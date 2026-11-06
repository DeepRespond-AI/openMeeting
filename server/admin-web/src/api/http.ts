import { ElMessage } from 'element-plus'
import router from '@/router'

export const API_BASE = '/admin/api'

export class ApiError extends Error {
  status: number
  detail: string
  constructor(status: number, detail: string) {
    super(detail)
    this.status = status
    this.detail = detail
  }
}

export interface RequestOptions {
  method?: string
  body?: unknown
  query?: Record<string, string | number | boolean | null | undefined>
  /** Suppress the automatic ElMessage on error */
  silent?: boolean
}

function buildUrl(path: string, query?: RequestOptions['query']): string {
  let url = API_BASE + path
  if (query) {
    const params = new URLSearchParams()
    for (const [k, v] of Object.entries(query)) {
      if (v !== undefined && v !== null && v !== '') params.append(k, String(v))
    }
    const qs = params.toString()
    if (qs) url += (url.includes('?') ? '&' : '?') + qs
  }
  return url
}

async function extractDetail(res: Response): Promise<string> {
  try {
    const data = await res.json()
    if (typeof data?.detail === 'string') return data.detail
    if (Array.isArray(data?.detail)) {
      // FastAPI validation errors
      return data.detail.map((d: { msg?: string }) => d.msg ?? JSON.stringify(d)).join('; ')
    }
    return JSON.stringify(data)
  } catch {
    return res.statusText || `HTTP ${res.status}`
  }
}

let redirecting = false

function handleUnauthorized() {
  if (redirecting) return
  const current = router.currentRoute.value
  if (current.name === 'login') return
  redirecting = true
  router
    .replace({ name: 'login', query: { redirect: current.fullPath } })
    .finally(() => {
      redirecting = false
    })
}

export async function request<T = unknown>(path: string, opts: RequestOptions = {}): Promise<T> {
  const init: RequestInit = {
    method: opts.method ?? 'GET',
    credentials: 'include',
    headers: { Accept: 'application/json' },
  }
  if (opts.body instanceof FormData) {
    init.body = opts.body
  } else if (opts.body !== undefined) {
    ;(init.headers as Record<string, string>)['Content-Type'] = 'application/json'
    init.body = JSON.stringify(opts.body)
  }

  let res: Response
  try {
    res = await fetch(buildUrl(path, opts.query), init)
  } catch (e) {
    const msg = '网络错误，无法连接服务器'
    if (!opts.silent) ElMessage.error(msg)
    throw new ApiError(0, msg)
  }

  if (res.status === 401) {
    const detail = await extractDetail(res)
    // /login reports its own error; /me is the router guard's session probe
    if (path !== '/login' && path !== '/me') handleUnauthorized()
    if (!opts.silent && path === '/login') ElMessage.error(detail || '密码错误')
    throw new ApiError(401, detail)
  }

  if (!res.ok) {
    const detail = await extractDetail(res)
    if (!opts.silent) ElMessage.error(detail || `请求失败 (${res.status})`)
    throw new ApiError(res.status, detail)
  }

  if (res.status === 204) return undefined as T
  const text = await res.text()
  if (!text) return undefined as T
  try {
    return JSON.parse(text) as T
  } catch {
    return text as unknown as T
  }
}

/** Multipart POST with upload progress (fetch cannot report it); same error handling as `request`. */
export function upload<T = unknown>(path: string, body: FormData, onProgress?: (fraction: number) => void): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const xhr = new XMLHttpRequest()
    xhr.open('POST', buildUrl(path))
    xhr.withCredentials = true
    xhr.setRequestHeader('Accept', 'application/json')
    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable && e.total > 0) onProgress?.(e.loaded / e.total)
    }
    xhr.onerror = () => {
      const msg = '网络错误，无法连接服务器'
      ElMessage.error(msg)
      reject(new ApiError(0, msg))
    }
    xhr.onload = async () => {
      if (xhr.status === 401) {
        handleUnauthorized()
        reject(new ApiError(401, '未登录或登录已过期'))
        return
      }
      if (xhr.status < 200 || xhr.status >= 300) {
        const detail = await extractDetail(new Response(xhr.responseText, { status: xhr.status }))
        ElMessage.error(detail || `请求失败 (${xhr.status})`)
        reject(new ApiError(xhr.status, detail))
        return
      }
      try {
        resolve((xhr.responseText ? JSON.parse(xhr.responseText) : undefined) as T)
      } catch {
        resolve(xhr.responseText as unknown as T)
      }
    }
    xhr.send(body)
  })
}

export const http = {
  get: <T>(path: string, query?: RequestOptions['query'], silent = false) =>
    request<T>(path, { query, silent }),
  post: <T>(path: string, body?: unknown, silent = false) =>
    request<T>(path, { method: 'POST', body, silent }),
  put: <T>(path: string, body?: unknown) => request<T>(path, { method: 'PUT', body }),
  patch: <T>(path: string, body?: unknown) => request<T>(path, { method: 'PATCH', body }),
  del: <T = void>(path: string) => request<T>(path, { method: 'DELETE' }),
}
