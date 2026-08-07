import {
  clearTokens,
  getAccessToken,
  getRefreshToken,
  saveTokens,
} from './storage'

const BASE = (import.meta.env.VITE_API_BASE as string | undefined)?.replace(/\/$/, '') || '/api/v1'

export class ApiError extends Error {
  status: number
  body: unknown

  constructor(message: string, status: number, body?: unknown) {
    super(message)
    this.status = status
    this.body = body
  }
}

function messageFromBody(body: unknown): string {
  if (!body || typeof body !== 'object') return 'Request failed'
  const b = body as Record<string, unknown>
  if (typeof b.detail === 'string') return b.detail
  if (Array.isArray(b.non_field_errors) && b.non_field_errors.length) {
    return String(b.non_field_errors[0])
  }
  const first = Object.values(b).find((v) => Array.isArray(v) && v.length)
  if (Array.isArray(first)) return String(first[0])
  return 'Request failed'
}

async function tryRefresh(): Promise<boolean> {
  const refresh = getRefreshToken()
  if (!refresh) return false
  const res = await fetch(`${BASE}/auth/token/refresh/`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({ refresh }),
  })
  if (!res.ok) {
    clearTokens()
    return false
  }
  const data = (await res.json()) as { access: string }
  saveTokens(data.access, refresh)
  return true
}

export async function apiRequest<T>(
  path: string,
  options: RequestInit & { auth?: boolean; query?: Record<string, string | number | undefined | null> } = {},
): Promise<T> {
  const { auth = true, query, ...init } = options
  const headers = new Headers(init.headers)
  headers.set('Accept', 'application/json')
  if (init.body && !(init.body instanceof FormData)) {
    headers.set('Content-Type', 'application/json')
  }
  if (auth) {
    const token = getAccessToken()
    if (token) headers.set('Authorization', `Bearer ${token}`)
  }

  const qs = query
    ? `?${Object.entries(query)
        .filter(([, v]) => v !== undefined && v !== null && v !== '')
        .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
        .join('&')}`
    : ''

  const url = `${BASE}${path.startsWith('/') ? path : `/${path}`}${qs}`

  let res = await fetch(url, { ...init, headers })
  if (auth && res.status === 401) {
    const ok = await tryRefresh()
    if (ok) {
      const token = getAccessToken()
      if (token) headers.set('Authorization', `Bearer ${token}`)
      res = await fetch(url, { ...init, headers })
    }
  }

  if (res.status === 204) return undefined as T

  const text = await res.text()
  let body: unknown = null
  if (text) {
    try {
      body = JSON.parse(text)
    } catch {
      body = text
    }
  }

  if (!res.ok) {
    throw new ApiError(messageFromBody(body), res.status, body)
  }
  return body as T
}

/** Download a binary/file response (CSV, PDF) with auth + refresh. */
export async function apiDownload(
  path: string,
  options: RequestInit & {
    auth?: boolean
    query?: Record<string, string | number | undefined | null>
    filename?: string
  } = {},
): Promise<void> {
  const { auth = true, query, filename, ...init } = options
  const headers = new Headers(init.headers)
  if (init.body && !(init.body instanceof FormData)) {
    headers.set('Content-Type', 'application/json')
  }
  if (auth) {
    const token = getAccessToken()
    if (token) headers.set('Authorization', `Bearer ${token}`)
  }

  const qs = query
    ? `?${Object.entries(query)
        .filter(([, v]) => v !== undefined && v !== null && v !== '')
        .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
        .join('&')}`
    : ''

  const url = `${BASE}${path.startsWith('/') ? path : `/${path}`}${qs}`

  let res = await fetch(url, { ...init, headers })
  if (auth && res.status === 401) {
    const ok = await tryRefresh()
    if (ok) {
      const token = getAccessToken()
      if (token) headers.set('Authorization', `Bearer ${token}`)
      res = await fetch(url, { ...init, headers })
    }
  }

  if (!res.ok) {
    const text = await res.text()
    let body: unknown = text
    try {
      body = JSON.parse(text)
    } catch {
      /* keep text */
    }
    throw new ApiError(messageFromBody(body), res.status, body)
  }

  const blob = await res.blob()
  let downloadName = filename
  if (!downloadName) {
    const cd = res.headers.get('Content-Disposition') || ''
    const match = /filename="?([^"]+)"?/i.exec(cd)
    downloadName = match?.[1] || 'download'
  }
  const objectUrl = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = objectUrl
  a.download = downloadName
  document.body.appendChild(a)
  a.click()
  a.remove()
  URL.revokeObjectURL(objectUrl)
}
