import { useEffect, useMemo, useState } from 'react'
import { fetchCategories, fetchLocations } from '../api/inventory'
import {
  exportReport,
  fetchStockMovementReport,
  type StockMovementReport,
} from '../api/reports'

function defaultRange() {
  const to = new Date()
  const from = new Date()
  from.setDate(to.getDate() - 13)
  const fmt = (d: Date) => d.toISOString().slice(0, 10)
  return { from: fmt(from), to: fmt(to) }
}

type Period = 'daily' | 'weekly' | 'monthly'

export function StockMovementReportPage() {
  const range = defaultRange()
  const [fromDate, setFromDate] = useState(range.from)
  const [toDate, setToDate] = useState(range.to)
  const [category, setCategory] = useState('')
  const [location, setLocation] = useState('')
  const [period, setPeriod] = useState<Period>('daily')
  const [categories, setCategories] = useState<string[]>([])
  const [locations, setLocations] = useState<string[]>([])
  const [data, setData] = useState<StockMovementReport | null>(null)
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

  async function generate(nextPeriod = period) {
    setLoading(true)
    setError('')
    setExportMsg('')
    try {
      const report = await fetchStockMovementReport({
        from_date: fromDate || undefined,
        to_date: toDate || undefined,
        category: category || undefined,
        location: location || undefined,
        period: nextPeriod,
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
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const maxBar = useMemo(() => {
    if (!data?.series.length) return 1
    return Math.max(
      1,
      ...data.series.flatMap((r) => [r.stock_in, r.stock_out]),
    )
  }, [data])

  async function onExport(format: 'csv' | 'pdf') {
    setExportMsg('')
    try {
      await exportReport({
        report_type: 'stock_movement',
        format,
        from_date: fromDate || undefined,
        to_date: toDate || undefined,
        category: category || undefined,
        location: location || undefined,
        period,
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

      <div className="card panel" style={{ marginBottom: 16 }}>
        <div className="movement-chart-head">
          <h2 className="panel-title" style={{ marginBottom: 0 }}>
            Stock Movement Overview
          </h2>
          <div className="period-toggle">
            {(['daily', 'weekly', 'monthly'] as Period[]).map((p) => (
              <button
                key={p}
                type="button"
                className={period === p ? 'active' : ''}
                onClick={() => {
                  setPeriod(p)
                  void generate(p)
                }}
              >
                {p.charAt(0).toUpperCase() + p.slice(1)}
              </button>
            ))}
          </div>
          <div className="chart-legend">
            <span>
              <i className="dot in" /> Stock In
            </span>
            <span>
              <i className="dot out" /> Stock Out
            </span>
          </div>
        </div>

        {loading && !data ? (
          <div className="loading">Loading chart…</div>
        ) : !data?.series.length ? (
          <div className="empty">No movements in this period</div>
        ) : (
          <div className="movement-bars">
            {data.series.map((row) => (
              <div className="movement-col" key={row.date}>
                <div className="bars">
                  <div
                    className="bar in"
                    style={{ height: `${(row.stock_in / maxBar) * 100}%` }}
                    title={`In ${row.stock_in}`}
                  />
                  <div
                    className="bar out"
                    style={{ height: `${(row.stock_out / maxBar) * 100}%` }}
                    title={`Out ${row.stock_out}`}
                  />
                </div>
                <span>{row.label}</span>
              </div>
            ))}
          </div>
        )}
      </div>

      {data ? (
        <div className="card table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Stock In (Qty)</th>
                <th>Stock Out (Qty)</th>
                <th>Net Movement</th>
                <th>Transactions</th>
              </tr>
            </thead>
            <tbody>
              {data.series.map((row) => (
                <tr key={row.date}>
                  <td>{row.label}</td>
                  <td>{row.stock_in.toLocaleString()}</td>
                  <td>{row.stock_out.toLocaleString()}</td>
                  <td>
                    <span
                      className={`qty-pill ${row.net >= 0 ? 'green' : 'red'}`}
                    >
                      {row.net > 0 ? '+' : ''}
                      {row.net.toLocaleString()}
                    </span>
                  </td>
                  <td>{row.transactions}</td>
                </tr>
              ))}
              <tr className="total-row">
                <td>
                  <strong>Total</strong>
                </td>
                <td>
                  <strong>{data.totals.stock_in.toLocaleString()}</strong>
                </td>
                <td>
                  <strong>{data.totals.stock_out.toLocaleString()}</strong>
                </td>
                <td>
                  <strong>
                    {data.totals.net > 0 ? '+' : ''}
                    {data.totals.net.toLocaleString()}
                  </strong>
                </td>
                <td>
                  <strong>{data.totals.transactions}</strong>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      ) : null}
    </>
  )
}
