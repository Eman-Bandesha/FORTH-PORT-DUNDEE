import { useState, type FormEvent } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { ApiError } from '../api/client'
import { useAuth } from '../auth/AuthContext'
import '../styles/login.css'

export function LoginPage() {
  const { user, loading, login } = useAuth()
  const navigate = useNavigate()
  const [username, setUsername] = useState('eman@gmail.com')
  const [password, setPassword] = useState('123456')
  const [remember, setRemember] = useState(true)
  const [showPassword, setShowPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')

  if (!loading && user) {
    return <Navigate to="/" replace />
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    setError('')
    setSubmitting(true)
    try {
      await login(username.trim(), password)
      if (!remember) {
        /* tokens already in localStorage; keep simple for admin */
      }
      navigate('/', { replace: true })
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Unable to sign in')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="login-page">
      <section className="login-brand">
        <div className="login-brand-content">
          <div className="login-logo-mark">FP</div>
          <h1>FORTH PORTS DUNDEE</h1>
          <p className="tagline">
            Store Management System — Managing stock. Supporting operations.
          </p>
        </div>
        <div className="login-brand-footer">Dundee Store · Admin Console</div>
      </section>

      <section className="login-panel">
        <div className="login-card">
          <h2>Welcome Back!</h2>
          <p className="subtitle">Sign in to manage inventory and stock movements.</p>
          <form className="login-form" onSubmit={(e) => void onSubmit(e)}>
            {error ? <div className="form-error">{error}</div> : null}
            <div className="field">
              <label htmlFor="username">Email or Username</label>
              <input
                id="username"
                autoComplete="username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
              />
            </div>
            <div className="field">
              <label htmlFor="password">Password</label>
              <div className="password-wrap">
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  autoComplete="current-password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((v) => !v)}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                >
                  {showPassword ? '🙈' : '👁'}
                </button>
              </div>
            </div>
            <div className="login-row">
              <label className="remember">
                <input
                  type="checkbox"
                  checked={remember}
                  onChange={(e) => setRemember(e.target.checked)}
                />
                Remember me
              </label>
              <span className="linkish" style={{ opacity: 0.5, cursor: 'default' }}>
                Forgot password?
              </span>
            </div>
            <button className="btn-primary" type="submit" disabled={submitting}>
              {submitting ? 'Signing in…' : 'Sign In'}
            </button>
          </form>
          <p className="login-hint">Default: eman@gmail.com / 123456</p>
        </div>
      </section>
    </div>
  )
}
