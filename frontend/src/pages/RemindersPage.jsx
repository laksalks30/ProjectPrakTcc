// ============ FILE: frontend/src/pages/RemindersPage.jsx ============
import React, { useEffect, useState } from 'react'
import { patientService, reminderService, prescriptionService } from '../services/api'
import ReminderItem from '../components/ReminderItem'
import { Bell, Plus, X } from 'lucide-react'
import toast from 'react-hot-toast'
import { useAuth } from '../context/AuthContext'

const DAYS = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']
const DAY_LABELS = { monday:'Senin', tuesday:'Selasa', wednesday:'Rabu', thursday:'Kamis', friday:'Jumat', saturday:'Sabtu', sunday:'Minggu' }

const RemindersPage = () => {
  const { user } = useAuth()
  const [patients, setPatients] = useState([])
  const [selectedPatient, setSelectedPatient] = useState('')
  const [prescriptions, setPrescriptions] = useState([])
  const [reminders, setReminders] = useState([])
  const [loading, setLoading] = useState(false)
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ prescription_id: '', patient_id: '', scheduled_times: ['08:00'], days_of_week: [...DAYS], notes: '' })
  const [formLoading, setFormLoading] = useState(false)
  const [errors, setErrors] = useState({})

  useEffect(() => {
    patientService.getAll({ limit: 100 }).then(r => {
      const fetchedPatients = r.data.data.patients || [];
      setPatients(fetchedPatients);
      if (user?.role === 'user' && fetchedPatients.length > 0) {
        setSelectedPatient(fetchedPatients[0].id.toString());
        setForm(p => ({ ...p, patient_id: fetchedPatients[0].id.toString() }));
      }
    }).catch(() => {})
  }, [user])

  useEffect(() => {
    if (selectedPatient) {
      fetchReminders(selectedPatient)
      prescriptionService.getByPatient(selectedPatient, { status: 'active' })
        .then(r => setPrescriptions(r.data.data.prescriptions || [])).catch(() => {})
    } else {
      setReminders([])
      setPrescriptions([])
    }
  }, [selectedPatient])

  const fetchReminders = async (patientId) => {
    setLoading(true)
    try {
      const res = await reminderService.getByPatient(patientId)
      setReminders(res.data.data.reminders || [])
    } catch { toast.error('Gagal memuat reminder') }
    finally { setLoading(false) }
  }

  const toggleDay = (day) => {
    setForm(p => ({
      ...p,
      days_of_week: p.days_of_week.includes(day)
        ? p.days_of_week.filter(d => d !== day)
        : [...p.days_of_week, day]
    }))
  }

  const validate = () => {
    const errs = {}
    if (!selectedPatient) errs.patient_id = 'Pilih pasien'
    if (!form.prescription_id) errs.prescription_id = 'Pilih resep'
    if (form.scheduled_times.some(t => !t)) errs.scheduled_times = 'Semua waktu wajib diisi'
    if (form.days_of_week.length === 0) errs.days_of_week = 'Pilih minimal 1 hari'
    return errs
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const errs = validate()
    if (Object.keys(errs).length > 0) { setErrors(errs); return }
    setErrors({})
    setFormLoading(true)
    try {
      const promises = form.scheduled_times.map(time => {
        return reminderService.create({ 
          ...form, 
          scheduled_time: time,
          patient_id: parseInt(selectedPatient), 
          prescription_id: parseInt(form.prescription_id) 
        })
      })
      await Promise.all(promises)
      toast.success('Reminder berhasil dibuat!')
      setShowForm(false)
      setForm({ prescription_id: '', patient_id: selectedPatient, scheduled_times: ['08:00'], days_of_week: [...DAYS], notes: '' })
      fetchReminders(selectedPatient)
    } catch (e) {
      toast.error(e.response?.data?.message || 'Gagal membuat reminder')
    } finally { setFormLoading(false) }
  }

  const handleDelete = async (id) => {
    if (!window.confirm('Hapus reminder ini?')) return
    try {
      await reminderService.delete(id)
      toast.success('Reminder dihapus')
      setReminders(prev => prev.filter(r => r.id !== id))
    } catch { toast.error('Gagal menghapus reminder') }
  }

  const handleToggle = async (id, isActive) => {
    try {
      await reminderService.update(id, { is_active: isActive })
      setReminders(prev => prev.map(r => r.id === id ? { ...r, is_active: isActive } : r))
      toast.success(isActive ? 'Reminder diaktifkan' : 'Reminder dinonaktifkan')
    } catch { toast.error('Gagal mengubah status reminder') }
  }

  return (
    <div className="space-y-5 animate-fade-in">
      <div className="page-header">
        <div>
          <h1 className="page-title">Jadwal Reminder</h1>
          <p className="page-subtitle">Kelola pengingat minum obat per pasien</p>
        </div>
        {user?.role === 'user' && (
          <button onClick={() => { setShowForm(!showForm); setForm(p => ({ ...p, patient_id: selectedPatient })) }}
            className="btn-primary">
            {showForm ? <><X size={16} /> Tutup</> : <><Plus size={16} /> Tambah Reminder</>}
          </button>
        )}
      </div>

      {/* Patient Selector */}
      <div className="card p-4">
        <label className="form-label">Pilih Pasien</label>
        <select className="form-select max-w-sm" value={selectedPatient}
          onChange={e => { setSelectedPatient(e.target.value); setForm(p => ({ ...p, patient_id: e.target.value })) }}>
          <option value="">-- Pilih Pasien --</option>
          {patients.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
      </div>

      {/* Add Form */}
      {showForm && (
        <div className="card animate-slide-up">
          <div className="card-header"><h3 className="font-semibold text-slate-700">Form Tambah Reminder</h3></div>
          <form onSubmit={handleSubmit} className="card-body space-y-4">
            <div>
              <label className="form-label">Resep Aktif <span className="text-red-500">*</span></label>
              <select className={`form-select ${errors.prescription_id ? 'form-input-error' : ''}`}
                value={form.prescription_id} 
                onChange={e => {
                  const pid = e.target.value
                  const rx = prescriptions.find(r => r.id.toString() === pid)
                  let times = ['08:00']
                  if (rx && rx.frequency) {
                    const match = rx.frequency.match(/(\d+)x/)
                    if (match) {
                      const count = parseInt(match[1])
                      if (count === 1) times = ['08:00']
                      else if (count === 2) times = ['08:00', '20:00']
                      else if (count === 3) times = ['08:00', '13:00', '18:00']
                      else if (count === 4) times = ['06:00', '12:00', '18:00', '23:59']
                      else times = Array(count).fill('08:00')
                    }
                  }
                  setForm(p => ({ ...p, prescription_id: pid, scheduled_times: times }))
                }}>
                <option value="">-- Pilih Resep --</option>
                {prescriptions.map(rx => (
                  <option key={rx.id} value={rx.id}>{rx.medication_name} — {rx.dosage} ({rx.frequency})</option>
                ))}
              </select>
              {errors.prescription_id && <p className="form-error">{errors.prescription_id}</p>}
            </div>

            <div>
              <label className="form-label">Waktu Pengingat ({form.scheduled_times.length}x sehari) <span className="text-red-500">*</span></label>
              <div className="flex flex-wrap gap-3 mt-1">
                {form.scheduled_times.map((time, idx) => (
                  <div key={idx} className="flex flex-col">
                    <span className="text-xs text-slate-500 mb-1">Waktu {idx + 1}</span>
                    <input type="time" className={`form-input w-32 ${errors.scheduled_times ? 'form-input-error' : ''}`}
                      value={time} 
                      onChange={e => {
                        const newTimes = [...form.scheduled_times]
                        newTimes[idx] = e.target.value
                        setForm(p => ({ ...p, scheduled_times: newTimes }))
                      }} />
                  </div>
                ))}
              </div>
              {errors.scheduled_times && <p className="form-error">{errors.scheduled_times}</p>}
            </div>

            <div>
              <label className="form-label">Hari <span className="text-red-500">*</span></label>
              <div className="flex flex-wrap gap-2 mt-1">
                {DAYS.map(day => (
                  <button type="button" key={day}
                    onClick={() => toggleDay(day)}
                    className={`px-3 py-1.5 rounded-lg text-xs font-semibold border transition-colors ${
                      form.days_of_week.includes(day)
                        ? 'bg-primary-500 text-white border-primary-500'
                        : 'bg-white text-slate-500 border-slate-200 hover:border-primary-300'
                    }`}>
                    {DAY_LABELS[day]}
                  </button>
                ))}
              </div>
              {errors.days_of_week && <p className="form-error">{errors.days_of_week}</p>}
            </div>

            <div>
              <label className="form-label">Catatan</label>
              <input className="form-input" placeholder="Catatan tambahan..."
                value={form.notes} onChange={e => setForm(p => ({ ...p, notes: e.target.value }))} />
            </div>

            <div className="flex gap-3">
              <button type="button" onClick={() => setShowForm(false)} className="btn-secondary">Batal</button>
              <button type="submit" className="btn-primary" disabled={formLoading}>
                {formLoading && <span className="spinner w-4 h-4" />}
                {formLoading ? 'Menyimpan...' : 'Simpan Reminder'}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Reminders List */}
      {!selectedPatient ? (
        <div className="card p-10 text-center text-slate-400">
          <Bell size={40} className="mx-auto mb-3 opacity-30" />
          <p>Pilih pasien untuk melihat reminder</p>
        </div>
      ) : loading ? (
        <div className="flex justify-center py-10"><div className="spinner w-8 h-8" /></div>
      ) : reminders.length === 0 ? (
        <div className="card p-10 text-center text-slate-400">
          <Bell size={40} className="mx-auto mb-3 opacity-30" />
          <p>Belum ada reminder untuk pasien ini</p>
        </div>
      ) : (
        <div className="space-y-3">
          {reminders.map(r => (
            <ReminderItem key={r.id} reminder={r} onDelete={handleDelete} onToggle={handleToggle} />
          ))}
        </div>
      )}
    </div>
  )
}

export default RemindersPage
