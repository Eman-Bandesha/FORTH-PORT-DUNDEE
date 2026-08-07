import { apiRequest } from './client'
import type { DashboardStats, Item, Movement, Paginated } from './types'

export function fetchDashboard() {
  return apiRequest<DashboardStats>('/dashboard/stats/')
}

export function fetchItem(code: string) {
  return apiRequest<Item>(`/items/${encodeURIComponent(code)}/`)
}

export function fetchItems(params: {
  search?: string
  category?: string
  location?: string
  status?: string
  sort?: string
  page?: number
  page_size?: number
}) {
  return apiRequest<Paginated<Item>>('/items/', { query: params })
}

export function fetchCategories() {
  return apiRequest<{ categories: string[] }>('/items/meta/categories/')
}

export function fetchLocations() {
  return apiRequest<{ locations: string[] }>('/items/meta/locations/')
}

export function createItem(payload: Partial<Item> & { code: string; name: string }) {
  return apiRequest<Item>('/items/', {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

export function updateItem(code: string, payload: Partial<Item>) {
  return apiRequest<Item>(`/items/${encodeURIComponent(code)}/`, {
    method: 'PATCH',
    body: JSON.stringify(payload),
  })
}

export function deleteItem(code: string) {
  return apiRequest<void>(`/items/${encodeURIComponent(code)}/`, {
    method: 'DELETE',
  })
}

export function fetchMovements(params: {
  type?: string
  search?: string
  location?: string
  from_date?: string
  to_date?: string
  sort?: string
  page?: number
  page_size?: number
}) {
  return apiRequest<Paginated<Movement>>('/movements/', { query: params })
}

export function createMovement(payload: {
  type: 'stock_in' | 'stock_out'
  item_code: string
  quantity: number
  requested_by: string
  location?: string
  notes?: string
  reason?: string
  reference_no?: string
  date?: string
}) {
  return apiRequest<Movement>('/movements/', {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

export function fetchNextReference() {
  return apiRequest<{ reference_no: string }>('/movements/next-reference/')
}

export function fetchNotifications(sort = 'name_asc') {
  return apiRequest<{ count: number; results: Item[] }>('/notifications/', {
    query: { sort },
  })
}
