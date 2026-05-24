// ============ FILE: frontend/src/pages/PatientDetailPage.jsx ============
import React, { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { patientService, prescriptionService, logService } from '../services/api'
import LogTable from '../components/LogTable'
import { ArrowLeft, User, MapPin, Droplets, Calendar, FileText, ClipboardList, Plus } from 'lucide-react'
import toast from 'react-hot-toast'
import { format } from 'date-fns'
import { id } from 'date-fns/locale'
import { useAuth } from '../context/AuthContext'

const PatientDetailPage = () => {
  const { id: patientId } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const [patient, setPatient] = useState(null)
  const [prescriptions, setPrescriptions] = useState([])
  const [logs, setLogs] = useState([])
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState('prescriptions')
  const [logsLoading, setLogsLoading] = useState(false)

  useEffect(() => {
    fetchPatient()
    fetchPrescriptions()
  }, [patientId])

  useEffect(() => {
    if (activeTab === 'logs') fetchLogs()
  }, [activeTab, patientId])

  const fetchPatient = async () => {
    try {
      const res = await patientService.getById(patientId)
      setPatient(res.data.data.patient)
    } catch {
      toast.error('Gagal memuat data lansia')
      navigate('/patients')
    } finally {
      setLoading(false)
    }
  }

  const fetchPrescriptions = async () => {
    try {
      const res = await prescriptionService.getByPatient(patientId)
      setPrescriptions(res.data.data.prescriptions || [])
    } catch {}
  }

  const fetchLogs = async () => {
    setLogsLoading(true)
    try {
      const res = await logService.getByPatient(patientId)
      setLogs(res.data.data.logs || [])
    } catch {} finally {
      setLogsLoading(false)
    }
  }

  const statusConfig = {
    active: { label: 'Aktif', cls: 'badge-green' },
    completed: { label: 'Selesai', cls: 'badge-blue' },
    stopped: { label: 'Dihentikan', cls: 'badge-gray' },
  }

  if (loading) return (
    <div className="flex items-center justify-center h-64">
      <div className="spinner w-8 h-8" />
    </div>
  )

  if (!patient) return null

  const age = patient.birth_date
    ? new Date().getFullYear() - new Date(patient.birth_date).getFullYear()
    : '-'

  return (
    <div className="space-y-5 animate-fade-in max-w-4xl mx-auto">
      <div className="flex items-center gap-3">
        <button onClick={() => navigate('/patients')} className="btn-ghost btn-sm p-2"><ArrowLeft size={18} /></button>
        <h1 className="page-title">Detail Lansia</h1>
      </div>

      {/* Patient Header */}
      <div className="card p-6">
        <div className="flex items-start gap-5">
          <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-primary-400 to-secondary-500 flex items-center justify-center flex-shrink-0 overflow-hidden">
            {patient.photo_url
              ? <img src={patient.photo_url} alt={patient.name} className="w-full h-full object-cover" />
              : <User size={32} className="text-white" />}
          </div>
          <div className="flex-1">
            <h2 className="text-xl font-bold text-slate-800">{patient.name}</h2>
            <div className="flex flex-wrap gap-x-4 gap-y-1.5 mt-2">
              <span className="flex items-center gap-1.5 text-sm text-slate-500">
                <Calendar size={14} className="text-primary-400" />
                {age} tahun ({patient.birth_date ? format(new Date(patient.birth_date), 'dd MMMM yyyy', { locale: id }) : '-'})
              </span>
              <span className="flex items-center gap-1.5 text-sm text-slate-500">
                <User size={14} className="text-primary-400" />
                {patient.gender === 'male' ? 'Laki-laki' : 'Perempuan'}
              </span>
              {patient.blood_type && (
                <span className="flex items-center gap-1.5 text-sm text-slate-500">
                  <Droplets size={14} className="text-red-400" />
                  Gol. {patient.blood_type}
                </span>
              )}
              {patient.address && (
                <span className="flex items-center gap-1.5 text-sm text-slate-500">
                  <MapPin size={14} className="text-slate-400" />
                  {patient.address}
                </span>
              )}
            </div>
            {patient.medical_notes && (
              <div className="mt-3 p-3 bg-amber-50 rounded-lg border border-amber-100">
                <p className="text-xs text-amber-800 font-medium mb-1">Catatan Medis:</p>
                <p className="text-sm text-amber-700">{patient.medical_notes}</p>
              </div>
            )}
          </div>
          {user?.role === 'admin' && (
            <button
              onClick={() => navigate(`/prescriptions/add?patientId=${patient.id}`)}
              className="btn-primary btn-sm flex-shrink-0">
              <Plus size={14} /> Tambah Resep
            </button>
          )}
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-200">
        {[
          { key: 'prescriptions', label: 'Resep Aktif', icon: FileText, count: prescriptions.filter(p => p.status === 'active').length },
          { key: 'all_prescriptions', label: 'Semua Resep', icon: FileText, count: prescriptions.length },
          { key: 'logs', label: 'Riwayat Log', icon: ClipboardList },
        ].map(tab => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === tab.key
                ? 'border-primary-500 text-primary-600'
                : 'border-transparent text-slate-500 hover:text-slate-700'
            }`}
          >
            <tab.icon size={15} />
            {tab.label}
            {tab.count !== undefined && (
              <span className={`text-xs px-1.5 py-0.5 rounded-full ${activeTab === tab.key ? 'bg-primary-100 text-primary-700' : 'bg-slate-100 text-slate-500'}`}>
                {tab.count}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {(activeTab === 'prescriptions' || activeTab === 'all_prescriptions') && (
        <div className="space-y-3">
          {(activeTab === 'prescriptions'
            ? prescriptions.filter(p => p.status === 'active')
            : prescriptions
          ).length === 0 ? (
            <div className="card p-10 text-center text-slate-400">
              <FileText size={36} className="mx-auto mb-3 opacity-30" />
              <p>Belum ada resep {activeTab === 'prescriptions' ? 'aktif' : ''}</p>
            </div>
          ) : (
            (activeTab === 'prescriptions' ? prescriptions.filter(p => p.status === 'active') : prescriptions).map(rx => {
              const sc = statusConfig[rx.status] || statusConfig.active
              return (
                <div key={rx.id} className="card p-4">
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="font-semibold text-slate-800">{rx.medication_name || `Obat #${rx.medication_id}`}</span>
                        <span className={`badge ${sc.cls}`}>{sc.label}</span>
                      </div>
                      <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-sm text-slate-500">
                        <span>Dosis: <strong className="text-slate-700">{rx.dosage}</strong></span>
                        <span>Frekuensi: <strong className="text-slate-700">{rx.frequency}</strong></span>
                        <span>Mulai: <strong className="text-slate-700">{rx.start_date}</strong></span>
                        <span>Selesai: <strong className="text-slate-700">{rx.end_date || 'Tidak ditentukan'}</strong></span>
                        {rx.doctor_name && <span>Dokter: <strong className="text-slate-700">{rx.doctor_name}</strong></span>}
                      </div>
                      {rx.notes && <p className="text-xs text-slate-400 mt-2">{rx.notes}</p>}
                    </div>
                  </div>
                </div>
              )
            })
          )}
        </div>
      )}

      {activeTab === 'logs' && (
        <LogTable logs={logs} loading={logsLoading} />
      )}
    </div>
  )
}

export default PatientDetailPage
