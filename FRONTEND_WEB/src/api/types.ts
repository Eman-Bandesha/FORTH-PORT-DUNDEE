export type StockStatus = 'in_stock' | 'low_stock' | 'out_of_stock'
export type MovementType = 'stock_in' | 'stock_out'

export interface UserProfile {
  role: string
  department: string
  phone: string
}

export interface AuthUser {
  id: number
  username: string
  email: string
  first_name: string
  last_name: string
  profile?: UserProfile
}

export interface Item {
  code: string
  name: string
  image: string
  status: StockStatus
  quantity: number
  category: string
  unit: string
  reorder_level: number
  location: string
  description: string
  last_updated: string
}

export interface Movement {
  id: string
  type: MovementType
  item_name: string
  item_code: string
  image: string
  quantity: number
  date: string
  date_time_label?: string
  reference_no: string
  requested_by: string
  location: string
  notes: string
  reason: string
  unit: string
  stock_before: number
  change: number
  remaining_stock: number
}

export interface Paginated<T> {
  count: number
  next: string | null
  previous: string | null
  results: T[]
}

export interface DashboardStats {
  total_items: number
  total_quantity: number
  in_stock: number
  low_stock: number
  out_of_stock: number
  alerts_count: number
  stock_out_today: number
  near_expiry: number
  recent_stock_out: Movement[]
  recent_stock_in: Movement[]
  alert_items: Item[]
  by_category: { name: string; quantity: number }[]
  trend_7d: {
    date: string
    label: string
    stock_in: number
    stock_out: number
  }[]
}
