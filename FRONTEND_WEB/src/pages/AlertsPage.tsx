import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { fetchDashboard, fetchNotifications } from '../api/inventory'
import type { Item } from '../api/types'
import { StatusBadge } from '../components/StatusBadge'

export function AlertsPage() {
  const navigate = useNavigate()
  const [items, setItems] = useState<Item[]>([])
  const [lowCount, setLowCount] = useState(0)
  const [outCount, setOutCount] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [page, setPage] = useState(1)
  const pageSize = 10

  const load = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const [alerts, dash] = await Promise.all([
        fetchNotifications(),
        fetchDashboard(),
      ])
      setItems(alerts.results)
      setLowCount(dash.low_stock)
      setOutCount(dash.out_of_stock)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load alerts')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const totalPages = Math.max(1, Math.ceil(items.length / pageSize))
  const pageItems = items.slice((page - 1) * pageSize, page * pageSize)
  const showingFrom = items.length === 0 ? 0 : (page - 1) * pageSize + 1
  const showingTo = Math.min(page * pageSize, items.length)

  return (
    <>
      <div className="stats-grid" style={{ gridTemplateColumns: '1fr 1fr' }}>
        <div className="card stat-card warn">
          <div>
            <div className="label">Low Stock Items</div>
            <div className="value">{lowCount}</div>
            <div style={{ color: 'var(--muted)', fontSize: '0.85rem', marginTop: 4 }}>
              Items below minimum level
            </div>
          </div>
          <div className="icon" style={{ background: '#fcf1de' }}>
            ⚠
          </div>
        </div>
        <div className="card stat-card danger">
          <div>
            <div className="label">Out of Stock Items</div>
            <div className="value">{outCount}</div>
            <div style={{ color: 'var(--muted)', fontSize: '0.85rem', marginTop: 4 }}>
              No stock available
            </div>
          </div>
          <div className="icon" style={{ background: '#fbe7e6' }}>
            !
          </div>
        </div>
      </div>

      {error ? (
        <div className="form-error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <div className="card table-wrap">
        {loading ? (
          <div className="loading">Loading alerts…</div>
        ) : items.length === 0 ? (
          <div className="empty">No low or out-of-stock items</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Item</th>
                <th>Category</th>
                <th>Current Stock</th>
                <th>Minimum Stock</th>
                <th>Status</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {pageItems.map((item) => (
                <tr key={item.code}>
                  <td>
                    <strong>{item.name}</strong>
                    <div style={{ color: 'var(--muted)', fontSize: '0.78rem' }}>
                      {item.code}
                    </div>
                  </td>
                  <td>{item.category}</td>
                  <td style={{ color: 'var(--red)', fontWeight: 700 }}>
                    {item.quantity} {item.unit}
                  </td>
                  <td>
                    {item.reorder_level} {item.unit}
                  </td>
                  <td>
                    <StatusBadge status={item.status} />
                  </td>
                  <td>
                    <button
                      type="button"
                      className="btn-primary"
                      style={{ padding: '8px 12px', fontSize: '0.85rem' }}
                      onClick={() =>
                        navigate(
                          `/stock-in/new?item=${encodeURIComponent(item.code)}`,
                        )
                      }
                    >
                      Add Stock
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        <div
          className="pagination"
          style={{ justifyContent: 'space-between', alignItems: 'center' }}
        >
          <span style={{ color: 'var(--muted)', fontSize: '0.85rem' }}>
            Showing {showingFrom} to {showingTo} of {items.length} items
          </span>
          <div style={{ display: 'flex', gap: 6 }}>
            {Array.from({ length: Math.min(totalPages, 8) }, (_, i) => {
              const p = i + 1
              return (
                <button
                  key={p}
                  type="button"
                  className={`page-btn${page === p ? ' active' : ''}`}
                  onClick={() => setPage(p)}
                >
                  {p}
                </button>
              )
            })}
          </div>
        </div>
      </div>
    </>
  )
}
