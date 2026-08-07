import { useEffect, useMemo, useState, type FormEvent } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { ApiError } from '../api/client'
import {
  createMovement,
  fetchItems,
  fetchLocations,
  fetchNextReference,
} from '../api/inventory'
import type { Item } from '../api/types'
import { useAuth } from '../auth/AuthContext'

export function AddStockPage() {
  const { displayName } = useAuth()
  const navigate = useNavigate()
  const [params] = useSearchParams()
  const preset = params.get('item') ?? ''

  const [items, setItems] = useState<Item[]>([])
  const [locations, setLocations] = useState<string[]>([])
  const [itemQuery, setItemQuery] = useState('')
  const [referenceNo, setReferenceNo] = useState('')
  const [form, setForm] = useState({
    item_code: preset,
    quantity: '',
    unit: '',
    location: '',
    supplier: '',
    date: new Date().toISOString().slice(0, 10),
    notes: '',
  })
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    void Promise.all([
      fetchItems({ page_size: 500, sort: 'name_asc' }),
      fetchLocations(),
      fetchNextReference(),
    ]).then(([itemData, locs, ref]) => {
      setItems(itemData.results)
      setLocations(locs.locations)
      setReferenceNo(ref.reference_no)
      if (preset) {
        const found = itemData.results.find(
          (i) => i.code.toLowerCase() === preset.toLowerCase(),
        )
        if (found) {
          setForm((f) => ({
            ...f,
            item_code: found.code,
            unit: found.unit,
            location: found.location,
          }))
          setItemQuery(`${found.code} — ${found.name}`)
        }
      }
    })
  }, [preset])

  const selected = useMemo(
    () => items.find((i) => i.code === form.item_code) ?? null,
    [items, form.item_code],
  )

  const qty = Number(form.quantity) || 0
  const newStock = (selected?.quantity ?? 0) + qty

  const filtered = useMemo(() => {
    const q = itemQuery.trim().toLowerCase()
    if (!q || form.item_code) return items.slice(0, 40)
    return items
      .filter(
        (i) =>
          i.name.toLowerCase().includes(q) ||
          i.code.toLowerCase().includes(q),
      )
      .slice(0, 40)
  }, [items, itemQuery, form.item_code])

  async function onSave(e: FormEvent) {
    e.preventDefault()
    if (!form.item_code) {
      setError('Please select an item')
      return
    }
    setSaving(true)
    setError('')
    try {
      await createMovement({
        type: 'stock_in',
        item_code: form.item_code,
        quantity: qty,
        requested_by: displayName,
        location: form.location || undefined,
        notes: [form.supplier ? `Supplier: ${form.supplier}` : '', form.notes]
          .filter(Boolean)
          .join(' · '),
        // Let the API assign the next WO##### reference
        date: form.date
          ? new Date(`${form.date}T12:00:00`).toISOString()
          : undefined,
      })
      navigate('/stock-in')
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Could not add stock')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="stock-form-layout">
      <form className="card form-page-card" onSubmit={(e) => void onSave(e)}>
        <div className="form-page-head">
          <h2>Stock Entry Details</h2>
          <p>Record incoming stock against an existing catalogue item.</p>
        </div>
        {error ? <div className="form-error">{error}</div> : null}

        <div className="field">
          <label>
            Select Item <span className="req">*</span>
          </label>
          <input
            placeholder="Search and select an item"
            value={itemQuery}
            onChange={(e) => {
              setItemQuery(e.target.value)
              setForm({ ...form, item_code: '' })
            }}
            required={!form.item_code}
          />
          {!form.item_code && itemQuery.trim() ? (
            <div className="item-suggest">
              {filtered.map((i) => (
                <button
                  type="button"
                  key={i.code}
                  onClick={() => {
                    setForm({
                      ...form,
                      item_code: i.code,
                      unit: i.unit,
                      location: form.location || i.location,
                    })
                    setItemQuery(`${i.code} — ${i.name}`)
                  }}
                >
                  <strong>{i.name}</strong>
                  <span>{i.code}</span>
                </button>
              ))}
            </div>
          ) : null}
        </div>

        <div className="form-grid-2" style={{ marginTop: 14 }}>
          <div className="field">
            <label>
              Quantity <span className="req">*</span>
            </label>
            <input
              type="number"
              min={1}
              value={form.quantity}
              onChange={(e) => setForm({ ...form, quantity: e.target.value })}
              required
            />
          </div>
          <div className="field">
            <label>
              Unit <span className="req">*</span>
            </label>
            <input value={form.unit || selected?.unit || ''} disabled />
          </div>
          <div className="field">
            <label>
              Location <span className="req">*</span>
            </label>
            <select
              value={form.location}
              onChange={(e) => setForm({ ...form, location: e.target.value })}
              required
            >
              <option value="">Select location</option>
              {locations.map((l) => (
                <option key={l} value={l}>
                  {l}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <label>Reference No.</label>
            <input
              value={referenceNo || 'Generating…'}
              disabled
              readOnly
              title="Assigned automatically when you save"
            />
            <span
              style={{
                display: 'block',
                marginTop: 6,
                fontSize: '0.78rem',
                color: 'var(--muted)',
              }}
            >
              Generated automatically on save
            </span>
          </div>
          <div className="field">
            <label>Supplier</label>
            <input
              value={form.supplier}
              onChange={(e) => setForm({ ...form, supplier: e.target.value })}
              placeholder="Optional"
            />
          </div>
          <div className="field">
            <label>
              Date <span className="req">*</span>
            </label>
            <input
              type="date"
              value={form.date}
              onChange={(e) => setForm({ ...form, date: e.target.value })}
              required
            />
          </div>
        </div>

        <div className="field" style={{ marginTop: 14 }}>
          <label>Notes (Optional)</label>
          <textarea
            rows={4}
            value={form.notes}
            onChange={(e) => setForm({ ...form, notes: e.target.value })}
          />
        </div>

        <div className="form-page-actions">
          <button
            type="button"
            className="btn-secondary"
            onClick={() => navigate(-1)}
          >
            Cancel
          </button>
          <button type="submit" className="btn-primary" disabled={saving}>
            {saving ? 'Saving…' : 'Add Stock'}
          </button>
        </div>
      </form>

      <div className="stock-side">
        <div className="card panel">
          <h2 className="panel-title">Item Summary</h2>
          {selected ? (
            <>
              <div className="summary-thumb">
                {selected.image ? (
                  <img src={selected.image} alt="" />
                ) : (
                  <span>📦</span>
                )}
              </div>
              <strong style={{ display: 'block', marginTop: 12 }}>
                {selected.name}
              </strong>
              <p style={{ color: 'var(--muted)', margin: '6px 0 12px' }}>
                SKU: {selected.code}
              </p>
              <span className="status-badge in_stock">{selected.category}</span>
              <div className="summary-facts">
                <div>
                  <span>Current Stock</span>
                  <strong>
                    {selected.quantity} {selected.unit}
                  </strong>
                </div>
                <div>
                  <span>Location</span>
                  <strong>{selected.location}</strong>
                </div>
                <div>
                  <span>Minimum Stock Level</span>
                  <strong>
                    {selected.reorder_level} {selected.unit}
                  </strong>
                </div>
              </div>
            </>
          ) : (
            <div className="empty">Select an item to preview details</div>
          )}
        </div>

        <div className="card panel preview-card">
          <h2 className="panel-title">Stock Update Preview</h2>
          <div className="preview-row">
            <span>Quantity to add</span>
            <strong className="green">
              + {qty} {selected?.unit || 'Each'}
            </strong>
          </div>
          <div className="preview-row">
            <span>New stock after update</span>
            <strong>
              {selected ? `${newStock} ${selected.unit}` : '—'}
            </strong>
          </div>
        </div>
      </div>
    </div>
  )
}
