import { useEffect, useState, type FormEvent } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ApiError } from '../api/client'
import {
  createItem,
  fetchCategories,
  fetchItem,
  fetchLocations,
  updateItem,
} from '../api/inventory'

const UNITS = ['Each', 'Pair', 'Box', 'Pack', 'Set', 'Bottle', 'Litre', 'Roll']

const emptyForm = {
  name: '',
  code: '',
  category: '',
  unit: '',
  location: '',
  reorder_level: '',
  quantity: '0',
  description: '',
  image: '',
}

export function ItemFormPage() {
  const { code } = useParams()
  const navigate = useNavigate()
  const editing = Boolean(code)
  const [form, setForm] = useState(emptyForm)
  const [categories, setCategories] = useState<string[]>([])
  const [locations, setLocations] = useState<string[]>([])
  const [saving, setSaving] = useState(false)
  const [loading, setLoading] = useState(editing)
  const [error, setError] = useState('')
  const [preview, setPreview] = useState<string | null>(null)

  useEffect(() => {
    void Promise.all([fetchCategories(), fetchLocations()]).then(
      ([cats, locs]) => {
        setCategories(cats.categories)
        setLocations(locs.locations)
      },
    )
  }, [])

  useEffect(() => {
    if (!code) return
    let cancelled = false
    setLoading(true)
    fetchItem(code)
      .then((item) => {
        if (cancelled) return
        setForm({
          name: item.name,
          code: item.code,
          category: item.category,
          unit: item.unit,
          location: item.location,
          reorder_level: String(item.reorder_level),
          quantity: String(item.quantity),
          description: item.description,
          image: item.image,
        })
        if (item.image) setPreview(item.image)
      })
      .catch((err: Error) => {
        if (!cancelled) setError(err.message)
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [code])

  function onFileChange(file: File | null) {
    if (!file) {
      setPreview(null)
      return
    }
    if (file.size > 2 * 1024 * 1024) {
      setError('Image must be under 2MB')
      return
    }
    const url = URL.createObjectURL(file)
    setPreview(url)
    // Backend expects a URL string; keep blank until media upload exists
    setForm((f) => ({ ...f, image: '' }))
  }

  async function onSave(e: FormEvent) {
    e.preventDefault()
    setSaving(true)
    setError('')
    try {
      const payload = {
        name: form.name.trim(),
        code: form.code.trim(),
        category: form.category,
        unit: form.unit,
        location: form.location,
        reorder_level: Number(form.reorder_level) || 0,
        quantity: Number(form.quantity) || 0,
        description: form.description.trim(),
        image: form.image || '',
      }
      if (editing && code) {
        await updateItem(code, payload)
      } else {
        await createItem(payload)
      }
      navigate('/items')
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Could not save item')
    } finally {
      setSaving(false)
    }
  }

  if (loading) return <div className="loading">Loading item…</div>

  return (
    <form className="form-page" onSubmit={(e) => void onSave(e)}>
      <div className="card form-page-card">
        <div className="form-page-head">
          <h2>Item Details</h2>
          <p>Enter the details below to {editing ? 'update this' : 'add a new'} item to inventory.</p>
        </div>

        {error ? <div className="form-error">{error}</div> : null}

        <div className="item-form-layout">
          <div className="item-form-main">
            <div className="form-grid-4">
              <div className="field">
                <label htmlFor="name">
                  Item Name <span className="req">*</span>
                </label>
                <input
                  id="name"
                  placeholder="Enter item name"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  required
                />
              </div>
              <div className="field">
                <label htmlFor="code">
                  SKU / Item Code <span className="req">*</span>
                </label>
                <input
                  id="code"
                  placeholder="Enter SKU or item code"
                  value={form.code}
                  onChange={(e) => setForm({ ...form, code: e.target.value })}
                  disabled={editing}
                  required
                />
              </div>
              <div className="field">
                <label htmlFor="category">
                  Category <span className="req">*</span>
                </label>
                <input
                  id="category"
                  list="category-options"
                  placeholder="Select category"
                  value={form.category}
                  onChange={(e) => setForm({ ...form, category: e.target.value })}
                  required
                />
                <datalist id="category-options">
                  {categories.map((c) => (
                    <option key={c} value={c} />
                  ))}
                </datalist>
              </div>
              <div className="field">
                <label htmlFor="unit">
                  Unit <span className="req">*</span>
                </label>
                <input
                  id="unit"
                  list="unit-options"
                  placeholder="Select unit"
                  value={form.unit}
                  onChange={(e) => setForm({ ...form, unit: e.target.value })}
                  required
                />
                <datalist id="unit-options">
                  {UNITS.map((u) => (
                    <option key={u} value={u} />
                  ))}
                </datalist>
              </div>
            </div>

            <div className="form-grid-2" style={{ marginTop: 14 }}>
              <div className="field">
                <label htmlFor="location">
                  Location <span className="req">*</span>
                </label>
                <input
                  id="location"
                  list="location-options"
                  placeholder="Select location"
                  value={form.location}
                  onChange={(e) => setForm({ ...form, location: e.target.value })}
                  required
                />
                <datalist id="location-options">
                  {locations.map((l) => (
                    <option key={l} value={l} />
                  ))}
                </datalist>
              </div>
              <div className="field">
                <label htmlFor="reorder">
                  Minimum Stock Level <span className="req">*</span>
                </label>
                <input
                  id="reorder"
                  type="number"
                  min={0}
                  placeholder="Enter minimum stock level"
                  value={form.reorder_level}
                  onChange={(e) =>
                    setForm({ ...form, reorder_level: e.target.value })
                  }
                  required
                />
              </div>
            </div>

            {!editing ? (
              <div className="field" style={{ marginTop: 14, maxWidth: 280 }}>
                <label htmlFor="qty">Initial Stock</label>
                <input
                  id="qty"
                  type="number"
                  min={0}
                  value={form.quantity}
                  onChange={(e) => setForm({ ...form, quantity: e.target.value })}
                />
              </div>
            ) : null}

            <div className="field" style={{ marginTop: 14 }}>
              <label htmlFor="description">Description</label>
              <textarea
                id="description"
                rows={5}
                placeholder="Enter item description (optional)"
                value={form.description}
                onChange={(e) =>
                  setForm({ ...form, description: e.target.value })
                }
              />
            </div>
          </div>

          <div className="item-image-panel field">
            <label>Item Image (Optional)</label>
            <div
              className="image-drop"
              onDragOver={(e) => e.preventDefault()}
              onDrop={(e) => {
                e.preventDefault()
                onFileChange(e.dataTransfer.files?.[0] ?? null)
              }}
            >
              {preview ? (
                <img src={preview} alt="Preview" />
              ) : (
                <>
                  <div className="upload-icon">☁</div>
                  <p>Drag and drop an image here or</p>
                  <label className="btn-secondary choose-file">
                    Choose File
                    <input
                      type="file"
                      accept="image/jpeg,image/png"
                      hidden
                      onChange={(e) =>
                        onFileChange(e.target.files?.[0] ?? null)
                      }
                    />
                  </label>
                  <span className="hint">JPG, PNG up to 2MB</span>
                </>
              )}
            </div>
          </div>
        </div>

        <div className="form-page-actions">
          <button
            type="button"
            className="btn-secondary"
            onClick={() => navigate('/items')}
          >
            Cancel
          </button>
          <button type="submit" className="btn-primary" disabled={saving}>
            {saving ? 'Saving…' : editing ? 'Save Changes' : 'Save Item'}
          </button>
        </div>
      </div>
    </form>
  )
}

