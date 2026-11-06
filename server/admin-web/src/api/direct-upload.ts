import { createMD5, createSHA256 } from 'hash-wasm'
import { ElMessage } from 'element-plus'
import { ApiError, request } from './http'

type Offer = { mode: 'proxy' } | {
  mode: 'direct'; ticket: string; url: string; headers: Record<string, string>; expires_in: number
}

async function proof(file: File, onProgress?: (fraction: number) => void) {
  const [sha, md5] = await Promise.all([createSHA256(), createMD5()])
  for (let offset = 0; offset < file.size; offset += 1024 * 1024) {
    const bytes = new Uint8Array(await file.slice(offset, offset + 1024 * 1024).arrayBuffer())
    sha.update(bytes); md5.update(bytes)
    onProgress?.(Math.min(0.05, (offset + bytes.length) / file.size * 0.05))
  }
  let binary = ''
  for (const byte of md5.digest('binary')) binary += String.fromCharCode(byte)
  return { file_name: file.name, size: file.size, sha256: sha.digest(), md5: btoa(binary) }
}

async function putObject(offer: Extract<Offer, { mode: 'direct' }>, file: File, onProgress?: (f: number) => void) {
    const url = new URL(offer.url)
    if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password) {
      throw new Error('服务器返回的上传地址无效')
    }
    for (const key of Object.keys(offer.headers)) {
      if (/^(cookie|host)$/i.test(key) || (key.toLowerCase() === 'authorization' &&
          !offer.headers[key]?.startsWith('AWS4-HMAC-SHA256 '))) {
        throw new Error('服务器返回了无效的上传请求头')
      }
    }
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), 4 * 60 * 60 * 1000)
    try {
      // Fetch disallows redirects explicitly; do not send business cookies/Authorization.
      const response = await fetch(url.href, { method: 'PUT', body: file, headers: offer.headers,
        credentials: 'omit', redirect: 'error', signal: controller.signal })
      if (!response.ok) throw new Error(`对象存储上传失败（HTTP ${response.status}），请重试`)
      onProgress?.(0.95)
    } catch (error) {
      if (error instanceof TypeError) throw new Error('无法上传到对象存储，请检查网络及存储跨域配置')
      if (controller.signal.aborted) throw new Error('对象存储上传超时，请重试')
      throw error
    } finally {
      clearTimeout(timeout)
    }
}

export async function directUpload<T>(path: string, file: File, extra: Record<string, unknown>,
                                      legacy: () => Promise<T>, onProgress?: (f: number) => void): Promise<T> {
  let offer: Offer
  try {
    const digest = await proof(file, onProgress)
    offer = await request<Offer>(`${path}/uploads`, { method: 'POST', body: { ...digest, ...extra }, silent: true })
  } catch (error) {
    if (error instanceof ApiError && [404, 405].includes(error.status)) return legacy()
    ElMessage.error(error instanceof Error ? error.message : '申请上传失败')
    throw error
  }
  if (offer.mode === 'proxy') return legacy()
  try {
    await putObject(offer, file, onProgress)
    const result = await request<T>(`${path}/uploads/complete`, {
      method: 'POST', body: { ticket: offer.ticket }, silent: true,
    })
    onProgress?.(1)
    return result
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : '确认上传失败，请重试')
    throw error
  }
}
