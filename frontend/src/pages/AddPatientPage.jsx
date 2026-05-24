// ============ FILE: frontend/src/pages/AddPatientPage.jsx ============
import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { patientService, medApi } from '../services/api'
import { ArrowLeft, Upload, User } from 'lucide-react'
import toast from 'react-hot-toast'

const AddPatientPage = () => {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [photoPreview, setPhotoPreview] = useState(null)
  const [photoFile, setPhotoFile] = useState(null)
  const [errors, setErrors] = useState({})
  const [form, setForm] = useState({
    name: '', birth_date: '', gender: 'male', address: '',
    blood_type: '', medical_notes: '', caregiver_id: ''
  })

  const validate = () => {
    const errs = {}
    if (!form.name || form.name.trim().length < 2) errs.name = 'Nama minimal 2 karakter'
    if (!form.birth_date) errs.birth_date = 'Tanggal lahir wajib diisi'
    if (!form.gender) errs.gender = 'Jenis kelamin wajib dipilih'
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
      // 1. Create patient without photo first
      const payload = { ...form }
      if (!payload.blood_type) delete payload.blood_type
      if (!payload.caregiver_id) delete payload.caregiver_id

      console.log('1️⃣ Creating patient with data:', payload)
      const res = await patientService.create(payload)
      let newPatient = res.data.data.patient
      console.log('✅ Patient created:', newPatient)

      // 2. If photo provided, upload to separate endpoint
      if (photoFile) {
        try {
          console.log('2️⃣ Uploading photo for patient', newPatient.id)
          const fd = new FormData()
          fd.append('photo', photoFile)
          
          const photoRes = await medApi.post(`/patients/${newPatient.id}/photo`, fd)
          newPatient = photoRes.data.data.patient
          console.log('✅ Photo uploaded. Patient photo_url:', newPatient.photo_url)
        } catch (photoError) {
          console.error('❌ Photo upload failed:', photoError)
          toast.error('Lansia berhasil ditambahkan, tapi gagal mengunggah foto (cek konfigurasi Cloud Storage).')
          navigate('/patients')
          setLoading(false)
          return
        }
      }

      toast.success('Data lansia berhasil ditambahkan!')
      navigate('/patients')
    } catch (e) {
      console.error('❌ Error:', e.response?.data || e.message)
      toast.error(e.response?.data?.message || 'Gagal menambah data lansia')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto animate-fade-in">
      <div className="flex items-center gap-3 mb-6">
        <button onClick={() => navigate('/patients')} className="btn-ghost btn-sm p-2">
          <ArrowLeft size={18} />
        </button>
        <div>
          <h1 className="page-title">Tambah Lansia</h1>
          <p className="page-subtitle">Isi data lengkap pasien lansia</p>
        </div>
      </div>

      <form onSubmit={handleSubmit}>
        <div className="card mb-4">
          <div className="card-header"><h3 className="font-semibold text-slate-700">Foto Profil</h3></div>
          <div className="card-body flex items-center gap-6">
            <div className="w-24 h-24 rounded-2xl bg-slate-100 overflow-hidden flex items-center justify-center border-2 border-dashed border-slate-300 flex-shrink-0">
              {photoPreview ? (
                <img src={photoPreview} alt="Preview" className="w-full h-full object-cover" />
              ) : (
                <User size={32} className="text-slate-300" />
              )}
            </div>
            <div>
              <label htmlFor="photo" className="btn-secondary cursor-pointer inline-flex items-center gap-2">
                <Upload size={15} /> Pilih Foto
              </label>
              <input id="photo" type="file" accept="image/*" className="hidden" onChange={handlePhotoChange} />
              <p className="text-xs text-slate-400 mt-2">JPG, PNG, GIF, WebP. Maks 5MB</p>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="card-header"><h3 className="font-semibold text-slate-700">Informasi Pribadi</h3></div>
          <div className="card-body space-y-4">
            <div>
              <label className="form-label">Nama Lengkap <span className="text-red-500">*</span></label>
              <input className={`form-input ${errors.name ? 'form-input-error' : ''}`}
                placeholder="Nama lengkap lansia"
                value={form.name} onChange={e => setForm(p => ({ ...p, name: e.target.value }))} />
              {errors.name && <p className="form-error">{errors.name}</p>}
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="form-label">Tanggal Lahir <span className="text-red-500">*</span></label>
                <input type="date" className={`form-input ${errors.birth_date ? 'form-input-error' : ''}`}
                  value={form.birth_date} onChange={e => setForm(p => ({ ...p, birth_date: e.target.value }))} />
                {errors.birth_date && <p className="form-error">{errors.birth_date}</p>}
              </div>
              <div>
                <label className="form-label">Jenis Kelamin <span className="text-red-500">*</span></label>
                <select className="form-select" value={form.gender}
                  onChange={e => setForm(p => ({ ...p, gender: e.target.value }))}>
                  <option value="male">Laki-laki</option>
                  <option value="female">Perempuan</option>
                </select>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="form-label">Golongan Darah</label>
                <select className="form-select" value={form.blood_type}
                  onChange={e => setForm(p => ({ ...p, blood_type: e.target.value }))}>
                  <option value="">-- Pilih --</option>
                  <option value="A">A</option>
                  <option value="B">B</option>
                  <option value="AB">AB</option>
                  <option value="O">O</option>
                </select>
              </div>
              <div>
                <label className="form-label">ID Caregiver</label>
                <input type="number" className="form-input" placeholder="ID user caregiver"
                  value={form.caregiver_id} onChange={e => setForm(p => ({ ...p, caregiver_id: e.target.value }))} />
              </div>
            </div>

            <div>
              <label className="form-label">Alamat</label>
              <textarea rows={2} className="form-textarea" placeholder="Alamat lengkap..."
                value={form.address} onChange={e => setForm(p => ({ ...p, address: e.target.value }))} />
            </div>

            <div>
              <label className="form-label">Catatan Medis</label>
              <textarea rows={3} className="form-textarea" placeholder="Riwayat penyakit, alergi, kondisi khusus..."
                value={form.medical_notes} onChange={e => setForm(p => ({ ...p, medical_notes: e.target.value }))} />
            </div>

            <div className="flex gap-3 pt-2">
              <button type="button" onClick={() => navigate('/patients')} className="btn-secondary flex-1">Batal</button>
              <button type="submit" className="btn-primary flex-1" disabled={loading}>
                {loading && <span className="spinner w-4 h-4" />}
                {loading ? 'Menyimpan...' : 'Simpan Data'}
              </button>
            </div>
          </div>
        </div>
      </form>
    </div>
  )
}

export default AddPatientPage
