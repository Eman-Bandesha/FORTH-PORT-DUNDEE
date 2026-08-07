import { Link } from 'react-router-dom'

export function ReportsHubPage() {
  return (
    <div className="reports-hub">
      <p className="reports-intro">
        Generate inventory reports. Choose a report type to filter, view, and export.
      </p>
      <div className="reports-cards">
        <Link to="/reports/stock-summary" className="card report-pick">
          <div className="report-pick-icon">◫</div>
          <h2>Stock Summary Report</h2>
          <p>
            Totals by category — SKUs, quantity, low stock and out of stock
            counts.
          </p>
          <span className="linkish">Open report →</span>
        </Link>
        <Link to="/reports/stock-movement" className="card report-pick">
          <div className="report-pick-icon">⇅</div>
          <h2>Stock Movement Report</h2>
          <p>
            Stock in vs stock out over time — daily, weekly, or monthly
            breakdown.
          </p>
          <span className="linkish">Open report →</span>
        </Link>
      </div>
    </div>
  )
}
