export function formatBytes(bytes: number | null | undefined): string {
  if (bytes === null || bytes === undefined || isNaN(bytes)) return '-'
  const units = ['B', 'KB', 'MB', 'GB', 'TB']
  let v = bytes
  let i = 0
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024
    i++
  }
  return `${v.toFixed(i === 0 ? 0 : 1)} ${units[i]}`
}

export function formatSizeMb(mb: number | null | undefined): string {
  if (!mb) return '-'
  return mb >= 1024 ? `${(mb / 1024).toFixed(1)} GB` : `${mb} MB`
}

export function formatDuration(sec: number | null | undefined): string {
  if (sec === null || sec === undefined || isNaN(sec)) return '-'
  sec = Math.round(sec)
  const d = Math.floor(sec / 86400)
  const h = Math.floor((sec % 86400) / 3600)
  const m = Math.floor((sec % 3600) / 60)
  const s = sec % 60
  if (d > 0) return `${d}天 ${h}小时`
  if (h > 0) return `${h}小时 ${m}分`
  if (m > 0) return `${m}分 ${s}秒`
  return `${s}秒`
}

export function formatDateTime(iso: string | null | undefined): string {
  if (!iso) return '-'
  const d = new Date(iso)
  if (isNaN(d.getTime())) return iso
  const p = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`
}

export function relativeTime(iso: string | null | undefined, now = Date.now()): string {
  if (!iso) return '从未'
  const t = new Date(iso).getTime()
  if (isNaN(t)) return iso
  const diff = Math.max(0, Math.round((now - t) / 1000))
  if (diff < 5) return '刚刚'
  if (diff < 60) return `${diff} 秒前`
  if (diff < 3600) return `${Math.floor(diff / 60)} 分钟前`
  if (diff < 86400) return `${Math.floor(diff / 3600)} 小时前`
  if (diff < 86400 * 30) return `${Math.floor(diff / 86400)} 天前`
  return formatDateTime(iso)
}

export function percent(used: number, total: number): number {
  if (!total) return 0
  return Math.min(100, Math.round((used / total) * 1000) / 10)
}

export function progressColor(p: number): string {
  if (p >= 90) return '#f56c6c'
  if (p >= 70) return '#e6a23c'
  return '#409eff'
}

export async function copyText(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text)
    return true
  } catch {
    // Fallback for non-secure contexts (plain http)
    const ta = document.createElement('textarea')
    ta.value = text
    ta.style.position = 'fixed'
    ta.style.opacity = '0'
    document.body.appendChild(ta)
    ta.select()
    let ok = false
    try {
      ok = document.execCommand('copy')
    } catch {
      ok = false
    }
    document.body.removeChild(ta)
    return ok
  }
}

export const LANGUAGE_OPTIONS = [
  { value: 'auto', label: '自动检测' },
  { value: 'zh', label: '中文' },
  { value: 'en', label: '英语' },
  { value: 'ja', label: '日语' },
  { value: 'ko', label: '韩语' },
  { value: 'yue', label: '粤语' },
  { value: 'fr', label: '法语' },
  { value: 'de', label: '德语' },
  { value: 'es', label: '西班牙语' },
  { value: 'ru', label: '俄语' },
]

export const JOB_KIND_LABEL: Record<string, string> = {
  import: '导入',
  retranscribe: '重转写',
  summary: '总结',
}

export const JOB_STATUS: Record<string, { label: string; type: 'info' | 'primary' | 'success' | 'danger' | 'warning' }> = {
  queued: { label: '排队中', type: 'info' },
  running: { label: '运行中', type: 'primary' },
  completed: { label: '已完成', type: 'success' },
  failed: { label: '失败', type: 'danger' },
  cancelled: { label: '已取消', type: 'warning' },
}

export const PHONE_RE = /^1[3-9]\d{9}$/

/** Strip +86/86 prefix, spaces and dashes (mirrors server normalization). */
export function normalizePhone(raw: string): string {
  let p = (raw || '').replace(/[\s-]/g, '')
  if (p.startsWith('+86')) p = p.slice(3)
  else if (p.length === 13 && p.startsWith('86')) p = p.slice(2)
  return p
}

/** 13800138000 → 138****8000 */
export function maskPhone(phone: string | null | undefined): string {
  if (!phone) return '-'
  if (phone.length !== 11) return phone
  return `${phone.slice(0, 3)}****${phone.slice(7)}`
}
