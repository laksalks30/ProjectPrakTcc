// ============ FILE: frontend/src/pages/AddMedicationPage.jsx ============
import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { medicationService } from '../services/api'
import { ArrowLeft, Upload, Pill } from 'lucide-react'
import toast from 'react-hot-toast'

const CATEGORIES = ['Antihipertensi','Antidiabetes','Antihiperlipidemia','Antibiotik','Analgesik','Antiplatelet',
  'ACE Inhibitor','Bronkodilator','Antasida/PPI','Suplemen','Vitamin','Lainnya']

const AddMedicationPage = () => {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [photoPreview, setPhotoPreview] = useState(null)
  const [photoFile, setPhotoFile] = useState(null)
  const [errors, setErrors] = useState({})
  const [form, setForm] = useState({
    name: '', generic_name: '', category: '', description: '', unit: 'tablet'
  })

  const validate = () => {
    const errs = {}
    if (!form.name || form.name.trim().length < 2) errs.name = 'Nama obat minimal 2 karakter'
    if (!form.unit) errs.unit = 'Satuan wajib diisi'
    return errs
  }

  const handlePhotoChange = (e) => {
    const file = e.target.files[0]
    if (!file) return
    if (file.size > 5 * 1024 * 1024) { toast.error('Ukuran foto maksimal 5MB'); return }
    setPhotoFile(file)
    setPhotoPreview(URL.createObjectURL(file))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const errs = validate()
    if (Object.keys(errs).length > 0) { setErrors(errs); return }
    setErrors({})
    setLoading(true)
    try {
      const res = await medicationService.create(form)
      const newMed = res.data.data.medication
      if (photoFile) {
        const fd = new FormData()
        fd.append('photo', photoFile)
        await medicationService.update(newMed.id, fd)
      }
      toast.success('Data obat berhasil ditambahkan!')
      navigate('/medications')
    } catch (e) {
      toast.error(e.response?.data?.message || 'Gagal menambah data obat')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto animate-fade-in">
      <div className="flex items-center gap-3 mb-6">
        <button onClick={() => navigate('/medications')} className="btn-ghost btn-sm p-2"><ArrowLeft size={18} /></button>
        <div>
          <h1 className="page-title">Tambah Obat</h1>
          <p className="page-subtitle">Tambahkan data obat ke master data</p>
        </div>
      </div>

      <form onSubmit={handleSubmit}>
        <div className="card mb-4">
          <div className="card-header"><h3 className="font-semibold text-slate-700">Foto Obat</h3></div>
          <div className="card-body flex items-center gap-6">
            <div className="w-24 h-24 rounded-2xl bg-slate-100 overflow-hidden flex items-center justify-center border-2 border-dashed border-slate-300 flex-shrink-0">
              {photoPreview
                ? <img src={photoPreview} alt="Preview" className="w-full h-full object-cover" />
                : <Pill size={32} className="text-slate-300" />}
            </div>
            <div>
              <label htmlFor="photo" className="btn-secondary cursor-pointer inline-flex items-center gap-2">
                <Upload size={15} /> Pilih Foto
              </label>
              <input id="photo" type="file" accept="image/*" className="hidden" onChange={handlePhotoChange} />
              <p className="text-xs text-slate-400 mt-2">JPG, PNG, WebP. Maks 5MB</p>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="card-header"><h3 className="font-semibold text-slate-700">Informasi Obat</h3></div>
          <div className="card-body space-y-4">
            <div>
              <label className="form-label">Nama Obat <span className="text-red-500">*</span></label>
              <input className={`form-input ${errors.name ? 'form-input-error' : ''}`}
                placeholder="cth: Amlodipine 5mg"
                value={form.name} onChange={e => setForm(p => ({ ...p, name: e.target.value }))} />
              {errors.name && <p className="form-error">{errors.name}</p>}
            </div>

            <div>
              <label className="form-label">Nama Generik</label>
              <input className="form-input" placeholder="cth: Amlodipine Besylate"
                value={form.generic_name} onChange={e => setForm(p => ({ ...p, generic_name: e.target.value }))} />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="form-label">Kategori</label>
                <select className="form-select" value={form.category}
                  onChange={e => setForm(p => ({ ...p, category: e.target.value }))}>
                  <option value="">-- Pilih Kategori --</option>
                  {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>
              <div>
                <label className="form-label">Satuan <span className="text-red-500">*</span></label>
                <select className={`form-select ${errors.unit ? 'form-input-error' : ''}`}
                  value={form.unit} onChange={e => setForm(p => ({ ...p, unit: e.target.value }))}>
                  <option value="tablet">Tablet</option>
                  <option value="kapsul">Kapsul</option>
                  <option value="ml">ml (Sirup)</option>
                  <option value="puff">Puff (Inhaler)</option>
                  <option value="tetes">Tetes</option>
                  <option value="sachet">Sachet</option>
                  <option value="ampul">Ampul</option>
                </select>
                {errors.unit && <p className="form-error">{errors.unit}</p>}
              </div>
            </div>

            <div>
              <label className="form-label">Deskripsi</label>
              <textarea rows={4} className="form-textarea"
                placeholder="Deskripsi obat, cara kerja, indikasi..."
                value={form.description} onChange={e => setForm(p => ({ ...p, description: e.target.value }))} />
            </div>

            <div className="flex gap-3 pt-2">
              <button type="button" onClick={() => navigate('/medications')} className="btn-secondary flex-1">Batal</button>
              <button type="submit" className="btn-primary flex-1" disabled={loading}>
                {loading && <span className="spinner w-4 h-4" />}
                {loading ? 'Menyimpan...' : 'Simpan Obat'}
              </button>
            </div>
          </div>
        </div>
      </form>
    </div>
  )
}

export default AddMedicationPage
