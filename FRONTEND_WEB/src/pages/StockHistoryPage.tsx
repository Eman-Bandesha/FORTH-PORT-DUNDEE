import { useCallback, useEffect, useState } from 'react'
import { fetchLocations, fetchMovements } from '../api/inventory'
import type { Movement } from '../api/types'

export function StockHistoryPage() {
  const [rows, setRows] = useState<Movement[]>([])
  const [count, setCount] = useState(0)
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [type, setType] = useState('')
  const [location, setLocation] = useState('')
  const [fromDate, setFromDate] = useState('')
  const [toDate, setToDate] = useState('')
  const [locations, setLocations] = useState<string[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const pageSize = 10

  const load = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const data = await fetchMovements({
        type: type || undefined,
        search: search.trim() || undefined,
        location: location || undefined,
        from_date: fromDate || undefined,
        to_date: toDate || undefined,
        page,
        page_size: pageSize,
        sort: 'newest_first',
      })
      setRows(data.results)
      setCount(data.count)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load history')
    } finally {
      setLoading(false)
    }
  }, [search, type, location, fromDate, toDate, page])

  useEffect(() => {
    void load()
  }, [load])

  useEffect(() => {
    void fetchLocations().then((locs) => setLocations(locs.locations))
  }, [])

  const totalPages = Math.max(1, Math.ceil(count / pageSize))
  const showingFrom = count === 0 ? 0 : (page - 1) * pageSize + 1
  const showingTo = Math.min(page * pageSize, count)

  function resetFilters() {
    setSearch('')
    setType('')
    setLocation('')
    setFromDate('')
    setToDate('')
    setPage(1)
  }

  return (
    <>
      <div className="page-toolbar">
        <div className="grow">
          <input
            className="search-input"
            placeholder="Search items, SKU or reference..."
            value={search}
            onChange={(e) => {
              setPage(1)
              setSearch(e.target.value)
            }}
          />
        </div>
        <input
          className="select-input"
          type="date"
          style={{ maxWidth: 150 }}
          value={fromDate}
          onChange={(e) => {
            setPage(1)
            setFromDate(e.target.value)
          }}
          aria-label="From date"
        />
        <input
          className="select-input"
          type="date"
          style={{ maxWidth: 150 }}
          value={toDate}
          onChange={(e) => {
            setPage(1)
            setToDate(e.target.value)
          }}
          aria-label="To date"
        />
        <select
          className="select-input"
          style={{ maxWidth: 170 }}
          value={location}
          onChange={(e) => {
            setPage(1)
            setLocation(e.target.value)
          }}
        >
          <option value="">All Locations</option>
          {locations.map((l) => (
            <option key={l} value={l}>
              {l}
            </option>
          ))}
        </select>
        <select
          className="select-input"
          style={{ maxWidth: 140 }}
          value={type}
          onChange={(e) => {
            setPage(1)
            setType(e.target.value)
          }}
        >
          <option value="">All types</option>
          <option value="stock_in">Stock In</option>
          <option value="stock_out">Stock Out</option>
        </select>
        <button type="button" className="btn-secondary" onClick={resetFilters}>
          Reset Filters
        </button>
      </div>

      {error ? (
        <div className="form-error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <div className="card table-wrap">
        {loading ? (
          <div className="loading">Loading history…</div>
        ) : rows.length === 0 ? (
          <div className="empty">No movements yet</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Item</th>
                <th>Action</th>
                <th>Quantity</th>
                <th>Location</th>
                <th>Reference</th>
                <th>Added By</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((m) => (
                <tr key={m.id}>
                  <td>{m.date_time_label || m.date}</td>
                  <td>{m.item_name}</td>
                  <td>
                    <span
                      className={`status-badge ${
                        m.type === 'stock_in' ? 'in_stock' : 'out_of_stock'
                      }`}
                    >
                      {m.type === 'stock_in' ? 'Stock In' : 'Stock Out'}
                    </span>
                  </td>
                  <td>
                    <span
                      className={`qty-pill ${
                        m.type === 'stock_in' ? 'green' : 'red'
                      }`}
                    >
                      {m.type === 'stock_in' ? '+' : '-'}
                      {m.quantity} {m.unit}
                    </span>
                  </td>
                  <td>{m.location}</td>
                  <td>{m.reference_no}</td>
                  <td>{m.requested_by}</td>
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
            Showing {showingFrom} to {showingTo} of {count} records
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
