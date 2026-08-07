import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  fetchLocations,
  fetchMovements,
} from '../api/inventory'
import type { Movement } from '../api/types'

export function StockInPage() {
  const navigate = useNavigate()
  const [rows, setRows] = useState<Movement[]>([])
  const [count, setCount] = useState(0)
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
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
        type: 'stock_in',
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
      setError(err instanceof Error ? err.message : 'Failed to load stock in')
    } finally {
      setLoading(false)
    }
  }, [search, location, fromDate, toDate, page])

  useEffect(() => {
    void load()
  }, [load])

  useEffect(() => {
    void fetchLocations().then((locs) => setLocations(locs.locations))
  }, [])

  const totalPages = Math.max(1, Math.ceil(count / pageSize))

  return (
    <>
      <div className="page-toolbar">
        <div className="grow">
          <input
            className="search-input"
            placeholder="Search item or reference…"
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
          style={{ maxWidth: 160 }}
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
          style={{ maxWidth: 160 }}
          value={toDate}
          onChange={(e) => {
            setPage(1)
            setToDate(e.target.value)
          }}
          aria-label="To date"
        />
        <select
          className="select-input"
          style={{ maxWidth: 200 }}
          value={location}
          onChange={(e) => {
            setPage(1)
            setLocation(e.target.value)
          }}
        >
          <option value="">All locations</option>
          {locations.map((l) => (
            <option key={l} value={l}>
              {l}
            </option>
          ))}
        </select>
        <button
          type="button"
          className="btn-primary"
          onClick={() => navigate('/stock-in/new')}
        >
          + Add New Stock
        </button>
      </div>

      {error ? (
        <div className="form-error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <div className="card table-wrap">
        {loading ? (
          <div className="loading">Loading stock in…</div>
        ) : rows.length === 0 ? (
          <div className="empty">No stock-in records</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Item</th>
                <th>Quantity</th>
                <th>Unit</th>
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
                    <span className="qty-pill green">+{m.quantity}</span>
                  </td>
                  <td>{m.unit}</td>
                  <td>{m.location}</td>
                  <td>{m.reference_no}</td>
                  <td>{m.requested_by}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        <div className="pagination">
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
    </>
  )
}
