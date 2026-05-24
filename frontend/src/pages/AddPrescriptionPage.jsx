// ============ FILE: frontend/src/pages/AddPrescriptionPage.jsx ============
import React, { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { patientService, medicationService, prescriptionService } from '../services/api'
import { ArrowLeft, FileText } from 'lucide-react'
import toast from 'react-hot-toast'

const AddPrescriptionPage = () => {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const defaultPatientId = searchParams.get('patientId') || ''

  const [patients, setPatients] = useState([])
  const [medications, setMedications] = useState([])
  const [loading, setLoading] = useState(false)
  const [errors, setErrors] = useState({})
  const [form, setForm] = useState({
    patient_id: defaultPatientId,
    medication_id: '',
    dosage: '',
    frequency: '',
    start_date: new Date().toISOString().split('T')[0],
    end_date: '',
    doctor_name: '',
    notes: '',
    status: 'active'
  })

  useEffect(() => {
    fetchPatients()
    fetchMedications()
  }, [])

  const fetchPatients = async () => {
    try {
      const res = await patientService.getAll({ limit: 100 })
      setPatients(res.data.data.patients || [])
    } catch {}
  }

  const fetchMedications = async () => {
    try {
      const res = await medicationService.getAll({ limit: 100 })
      setMedications(res.data.data.medications || [])
    } catch {}
  }

  const validate = () => {
    const errs = {}
    if (!form.patient_id) errs.patient_id = 'Pilih pasien terlebih dahulu'
    if (!form.medication_id) errs.medication_id = 'Pilih obat terlebih dahulu'
    if (!form.dosage) errs.dosage = 'Dosis wajib diisi'
    if (!form.frequency) errs.frequency = 'Frekuensi wajib diisi'
    if (!form.start_date) errs.start_date = 'Tanggal mulai wajib diisi'
    return errs
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const errs = validate()
    if (Object.keys(errs).length > 0) { setErrors(errs); return }
    setErrors({})
    setLoading(true)
    try {
      const payload = {
        ...form,
        patient_id: parseInt(form.patient_id),
        medication_id: parseInt(form.medication_id),
        end_date: form.end_date || null,
      }
      await prescriptionService.create(payload)
      toast.success('Resep berhasil ditambahkan!')
      if (defaultPatientId) navigate(`/patients/${defaultPatientId}`)
      else navigate('/patients')
    } catch (e) {
      toast.error(e.response?.data?.message || 'Gagal menambah resep')
    } finally {
      setLoading(false)
    }
  }

  const FREQUENCIES = ['1x sehari', '2x sehari', '3x sehari', '4x sehari',
    '1x sehari (pagi)', '1x sehari (malam)', '2x sehari (pagi & malam)', 'Saat diperlukan']

  return (
    <div className="max-w-2xl mx-auto animate-fade-in">
      <div className="flex items-center gap-3 mb-6">
        <button onClick={() => navigate(-1)} className="btn-ghost btn-sm p-2"><ArrowLeft size={18} /></button>
        <div>
          <h1 className="page-title">Tambah Resep</h1>
          <p className="page-subtitle">Buat resep baru untuk pasien lansia</p>
        </div>
      </div>

      <form onSubmit={handleSubmit}>
        <div className="card">
          <div className="card-header">
            <div className="flex items-center gap-2">
              <FileText size={18} className="text-primary-500" />
              <h3 className="font-semibold text-slate-700">Detail Resep</h3>
            </div>
          </div>
          <div className="card-body space-y-4">
            {/* Patient Select */}
            <div>
              <label className="form-label">Pasien Lansia <span className="text-red-500">*</span></label>
              <select className={`form-select ${errors.patient_id ? 'form-input-error' : ''}`}
                value={form.patient_id} onChange={e => setForm(p => ({ ...p, patient_id: e.target.value }))}>
                <option value="">-- Pilih Pasien --</option>
                {patients.map(p => (
                  <option key={p.id} value={p.id}>{p.name}</option>
                ))}
              </select>
              {errors.patient_id && <p className="form-error">{errors.patient_id}</p>}
            </div>

            {/* Medication Select */}
            <div>
              <label className="form-label">Obat <span className="text-red-500">*</span></label>
              <select className={`form-select ${errors.medication_id ? 'form-input-error' : ''}`}
                value={form.medication_id} onChange={e => setForm(p => ({ ...p, medication_id: e.target.value }))}>
                <option value="">-- Pilih Obat --</option>
                {medications.map(m => (
                  <option key={m.id} value={m.id}>{m.name} ({m.unit})</option>
                ))}
              </select>
              {errors.medication_id && <p className="form-error">{errors.medication_id}</p>}
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="form-label">Dosis <span className="text-red-500">*</span></label>
                <input className={`form-input ${errors.dosage ? 'form-input-error' : ''}`}
                  placeholder="cth: 1 tablet, 5ml" value={form.dosage}
                  onChange={e => setForm(p => ({ ...p, dosage: e.target.value }))} />
                {errors.dosage && <p className="form-error">{errors.dosage}</p>}
              </div>
              <div>
                <label className="form-label">Frekuensi <span className="text-red-500">*</span></label>
                <select className={`form-select ${errors.frequency ? 'form-input-error' : ''}`}
                  value={form.frequency} onChange={e => setForm(p => ({ ...p, frequency: e.target.value }))}>
                  <option value="">-- Pilih --</option>
                  {FREQUENCIES.map(f => <option key={f} value={f}>{f}</option>)}
                </select>
                {errors.frequency && <p className="form-error">{errors.frequency}</p>}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="form-label">Tanggal Mulai <span className="text-red-500">*</span></label>
                <input type="date" className={`form-input ${errors.start_date ? 'form-input-error' : ''}`}
                  value={form.start_date} onChange={e => setForm(p => ({ ...p, start_date: e.target.value }))} />
                {errors.start_date && <p className="form-error">{errors.start_date}</p>}
              </div>
              <div>
                <label className="form-label">Tanggal Selesai</label>
                <input type="date" className="form-input"
                  value={form.end_date} onChange={e => setForm(p => ({ ...p, end_date: e.target.value }))} />
                <p className="text-xs text-slate-400 mt-1">Kosongkan jika tidak ada batas</p>
              </div>
            </div>

            <div>
              <label className="form-label">Nama Dokter</label>
              <input className="form-input" placeholder="cth: dr. Ahmad Yani, Sp.PD"
                value={form.doctor_name} onChange={e => setForm(p => ({ ...p, doctor_name: e.target.value }))} />
            </div>



            <div>
              <label className="form-label">Catatan</label>
              <textarea rows={3} className="form-textarea"
                placeholder="Instruksi khusus, efek samping yang perlu diwaspadai..."
                value={form.notes} onChange={e => setForm(p => ({ ...p, notes: e.target.value }))} />
            </div>

            <div className="flex gap-3 pt-2">
              <button type="button" onClick={() => navigate(-1)} className="btn-secondary flex-1">Batal</button>
              <button type="submit" className="btn-primary flex-1" disabled={loading}>
                {loading && <span className="spinner w-4 h-4" />}
                {loading ? 'Menyimpan...' : 'Simpan Resep'}
              </button>
            </div>
          </div>
        </div>
      </form>
    </div>
  )
}

export default AddPrescriptionPage
