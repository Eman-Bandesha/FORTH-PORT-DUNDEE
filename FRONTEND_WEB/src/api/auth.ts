import { apiRequest } from './client'
import { clearTokens, saveTokens, saveUser } from './storage'
import type { AuthUser } from './types'

export async function login(username: string, password: string) {
  const data = await apiRequest<{
    user: AuthUser
    tokens: { access: string; refresh: string }
  }>('/auth/login/', {
    method: 'POST',
    auth: false,
    body: JSON.stringify({ username, password }),
  })
  saveTokens(data.tokens.access, data.tokens.refresh)
  saveUser(data.user)
  return data.user
}

export async function fetchMe() {
  const user = await apiRequest<AuthUser>('/auth/me/')
  saveUser(user)
  return user
}

export async function logout() {
  try {
    await apiRequest('/auth/logout/', { method: 'POST', body: '{}' })
  } catch {
    /* ignore */
  }
  clearTokens()
}
