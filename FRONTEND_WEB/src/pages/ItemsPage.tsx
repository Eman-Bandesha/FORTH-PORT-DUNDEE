import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  deleteItem,
  fetchCategories,
  fetchItems,
} from '../api/inventory'
import type { Item } from '../api/types'
import { StatusBadge } from '../components/StatusBadge'

export function ItemsPage() {
  const navigate = useNavigate()
  const [items, setItems] = useState<Item[]>([])
  const [count, setCount] = useState(0)
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [category, setCategory] = useState('')
  const [categories, setCategories] = useState<string[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const pageSize = 10

  const load = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const data = await fetchItems({
        search: search.trim() || undefined,
        category: category || undefined,
        page,
        page_size: pageSize,
        sort: 'name_asc',
      })
      setItems(data.results)
      setCount(data.count)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load items')
    } finally {
      setLoading(false)
    }
  }, [search, category, page])

  useEffect(() => {
    void load()
  }, [load])

  useEffect(() => {
    void fetchCategories().then((cats) => setCategories(cats.categories))
  }, [])

  const totalPages = Math.max(1, Math.ceil(count / pageSize))

  async function onDelete(item: Item) {
    if (!window.confirm(`Delete ${item.name}?`)) return
    try {
      await deleteItem(item.code)
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Delete failed')
    }
  }

  return (
    <>
      <div className="page-toolbar">
        <div className="grow">
          <input
            className="search-input"
            placeholder="Search by name or code…"
            value={search}
            onChange={(e) => {
              setPage(1)
              setSearch(e.target.value)
            }}
          />
        </div>
        <select
          className="select-input"
          style={{ maxWidth: 220 }}
          value={category}
          onChange={(e) => {
            setPage(1)
            setCategory(e.target.value)
          }}
        >
          <option value="">All categories</option>
          {categories.map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </select>
        <button
          type="button"
          className="btn-primary"
          onClick={() => navigate('/items/new')}
        >
          + Add New Item
        </button>
      </div>

      {error ? (
        <div className="form-error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <div className="card table-wrap">
        {loading ? (
          <div className="loading">Loading items…</div>
        ) : items.length === 0 ? (
          <div className="empty">No items found</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Item Code</th>
                <th>Item Name</th>
                <th>Category</th>
                <th>Unit</th>
                <th>Current Stock</th>
                <th>Min. Stock</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {items.map((item) => (
                <tr key={item.code}>
                  <td>{item.code}</td>
                  <td>{item.name}</td>
                  <td>{item.category}</td>
                  <td>{item.unit}</td>
                  <td>{item.quantity}</td>
                  <td>{item.reorder_level}</td>
                  <td>
                    <StatusBadge status={item.status} />
                  </td>
                  <td>
                    <div className="actions">
                      <button
                        type="button"
                        className="action-btn"
                        onClick={() =>
                          navigate(`/items/${encodeURIComponent(item.code)}/edit`)
                        }
                        aria-label="Edit"
                      >
                        ✎
                      </button>
                      <button
                        type="button"
                        className="action-btn danger"
                        onClick={() => void onDelete(item)}
                        aria-label="Delete"
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
          {totalPages > 8 ? (
            <span style={{ alignSelf: 'center' }}>… {totalPages}</span>
          ) : null}
        </div>
      </div>
    </>
  )
}
