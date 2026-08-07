import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'
import { fetchDashboard } from '../api/inventory'
import type { DashboardStats } from '../api/types'

const DONUT_COLORS = ['#0A2240', '#16A34A', '#E67E22', '#6B7787', '#2F6BE0']

export function DashboardPage() {
  const { displayName } = useAuth()
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    fetchDashboard()
      .then((data) => {
        if (!cancelled) setStats(data)
      })
      .catch((err: Error) => {
        if (!cancelled) setError(err.message)
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [])

  const maxTrend = useMemo(() => {
    if (!stats?.trend_7d.length) return 1
    return Math.max(
      1,
      ...stats.trend_7d.flatMap((d) => [d.stock_in, d.stock_out]),
    )
  }, [stats])

  const categoryTotal = useMemo(() => {
    if (!stats?.by_category.length) return 1
    return Math.max(1, stats.by_category.reduce((s, c) => s + c.quantity, 0))
  }, [stats])

  const donutBackground = useMemo(() => {
    if (!stats?.by_category.length) return '#dfe5ec'
    const top = stats.by_category.slice(0, 5)
    let cursor = 0
    const stops: string[] = []
    top.forEach((row, i) => {
      const pct = (row.quantity / categoryTotal) * 100
      const next = cursor + pct
      stops.push(`${DONUT_COLORS[i % DONUT_COLORS.length]} ${cursor}% ${next}%`)
      cursor = next
    })
    if (cursor < 100) stops.push(`#dfe5ec ${cursor}% 100%`)
    return `conic-gradient(${stops.join(', ')})`
  }, [stats, categoryTotal])

  const firstName = displayName.split(/\s+/)[0] || displayName

  if (loading) return <div className="loading">Loading dashboard…</div>
  if (error) return <div className="form-error">{error}</div>
  if (!stats) return null

  return (
    <>
      <div className="page-hello">
        <h2>Hello, {firstName}</h2>
        <p>Here’s what’s happening in the store today.</p>
      </div>

      <div className="stats-grid">
        <div className="card stat-card">
          <div className="stat-card-top">
            <div>
              <div className="label">Total Items</div>
              <div className="value">{stats.total_items.toLocaleString()}</div>
            </div>
            <div className="icon" style={{ background: 'var(--blue-soft)', color: 'var(--link)' }}>
              ▭
            </div>
          </div>
          <Link to="/items" className="stat-link">
            View all →
          </Link>
        </div>
        <div className="card stat-card">
          <div className="stat-card-top">
            <div>
              <div className="label">Total Stock</div>
              <div className="value">{stats.total_quantity.toLocaleString()}</div>
            </div>
            <div className="icon" style={{ background: 'var(--green-bg)', color: 'var(--green)' }}>
              ⊕
            </div>
          </div>
          <Link to="/items" className="stat-link">
            View all →
          </Link>
        </div>
        <div className="card stat-card warn">
          <div className="stat-card-top">
            <div>
              <div className="label">Low Stock</div>
              <div className="value">{stats.low_stock}</div>
            </div>
            <div className="icon" style={{ background: 'var(--orange-bg)', color: 'var(--orange)' }}>
              ⚠
            </div>
          </div>
          <Link to="/alerts" className="stat-link">
            View all →
          </Link>
        </div>
        <div className="card stat-card danger">
          <div className="stat-card-top">
            <div>
              <div className="label">Out of Stock</div>
              <div className="value">{stats.out_of_stock}</div>
            </div>
            <div className="icon" style={{ background: 'var(--red-bg)', color: 'var(--red)' }}>
              !
            </div>
          </div>
          <Link to="/alerts" className="stat-link">
            View all →
          </Link>
        </div>
      </div>

      <div className="dashboard-grid">
        <section className="card panel">
          <h2 className="panel-title">Stock Overview</h2>
          <div className="chart-line">
            {stats.trend_7d.map((day) => (
              <div className="chart-col" key={day.date}>
                <div className="bars">
                  <div
                    className="bar in"
                    style={{ height: `${(day.stock_in / maxTrend) * 100}%` }}
                    title={`In ${day.stock_in}`}
                  />
                  <div
                    className="bar out"
                    style={{ height: `${(day.stock_out / maxTrend) * 100}%` }}
                    title={`Out ${day.stock_out}`}
                  />
                </div>
                <span>{day.label}</span>
              </div>
            ))}
          </div>
        </section>

        <section className="card panel alerts-side-panel">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h2 className="panel-title" style={{ marginBottom: 0 }}>
              Alerts
            </h2>
            <Link to="/alerts" className="linkish">
              View all →
            </Link>
          </div>

          <div className="alert-banners side">
            <Link to="/alerts" className="alert-banner danger">
              <div className="left">
                <div className="banner-icon">✕</div>
                <div className="banner-text">
                  <strong>Out of Stock Items</strong>
                  <span>Need urgent replenishment</span>
                </div>
              </div>
              <div className="count">{stats.out_of_stock}</div>
            </Link>
            <Link to="/alerts" className="alert-banner warn">
              <div className="left">
                <div className="banner-icon">!</div>
                <div className="banner-text">
                  <strong>Low Stock Items</strong>
                  <span>Below reorder level</span>
                </div>
              </div>
              <div className="count">{stats.low_stock}</div>
            </Link>
          </div>

          <h3 className="panel-subtitle">Low Stock List</h3>
          <div className="alert-list">
            {stats.alert_items.length === 0 ? (
              <div className="empty">No low stock alerts</div>
            ) : (
              stats.alert_items.map((item) => (
                <div className="alert-row" key={item.code}>
                  <div className="meta">
                    <strong>{item.name}</strong>
                    <span>
                      Min {item.reorder_level} · {item.category}
                    </span>
                  </div>
                  <span className="qty-pill red">{item.quantity}</span>
                </div>
              ))
            )}
          </div>
        </section>

        <section className="card panel">
          <h2 className="panel-title">Recent Stock In</h2>
          <div className="recent-list">
            {stats.recent_stock_in.length === 0 ? (
              <div className="empty">No recent stock-in movements</div>
            ) : (
              stats.recent_stock_in.map((m) => (
                <div className="recent-row" key={m.id}>
                  <div className="meta">
                    <strong>{m.item_name}</strong>
                    <span>
                      {m.date_time_label || m.date} · {m.reference_no}
                    </span>
                  </div>
                  <span className="qty-pill green">+{m.quantity}</span>
                </div>
              ))
            )}
          </div>
        </section>

        <section className="card panel">
          <h2 className="panel-title">Stock by Category</h2>
          <div className="donut-wrap">
            <div className="donut" style={{ background: donutBackground }} />
            <div className="legend">
              {stats.by_category.slice(0, 5).map((row, i) => {
                const pct = Math.round((row.quantity / categoryTotal) * 100)
                return (
                  <div className="legend-row" key={row.name}>
                    <div className="left">
                      <span
                        className="swatch"
                        style={{
                          background: DONUT_COLORS[i % DONUT_COLORS.length],
                        }}
                      />
                      <span>{row.name}</span>
                    </div>
                    <strong>{pct}%</strong>
                  </div>
                )
              })}
            </div>
          </div>
        </section>
      </div>
    </>
  )
}
