import { useCallback, useEffect, useState } from 'react'
import {
  adminResetPassword,
  createUser,
  deactivateUser,
  exportUsers,
  fetchUsers,
  reactivateUser,
  suspendUser,
  updateUser,
  USER_ROLES,
  type AdminUser,
} from '../api/users'
import { Modal } from '../components/Modal'

type FormState = {
  first_name: string
  last_name: string
  email: string
  username: string
  role: string
  account_status: string
}

const emptyForm: FormState = {
  first_name: '',
  last_name: '',
  email: '',
  username: '',
  role: 'Staff',
  account_status: 'active',
}

export function UsersPage() {
  const [users, setUsers] = useState<AdminUser[]>([])
  const [count, setCount] = useState(0)
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [role, setRole] = useState('')
  const [status, setStatus] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [exportMsg, setExportMsg] = useState('')
  const [infoMsg, setInfoMsg] = useState('')
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing] = useState<AdminUser | null>(null)
  const [form, setForm] = useState<FormState>(emptyForm)
  const [saving, setSaving] = useState(false)
  const pageSize = 10

  const load = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const data = await fetchUsers({
        search: search.trim() || undefined,
        role: role || undefined,
        status: status || undefined,
        page,
        page_size: pageSize,
      })
      setUsers(data.results)
      setCount(data.count)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load users')
    } finally {
      setLoading(false)
    }
  }, [search, role, status, page])

  useEffect(() => {
    void load()
  }, [load])

  const totalPages = Math.max(1, Math.ceil(count / pageSize))
  const from = count === 0 ? 0 : (page - 1) * pageSize + 1
  const to = Math.min(page * pageSize, count)

  function openCreate() {
    setEditing(null)
    setForm(emptyForm)
    setModalOpen(true)
  }

  function openEdit(user: AdminUser) {
    setEditing(user)
    setForm({
      first_name: user.first_name || '',
      last_name: user.last_name || '',
      email: user.email || '',
      username: user.username || '',
      role: user.role || 'Staff',
      account_status: user.account_status || (user.is_active ? 'active' : 'deactivated'),
    })
    setModalOpen(true)
  }

  async function onSave() {
    setSaving(true)
    setError('')
    setInfoMsg('')
    try {
      if (editing) {
        await updateUser(editing.id, {
          first_name: form.first_name,
          last_name: form.last_name,
          email: form.email,
          username: form.username || undefined,
          role: form.role,
          account_status: form.account_status,
        })
        setInfoMsg('User updated.')
      } else {
        if (!form.email.trim()) throw new Error('Registered company email is required.')
        const created = await createUser({
          first_name: form.first_name,
          last_name: form.last_name,
          email: form.email.trim(),
          username: form.username.trim() || undefined,
          role: form.role,
          account_status: form.account_status,
          generate_temporary_password: true,
          send_setup_email: true,
        })
        if (created.temporary_password) {
          const mailNote = created.email_sent
            ? 'Setup email was sent.'
            : 'Email could not be sent (check Brevo on the server). Share this password manually.'
          setInfoMsg(
            `User created. Username: ${created.username}. Temporary password: ${created.temporary_password}. ${mailNote}`,
          )
        } else {
          setInfoMsg(
            created.email_sent
              ? 'User created. A temporary password was emailed to their registered address.'
              : 'User created, but the setup email failed. Reset password from the table actions.',
          )
        }
      }
      setModalOpen(false)
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  async function onDeactivate(user: AdminUser) {
    if (
      !window.confirm(
        `Deactivate ${user.name}? Stock and audit records will be kept. They will not be able to sign in.`,
      )
    ) {
      return
    }
    try {
      await deactivateUser(user.id)
      setInfoMsg('Account deactivated. Records kept.')
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Deactivate failed')
    }
  }

  async function onSuspend(user: AdminUser) {
    try {
      await suspendUser(user.id)
      setInfoMsg('Account suspended.')
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Suspend failed')
    }
  }

  async function onReactivate(user: AdminUser) {
    try {
      await reactivateUser(user.id)
      setInfoMsg('Account reactivated.')
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Reactivate failed')
    }
  }

  async function onResetPassword(user: AdminUser) {
    if (
      !window.confirm(
        `Generate a new temporary password for ${user.name} and email it?`,
      )
    ) {
      return
    }
    try {
      const result = await adminResetPassword(user.id, true)
      if (result.temporary_password) {
        const mailNote = result.email_sent
          ? 'Reset email was sent.'
          : 'Email could not be sent. Share this password manually.'
        setInfoMsg(
          `Password reset. Temporary password: ${result.temporary_password}. ${mailNote}`,
        )
      } else {
        setInfoMsg(
          result.email_sent
            ? 'Temporary password emailed. User must change it on next login.'
            : 'Password reset, but email failed. Try again or check Brevo settings.',
        )
      }
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Password reset failed')
    }
  }

  async function onExport(format: 'csv' | 'pdf') {
    setExportMsg('')
    try {
      await exportUsers({
        format,
        search: search.trim() || undefined,
        role: role || undefined,
        status: status || undefined,
      })
      setExportMsg(`${format.toUpperCase()} downloaded.`)
    } catch (err) {
      setExportMsg(err instanceof Error ? err.message : 'Export failed')
    }
  }

  return (
    <>
      <div className="page-toolbar">
        <div className="grow">
          <input
            className="search-input"
            placeholder="Search users…"
            value={search}
            onChange={(e) => {
              setPage(1)
              setSearch(e.target.value)
            }}
          />
        </div>
        <select
          className="select-input"
          style={{ maxWidth: 180 }}
          value={role}
          onChange={(e) => {
            setPage(1)
            setRole(e.target.value)
          }}
          aria-label="Role"
        >
          <option value="">All Roles</option>
          {USER_ROLES.map((r) => (
            <option key={r} value={r}>
              {r}
            </option>
          ))}
        </select>
        <select
          className="select-input"
          style={{ maxWidth: 180 }}
          value={status}
          onChange={(e) => {
            setPage(1)
            setStatus(e.target.value)
          }}
          aria-label="Status"
        >
          <option value="">All Statuses</option>
          <option value="active">Active</option>
          <option value="suspended">Suspended</option>
          <option value="deactivated">Deactivated</option>
        </select>
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
        <button type="button" className="btn-primary" onClick={openCreate}>
          + Add New User
        </button>
      </div>

      {error ? (
        <div className="form-error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}
      {infoMsg ? (
        <div style={{ marginBottom: 12, color: 'var(--green)', fontSize: '0.9rem' }}>
          {infoMsg}
        </div>
      ) : null}
      {exportMsg ? (
        <div style={{ marginBottom: 12, color: 'var(--muted)', fontSize: '0.9rem' }}>
          {exportMsg}
        </div>
      ) : null}

      <div className="card table-wrap">
        {loading ? (
          <div className="loading">Loading users…</div>
        ) : users.length === 0 ? (
          <div className="empty">No users found</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Username</th>
                <th>Email</th>
                <th>Role</th>
                <th>Status</th>
                <th>Last Login</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr key={user.id}>
                  <td>
                    {user.name}
                    {user.must_change_password ? (
                      <div style={{ fontSize: '0.75rem', color: 'var(--orange)' }}>
                        Must change password
                      </div>
                    ) : null}
                  </td>
                  <td>{user.username}</td>
                  <td>{user.email}</td>
                  <td>{user.role}</td>
                  <td>
                    <span
                      className={`user-status ${
                        user.is_active ? 'active' : 'inactive'
                      }`}
                    >
                      {user.status}
                    </span>
                  </td>
                  <td>{user.last_login_display || '—'}</td>
                  <td>
                    <div className="actions">
                      <button
                        type="button"
                        className="action-btn"
                        onClick={() => openEdit(user)}
                        aria-label="Edit"
                        title="Edit"
                      >
                        ✎
                      </button>
                      <button
                        type="button"
                        className="action-btn"
                        onClick={() => void onResetPassword(user)}
                        aria-label="Reset password"
                        title="Reset temporary password"
                      >
                        🔑
                      </button>
                      {user.is_active ? (
                        <button
                          type="button"
                          className="action-btn"
                          onClick={() => void onSuspend(user)}
                          aria-label="Suspend"
                          title="Suspend"
                        >
                          ⏸
                        </button>
                      ) : (
                        <button
                          type="button"
                          className="action-btn"
                          onClick={() => void onReactivate(user)}
                          aria-label="Reactivate"
                          title="Reactivate"
                        >
                          ▶
                        </button>
                      )}
                      <button
                        type="button"
                        className="action-btn danger"
                        onClick={() => void onDeactivate(user)}
                        aria-label="Deactivate"
                        title="Deactivate (keep records)"
                      >
                        🗑
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        <div className="pagination users-pagination">
          <span className="pagination-meta">
            Showing {from} to {to} of {count} records
          </span>
          <div className="pagination-btns">
            <button
              type="button"
              className="page-btn"
              disabled={page <= 1}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              aria-label="Previous page"
            >
              ‹
            </button>
            <button type="button" className="page-btn active">
              {page}
            </button>
            <button
              type="button"
              className="page-btn"
              disabled={page >= totalPages}
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              aria-label="Next page"
            >
              ›
            </button>
          </div>
        </div>
      </div>

      <Modal
        title={editing ? 'Edit User' : 'Add New User'}
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        footer={
          <>
            <button
              type="button"
              className="btn-secondary"
              onClick={() => setModalOpen(false)}
            >
              Cancel
            </button>
            <button
              type="button"
              className="btn-primary"
              disabled={saving}
              onClick={() => void onSave()}
            >
              {saving ? 'Saving…' : editing ? 'Save' : 'Create & email temp password'}
            </button>
          </>
        }
      >
        <p style={{ marginTop: 0, color: 'var(--muted)', fontSize: '0.9rem' }}>
          {editing
            ? 'Update staff details. Use the key action in the table to email a new temporary password.'
            : 'No public signup. A one-time temporary password is generated and emailed. The user must change it on first login.'}
        </p>
        <div className="form-grid">
          <div className="field">
            <label>First name</label>
            <input
              value={form.first_name}
              onChange={(e) =>
                setForm((f) => ({ ...f, first_name: e.target.value }))
              }
            />
          </div>
          <div className="field">
            <label>Last name</label>
            <input
              value={form.last_name}
              onChange={(e) =>
                setForm((f) => ({ ...f, last_name: e.target.value }))
              }
            />
          </div>
          <div className="field">
            <label>Username</label>
            <input
              value={form.username}
              onChange={(e) =>
                setForm((f) => ({ ...f, username: e.target.value }))
              }
              placeholder="Optional — defaults from email"
            />
          </div>
          <div className="field">
            <label>Registered email</label>
            <input
              type="email"
              value={form.email}
              onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
              required
            />
          </div>
          <div className="field">
            <label>Role</label>
            <select
              value={form.role}
              onChange={(e) => setForm((f) => ({ ...f, role: e.target.value }))}
            >
              {USER_ROLES.map((r) => (
                <option key={r} value={r}>
                  {r}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <label>Account status</label>
            <select
              value={form.account_status}
              onChange={(e) =>
                setForm((f) => ({ ...f, account_status: e.target.value }))
              }
            >
              <option value="active">Active</option>
              <option value="suspended">Suspended</option>
              <option value="deactivated">Deactivated</option>
            </select>
          </div>
        </div>
      </Modal>
    </>
  )
}
