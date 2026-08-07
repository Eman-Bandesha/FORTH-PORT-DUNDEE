import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import * as authApi from '../api/auth'
import { getAccessToken, loadUser } from '../api/storage'
import type { AuthUser } from '../api/types'

interface AuthContextValue {
  user: AuthUser | null
  loading: boolean
  login: (username: string, password: string) => Promise<void>
  logout: () => Promise<void>
  displayName: string
  role: string
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(() => loadUser<AuthUser>())
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false
    async function restore() {
      if (!getAccessToken()) {
        setLoading(false)
        return
      }
      try {
        const me = await authApi.fetchMe()
        if (!cancelled) setUser(me)
      } catch {
        if (!cancelled) setUser(null)
      } finally {
        if (!cancelled) setLoading(false)
      }
    }
    void restore()
    return () => {
      cancelled = true
    }
  }, [])

  const login = useCallback(async (username: string, password: string) => {
    const next = await authApi.login(username, password)
    setUser(next)
  }, [])

  const logout = useCallback(async () => {
    await authApi.logout()
    setUser(null)
  }, [])

  const value = useMemo<AuthContextValue>(() => {
    const full = `${user?.first_name ?? ''} ${user?.last_name ?? ''}`.trim()
    return {
      user,
      loading,
      login,
      logout,
      displayName: full || user?.username || 'Admin User',
      role: user?.profile?.role || 'Administrator',
    }
  }, [user, loading, login, logout])

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
