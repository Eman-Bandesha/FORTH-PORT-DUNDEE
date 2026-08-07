import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useEffect, useMemo, useState } from 'react'
import { useAuth } from '../auth/AuthContext'
import { fetchDashboard } from '../api/inventory'

type NavItem = {
  to: string
  label: string
  icon: string
  end?: boolean
  disabled?: boolean
}

const NAV: NavItem[] = [
  { to: '/', label: 'Dashboard', icon: '🏠', end: true },
  { to: '/items', label: 'Items', icon: '📦' },
  { to: '/stock-in', label: 'Stock In', icon: '⬇️' },
  { to: '/stock-history', label: 'Stock History', icon: '🕓' },
  { to: '/alerts', label: 'Low Stock Alerts', icon: '⚠️' },
  { to: '/reports', label: 'Reports', icon: '📊' },
  { to: '/users', label: 'Users', icon: '👥' },
]

const TITLES: Record<string, string> = {
  '/': 'Dashboard',
  '/items': 'Items',
  '/stock-in': 'Stock In',
  '/stock-history': 'Stock History',
  '/alerts': 'Low Stock Alerts',
  '/reports': 'Reports',
  '/reports/stock-summary': 'Stock Summary Report',
  '/reports/stock-movement': 'Stock Movement Report',
  '/users': 'Users',
}

export function AdminLayout() {
  const { displayName, role, logout } = useAuth()
  const location = useLocation()
  const navigate = useNavigate()
  const [collapsed, setCollapsed] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)
  const [alertCount, setAlertCount] = useState(0)

  useEffect(() => {
    let cancelled = false
    fetchDashboard()
      .then((d) => {
        if (!cancelled) setAlertCount(d.alerts_count)
      })
      .catch(() => {
        /* ignore */
      })
    return () => {
      cancelled = true
    }
  }, [location.pathname])

  const title = useMemo(() => {
    if (location.pathname === '/items/new') return 'Add New Item'
    if (location.pathname.endsWith('/edit')) return 'Edit Item'
    if (location.pathname === '/stock-in/new') return 'Add New Stock'
    return TITLES[location.pathname] ?? 'Admin'
  }, [location.pathname])

  const initials = displayName
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase() ?? '')
    .join('') || 'A'

  async function onLogout() {
    await logout()
    navigate('/login', { replace: true })
  }

  const shellClass = [
    'admin-shell',
    collapsed ? 'collapsed' : '',
    mobileOpen ? 'mobile-open' : '',
  ]
    .filter(Boolean)
    .join(' ')

  return (
    <div className={shellClass}>
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="mark">FP</div>
          <div className="titles">
            <strong>FORTH PORTS</strong>
            <span>DUNDEE STORE</span>
          </div>
        </div>
        <nav className="sidebar-nav">
          {NAV.map((item) =>
            item.disabled ? (
              <button
                key={item.label}
                type="button"
                className="nav-item disabled"
                title="Coming soon"
              >
                <span className="icon">{item.icon}</span>
                {item.label}
              </button>
            ) : (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.end}
                className={({ isActive }) =>
                  `nav-item${isActive ? ' active' : ''}`
                }
                onClick={() => setMobileOpen(false)}
              >
                <span className="icon">{item.icon}</span>
                {item.label}
              </NavLink>
            ),
          )}
        </nav>
        <div className="sidebar-footer">
          <div className="sidebar-user">
            <div className="avatar">{initials}</div>
            <div className="meta">
              <strong title={displayName}>{displayName}</strong>
              <span>{role}</span>
            </div>
          </div>
          <div className="sidebar-logout">
            <button type="button" className="nav-item" onClick={() => void onLogout()}>
              <span className="icon">🚪</span>
              Logout
            </button>
          </div>
        </div>
      </aside>

      <div className="main-area">
        <header className="topbar">
          <div className="topbar-left">
            <button
              type="button"
              className="icon-btn"
              aria-label="Toggle menu"
              onClick={() => {
                if (window.innerWidth <= 720) {
                  setMobileOpen((v) => !v)
                } else {
                  setCollapsed((v) => !v)
                }
              }}
            >
              ☰
            </button>
            <h1>{title}</h1>
          </div>
          <div className="topbar-right">
            <button
              type="button"
              className="bell"
              aria-label="Alerts"
              onClick={() => navigate('/alerts')}
            >
              🔔
              {alertCount > 0 ? <span className="badge">{alertCount}</span> : null}
            </button>
            <div className="user-chip">
              <div className="avatar">{initials}</div>
              <div className="meta">
                <strong>{displayName}</strong>
                <span>{role}</span>
              </div>
            </div>
          </div>
        </header>
        <main className="content">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
