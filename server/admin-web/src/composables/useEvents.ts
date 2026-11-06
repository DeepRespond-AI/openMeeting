import { onBeforeUnmount, ref } from 'vue'
import { EVENTS_URL } from '@/api'
import type { AdminEventName } from '@/api/types'

type Handler = (data: unknown) => void

const handlers = new Map<AdminEventName, Set<Handler>>()
const EVENT_NAMES: AdminEventName[] = ['connections', 'jobs', 'stt', 'llm', 'model-download', 'ping']

/** true while the SSE stream is open */
export const sseConnected = ref(false)

let source: EventSource | null = null
let refCount = 0
let retryTimer: number | null = null
let retryDelay = 2000

function dispatch(name: AdminEventName, raw: string) {
  let data: unknown = raw
  try {
    data = raw ? JSON.parse(raw) : null
  } catch {
    /* keep raw string */
  }
  handlers.get(name)?.forEach((h) => {
    try {
      h(data)
    } catch (e) {
      console.error('[sse] handler error', name, e)
    }
  })
}

function open() {
  if (source || typeof EventSource === 'undefined') return
  const es = new EventSource(EVENTS_URL, { withCredentials: true })
  source = es
  es.onopen = () => {
    sseConnected.value = true
    retryDelay = 2000
  }
  es.onerror = () => {
    sseConnected.value = false
    // Browser retries automatically unless the stream is CLOSED (e.g. 401 / non-SSE response)
    if (es.readyState === EventSource.CLOSED) {
      es.close()
      source = null
      scheduleReconnect()
    }
  }
  for (const name of EVENT_NAMES) {
    es.addEventListener(name, (ev) => dispatch(name, (ev as MessageEvent).data))
  }
}

function scheduleReconnect() {
  if (retryTimer !== null || refCount <= 0) return
  retryTimer = window.setTimeout(() => {
    retryTimer = null
    if (refCount > 0) open()
  }, retryDelay)
  retryDelay = Math.min(retryDelay * 2, 30000)
}

function close() {
  if (retryTimer !== null) {
    clearTimeout(retryTimer)
    retryTimer = null
  }
  source?.close()
  source = null
  sseConnected.value = false
}

/**
 * Subscribe to admin SSE events for the lifetime of the calling component.
 * The underlying EventSource is shared and reference-counted.
 */
export function useAdminEvents(subs: Partial<Record<AdminEventName, Handler>>) {
  refCount++
  for (const [name, h] of Object.entries(subs) as [AdminEventName, Handler][]) {
    if (!handlers.has(name)) handlers.set(name, new Set())
    handlers.get(name)!.add(h)
  }
  open()
  onBeforeUnmount(() => {
    for (const [name, h] of Object.entries(subs) as [AdminEventName, Handler][]) {
      handlers.get(name)?.delete(h)
    }
    refCount--
    if (refCount <= 0) {
      refCount = 0
      close()
    }
  })
  return { connected: sseConnected }
}

/** Run fn every `ms` milliseconds while mounted (fn is NOT called immediately). */
export function useInterval(fn: () => void, ms: number) {
  const id = window.setInterval(fn, ms)
  onBeforeUnmount(() => clearInterval(id))
}
