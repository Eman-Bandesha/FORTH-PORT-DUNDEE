import { apiDownload, apiRequest } from './client'
import type { Paginated } from './types'

export interface AdminUser {
  id: number
  username: string
  email: string
  first_name: string
  last_name: string
  name: string
  role: string
  status: string
  account_status?: 'active' | 'suspended' | 'deactivated' | string
  must_change_password?: boolean
  is_active: boolean
  last_login: string | null
  last_login_display: string | null
  temporary_password?: string
  email_sent?: boolean
  profile?: {
    role: string
    department: string
    phone: string
    account_status?: string
    must_change_password?: boolean
  }
}

export const USER_ROLES = ['Administrator', 'Staff'] as const

export function fetchUsers(params: {
  search?: string
  role?: string
  status?: string
  page?: number
  page_size?: number
}) {
  return apiRequest<Paginated<AdminUser>>('/users/', { query: params })
}

export function createUser(payload: {
  first_name?: string
  last_name?: string
  email: string
  username?: string
  role?: string
  department?: string
  phone?: string
  account_status?: string
  generate_temporary_password?: boolean
  send_setup_email?: boolean
  password?: string
}) {
  return apiRequest<AdminUser>('/users/', {
    method: 'POST',
    body: JSON.stringify({
      generate_temporary_password: true,
      send_setup_email: true,
      ...payload,
    }),
  })
}

export function updateUser(
  id: number,
  payload: {
    first_name?: string
    last_name?: string
    email?: string
    username?: string
    role?: string
    department?: string
    phone?: string
    account_status?: string
    is_active?: boolean
    password?: string
    reset_temporary_password?: boolean
    send_reset_email?: boolean
  },
) {
  return apiRequest<AdminUser>(`/users/${id}/`, {
    method: 'PATCH',
    body: JSON.stringify(payload),
  })
}

/** Soft-deactivate — keeps stock/audit history. */
export function deactivateUser(id: number) {
  return apiRequest<{ detail: string; user: AdminUser }>(`/users/${id}/`, {
    method: 'DELETE',
  })
}

export function suspendUser(id: number) {
  return apiRequest<AdminUser>(`/users/${id}/suspend/`, { method: 'POST', body: '{}' })
}

export function reactivateUser(id: number) {
  return apiRequest<AdminUser>(`/users/${id}/reactivate/`, {
    method: 'POST',
    body: '{}',
  })
}

export function adminResetPassword(id: number, sendEmail = true) {
  return apiRequest<AdminUser>(`/users/${id}/reset-password/`, {
    method: 'POST',
    body: JSON.stringify({ send_reset_email: sendEmail }),
  })
}

export function exportUsers(params: {
  format: 'csv' | 'pdf'
  search?: string
  role?: string
  status?: string
}) {
  return apiDownload('/reports/export/', {
    method: 'POST',
    body: JSON.stringify({
      report_type: 'users',
      format: params.format,
      search: params.search || undefined,
      role: params.role || undefined,
      status: params.status || undefined,
    }),
  })
}
