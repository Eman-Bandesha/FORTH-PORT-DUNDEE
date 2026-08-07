import { apiDownload, apiRequest } from './client'

export interface StockSummaryCategoryRow {
  category: string
  total_items: number
  total_quantity: number
  stock_value: number
  out_of_stock: number
  low_stock: number
}

export interface StockSummaryReport {
  total_items: number
  total_quantity: number
  total_stock_value: number
  in_stock: number
  low_stock: number
  out_of_stock: number
  by_category: StockSummaryCategoryRow[]
  totals: StockSummaryCategoryRow
}

export interface MovementSeriesRow {
  date: string
  label: string
  stock_in: number
  stock_out: number
  net: number
  transactions: number
}

export interface StockMovementReport {
  period: 'daily' | 'weekly' | 'monthly'
  from_date: string
  to_date: string
  series: MovementSeriesRow[]
  totals: {
    stock_in: number
    stock_out: number
    net: number
    transactions: number
  }
}

export function fetchStockSummaryReport(params: {
  category?: string
  location?: string
}) {
  return apiRequest<StockSummaryReport>('/reports/stock-summary/', {
    query: params,
  })
}

export function fetchStockMovementReport(params: {
  from_date?: string
  to_date?: string
  category?: string
  location?: string
  period?: string
}) {
  return apiRequest<StockMovementReport>('/reports/stock-movement/', {
    query: params,
  })
}

export function exportReport(payload: {
  report_type: 'stock_summary' | 'stock_movement' | 'users'
  format: 'csv' | 'pdf'
  category?: string
  location?: string
  from_date?: string
  to_date?: string
  period?: string
  search?: string
  role?: string
  status?: string
}) {
  return apiDownload('/reports/export/', {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}
