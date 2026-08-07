import type { StockStatus } from '../api/types'

const LABELS: Record<StockStatus, string> = {
  in_stock: 'In Stock',
  low_stock: 'Low Stock',
  out_of_stock: 'Out of Stock',
}

export function StatusBadge({ status }: { status: StockStatus }) {
  return <span className={`status-badge ${status}`}>{LABELS[status]}</span>
}
