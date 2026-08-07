import { useEffect, useState } from 'react'
import { fetchCategories, fetchLocations } from '../api/inventory'
import {
  exportReport,
  fetchStockSummaryReport,
  type StockSummaryReport,
} from '../api/reports'

function monthRange() {
  const now = new Date()
  const from = new Date(now.getFullYear(), now.getMonth(), 1)
  const to = new Date(now.getFullYear(), now.getMonth() + 1, 0)
  const fmt = (d: Date) => d.toISOString().slice(0, 10)
  return { from: fmt(from), to: fmt(to) }
}

export function StockSummaryReportPage() {
  const range = monthRange()
  const [fromDate, setFromDate] = useState(range.from)
  const [toDate, setToDate] = useState(range.to)
  const [category, setCategory] = useState('')
  const [location, setLocation] = useState('')
  const [categories, setCategories] = useState<string[]>([])
  const [locations, setLocations] = useState<string[]>([])
  const [data, setData] = useState<StockSummaryReport | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [exportMsg, setExportMsg] = useState('')

  useEffect(() => {
    void Promise.all([fetchCategories(), fetchLocations()]).then(
      ([cats, locs]) => {
        setCategories(cats.categories)
        setLocations(locs.locations)
      },
    )
  }, [])

  async function generate() {
    setLoading(true)
    setError('')
    setExportMsg('')
    try {
      const report = await fetchStockSummaryReport({
        category: category || undefined,
        location: location || undefined,
      })
      setData(report)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to generate report')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void generate()
    // initial load
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  async function onExport(format: 'csv' | 'pdf') {
    setExportMsg('')
    try {
      await exportReport({
        report_type: 'stock_summary',
        format,
        category: category || undefined,
        location: location || undefined,
      })
      setExportMsg(`${format.toUpperCase()} downloaded.`)
    } catch (err) {
      setExportMsg(err instanceof Error ? err.message : 'Export failed')
    }
  }

  return (
    <>
      <div className="page-toolbar report-filters">
        <div className="field compact">
          <label>From</label>
          <input
            className="select-input"
            type="date"
            value={fromDate}
            onChange={(e) => setFromDate(e.target.value)}
          />
        </div>
        <div className="field compact">
          <label>To</label>
          <input
            className="select-input"
            type="date"
            value={toDate}
            onChange={(e) => setToDate(e.target.value)}
          />
        </div>
        <div className="field compact">
          <label>Category</label>
          <select
            className="select-input"
            value={category}
            onChange={(e) => setCategory(e.target.value)}
          >
            <option value="">All Categories</option>
            {categories.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </div>
        <div className="field compact">
          <label>Location</label>
          <select
            className="select-input"
            value={location}
            onChange={(e) => setLocation(e.target.value)}
          >
            <option value="">All Locations</option>
            {locations.map((l) => (
              <option key={l} value={l}>
                {l}
              </option>
            ))}
          </select>
        </div>
        <button
          type="button"
          className="btn-primary"
          onClick={() => void generate()}
          disabled={loading}
        >
          {loading ? 'Generating…' : 'Generate'}
        </button>
        <div className="export-split">
          <button
            type="button"
            className="btn-secondary"
            onClick={() => void onExport('csv')}
          >
            Export CSV
          </button>
          <button
            type="button"
            className="btn-secondary"
            onClick={() => void onExport('pdf')}
          >
            Export PDF
          </button>
        </div>
      </div>

      {error ? <div className="form-error" style={{ marginBottom: 12 }}>{error}</div> : null}
      {exportMsg ? (
        <div style={{ marginBottom: 12, color: 'var(--muted)', fontSize: '0.9rem' }}>
          {exportMsg}
        </div>
      ) : null}

      {data ? (
        <>
          <div className="stats-grid report-kpis">
            <div className="card stat-card">
              <div>
                <div className="label">Total Items</div>
                <div className="value">{data.total_items.toLocaleString()}</div>
                <div className="kpi-sub">SKUs</div>
              </div>
            </div>
            <div className="card stat-card">
              <div>
                <div className="label">Total Stock Quantity</div>
                <div className="value" style={{ color: 'var(--green)' }}>
                  {data.total_quantity.toLocaleString()}
                </div>
                <div className="kpi-sub">Units</div>
              </div>
            </div>
            <div className="card stat-card">
              <div>
                <div className="label">Total Stock Value</div>
                <div className="value">—</div>
                <div className="kpi-sub">Estimated (costing TBD)</div>
              </div>
            </div>
            <div className="card stat-card danger">
              <div>
                <div className="label">Out of Stock Items</div>
                <div className="value">{data.out_of_stock}</div>
                <div className="kpi-sub">Items</div>
              </div>
            </div>
            <div className="card stat-card warn">
              <div>
                <div className="label">Low Stock Items</div>
                <div className="value">{data.low_stock}</div>
                <div className="kpi-sub">Items</div>
              </div>
            </div>
          </div>

          <div className="card table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Category</th>
                  <th>Total Items</th>
                  <th>Total Quantity</th>
                  <th>Stock Value (GBP)</th>
                  <th>Out of Stock</th>
                  <th>Low Stock</th>
                </tr>
              </thead>
              <tbody>
                {data.by_category.map((row) => (
                  <tr key={row.category}>
                    <td>{row.category}</td>
                    <td>{row.total_items.toLocaleString()}</td>
                    <td>{row.total_quantity.toLocaleString()}</td>
                    <td>—</td>
                    <td style={{ color: 'var(--red)', fontWeight: 700 }}>
                      {row.out_of_stock}
                    </td>
                    <td style={{ color: 'var(--orange)', fontWeight: 700 }}>
                      {row.low_stock}
                    </td>
                  </tr>
                ))}
                <tr className="total-row">
                  <td>
                    <strong>Total</strong>
                  </td>
                  <td>
                    <strong>{data.totals.total_items.toLocaleString()}</strong>
                  </td>
                  <td>
                    <strong>{data.totals.total_quantity.toLocaleString()}</strong>
                  </td>
                  <td>
                    <strong>—</strong>
                  </td>
                  <td>
                    <strong>{data.totals.out_of_stock}</strong>
                  </td>
                  <td>
                    <strong>{data.totals.low_stock}</strong>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </>
      ) : loading ? (
        <div className="loading">Generating report…</div>
      ) : null}
    </>
  )
}
