// ============ FILE: frontend/src/pages/LogsPage.jsx ============
import React, { useEffect, useState } from 'react'
import { patientService, logService, prescriptionService, reminderService } from '../services/api'
import LogTable from '../components/LogTable'
import { ClipboardList, CheckCircle, XCircle, ChevronRight, RotateCcw, Clock, AlertCircle, Info } from 'lucide-react'
import toast from 'react-hot-toast'

// Nama hari sesuai format backend (lowercase english) → index getDay()
const DAY_KEYS = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']

// ─── Helpers ─────────────────────────────────────────────────────────────────
// Konversi waktu lokal ke ISO string (tanpa offset UTC)
const toLocalISO = (date) => {
  const d = new Date(date)
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16)
}

const parseTimeToMinutes = (timeStr) => {
  if (!timeStr) return 0
  const [hh, mm] = timeStr.split(':').map(Number)
  return hh * 60 + (mm || 0)
}

const minutesToTimeStr = (minutes) => {
  const hh = Math.floor(minutes / 60) % 24
  const mm = minutes % 60
  return `${String(hh).padStart(2, '0')}:${String(mm).padStart(2, '0')}`
}

// ─────────────────────────────────────────────────────────────────────────────
const LogsPage = () => {
  const [patients, setPatients]             = useState([])
  const [prescriptions, setPrescriptions]   = useState([])
  const [todayReminders, setTodayReminders] = useState([])  // reminder hari ini untuk resep terpilih
  const [logs, setLogs]                     = useState([])
  const [loadingLogs, setLoadingLogs]       = useState(false)
  const [confirming, setConfirming]         = useState(false)
  const [currentTime, setCurrentTime]       = useState(new Date())
  const [step, setStep]                     = useState(1)
  const [selectedPatient, setSelectedPatient]         = useState(null)
  const [selectedPrescription, setSelectedPrescription] = useState(null)

  // ── Jam realtime ──────────────────────────────────────────────────────────
  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000)
    return () => clearInterval(timer)
  }, [])

  // ── Load semua pasien ─────────────────────────────────────────────────────
  useEffect(() => {
    patientService.getAll({ limit: 100 })
      .then(r => setPatients(r.data.data.patients || []))
      .catch(() => {})
  }, [])

  // ── Hitung menit sekarang (dari waktu lokal) ──────────────────────────────
  const nowMins = currentTime.getHours() * 60 + currentTime.getMinutes()

  // ── Cari reminder yang aktif: hanya jika waktu asli sudah tiba (nowMins >= scheduledMins) ──
  // Diperhitungkan ulang tiap detik lewat currentTime
  // Menggunakan 'find' agar reminder yang terlewat (belum dilog) muncul lebih dulu
  const activeReminder = todayReminders.find(r => {
    if (r.already_logged) return false
    return nowMins >= parseTimeToMinutes(r.scheduled_time)
  })

  // Reminder berikutnya yang belum waktunya (strictly belum tiba)
  const nextUpcoming = todayReminders.find(r => !r.already_logged && parseTimeToMinutes(r.scheduled_time) > nowMins)

  const canConfirm = activeReminder != null

  // ── Step 1: Pilih Pasien ──────────────────────────────────────────────────
  const handleSelectPatient = (patient) => {
    setSelectedPatient(patient)
    setSelectedPrescription(null)
    setTodayReminders([])
    setPrescriptions([])
    prescriptionService.getByPatient(patient.id)
      .then(r => setPrescriptions(r.data.data.prescriptions || []))
      .catch(() => toast.error('Gagal memuat data obat'))
    fetchLogs(patient.id)
    setStep(2)
  }

  // ── Step 2: Pilih Obat ────────────────────────────────────────────────────
  const handleSelectPrescription = async (prescription) => {
    setSelectedPrescription(prescription)
    setTodayReminders([])
    try {
      const res = await reminderService.getByPatient(selectedPatient.id)
      const allReminders = res.data.data.reminders || []
      const todayKey = DAY_KEYS[new Date().getDay()]

      // Filter: hanya reminder untuk resep ini & berlaku hari ini
      const filtered = allReminders.filter(r => {
        if (String(r.prescription_id) !== String(prescription.id)) return false
        const days = Array.isArray(r.days_of_week)
          ? r.days_of_week.map(d => d.toLowerCase())
          : (r.days_of_week || '').split(',').map(d => d.trim().toLowerCase())
        return days.includes(todayKey) || days.includes('everyday') || days.length === 0
      })

      const todayDate = toLocalISO(new Date()).split('T')[0]
      const withStatus = filtered.map(r => {
        const timeStr = r.scheduled_time.slice(0, 5)
        const alreadyLogged = logs.some(log => {
          if (String(log.prescription_id) !== String(prescription.id)) return false
          if (!log.scheduled_at) return false
          const logDate = log.scheduled_at.split('T')[0]
          const logTime = log.scheduled_at.split('T')[1].slice(0, 5)
          return logDate === todayDate && logTime === timeStr
        })
        return { ...r, already_logged: alreadyLogged }
      })

      // Urutkan berdasarkan waktu
      withStatus.sort((a, b) => parseTimeToMinutes(a.scheduled_time) - parseTimeToMinutes(b.scheduled_time))
      setTodayReminders(withStatus)
    } catch {
      toast.error('Gagal memuat jadwal reminder')
    }
    setStep(3)
  }

  // ── Fetch log history ─────────────────────────────────────────────────────
  const fetchLogs = async (patientId) => {
    setLoadingLogs(true)
    try {
      const res = await logService.getByPatient(patientId)
      setLogs(res.data.data.logs || [])
    } catch {} finally { setLoadingLogs(false) }
  }

  // ── Step 3: Konfirmasi ────────────────────────────────────────────────────
  const handleConfirm = async (status) => {
    setConfirming(true)
    try {
      const now        = new Date()
      const takenAt    = toLocalISO(now)                                  // Waktu lokal saat ini
      const todayDate  = toLocalISO(now).split('T')[0]                    // YYYY-MM-DD lokal
      const scheduledAt = activeReminder
        ? `${todayDate}T${activeReminder.scheduled_time.slice(0, 5)}`
        : takenAt

      // Catat log
      await logService.create({
        patient_id:      selectedPatient.id,
        prescription_id: selectedPrescription.id,
        scheduled_at:    scheduledAt,
        taken_at:        status === 'taken' ? takenAt : null,
        status,
        notes: ''
      })

      // ── Jika terlambat minum, geser jadwal reminder berikutnya ──────────
      if (status === 'taken' && activeReminder) {
        const scheduledMins = parseTimeToMinutes(activeReminder.scheduled_time)
        const takenMins     = now.getHours() * 60 + now.getMinutes()
        const delayMins     = takenMins - scheduledMins

        if (delayMins > 15) {
          // Cari reminder berikutnya (scheduled_time lebih besar dari yang aktif)
          const nextReminder = todayReminders.find(r =>
            parseTimeToMinutes(r.scheduled_time) > parseTimeToMinutes(activeReminder.scheduled_time)
          )
          if (nextReminder) {
            const origMins   = parseTimeToMinutes(nextReminder.scheduled_time)
            const newTimeMins = origMins + delayMins
            const newTimeStr  = minutesToTimeStr(newTimeMins)

            // Update ke backend
            await reminderService.update(nextReminder.id, {
              ...nextReminder,
              scheduled_time: newTimeStr
            })

            toast(`⏰ Terlambat ${delayMins} menit — jadwal berikutnya digeser ke ${newTimeStr}`, {
              duration: 6000,
              icon: '🔔'
            })
          }
        }
      }

      const msg = status === 'taken'
        ? `✅ ${selectedPrescription.medication_name} dicatat sudah diminum!`
        : `❌ ${selectedPrescription.medication_name} dicatat belum diminum.`
      toast.success(msg)

      await fetchLogs(selectedPatient.id)
      setSelectedPrescription(null)
      setTodayReminders([])
      setStep(2)
    } catch (e) {
      toast.error(e.response?.data?.message || 'Gagal mencatat log')
    } finally { setConfirming(false) }
  }

  const handleReset = () => {
    setStep(1); setSelectedPatient(null); setSelectedPrescription(null)
    setPrescriptions([]); setTodayReminders([]); setLogs([])
  }

  // ─────────────────────────────────────────────────────────────────────────
  return (
    <div className="space-y-6 animate-fade-in">

      {/* ── Header ─────────────────────────────────────────────────────── */}
      <div className="page-header">
        <div>
          <h1 className="page-title">Riwayat Log</h1>
          <p className="page-subtitle">Catat dan pantau minum obat pasien lansia</p>
        </div>
        <div className="flex items-center gap-3">
          {/* Jam realtime */}
          <div className="flex items-center gap-2 bg-slate-800 text-white px-4 py-2 rounded-xl font-mono text-lg font-bold shadow">
            <Clock size={18} className="text-blue-300" />
            {currentTime.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
            <span className="text-xs font-normal text-slate-400 ml-1">WIB</span>
          </div>
          {step > 1 && (
            <button onClick={handleReset} className="btn-secondary flex items-center gap-2">
              <RotateCcw size={15} /> Mulai Ulang
            </button>
          )}
        </div>
      </div>

      {/* ── Breadcrumb ──────────────────────────────────────────────────── */}
      <div className="flex items-center gap-2 text-sm">
        {[
          { n: 1, label: 'Pilih Lansia' },
          { n: 2, label: 'Pilih Obat' },
          { n: 3, label: 'Konfirmasi' }
        ].map(({ n, label }, i, arr) => (
          <React.Fragment key={n}>
            <span className={`px-3 py-1 rounded-full font-medium transition-colors ${
              step >= n ? 'bg-blue-100 text-blue-700' : 'bg-slate-100 text-slate-400'
            }`}>
              {n}. {label}
            </span>
            {i < arr.length - 1 && <ChevronRight size={14} className="text-slate-300" />}
          </React.Fragment>
        ))}
      </div>

      {/* ── STEP 1: Pilih Pasien ────────────────────────────────────────── */}
      {step === 1 && (
        <div className="card">
          <div className="card-header">
            <h3 className="font-semibold text-slate-700">Pilih Pasien Lansia</h3>
          </div>
          <div className="p-4 grid grid-cols-1 gap-2 max-h-80 overflow-y-auto">
            {patients.length === 0 && <p className="text-center text-slate-400 py-8">Belum ada data pasien</p>}
            {patients.map(p => (
              <button key={p.id} onClick={() => handleSelectPatient(p)}
                className="w-full text-left px-4 py-3 rounded-lg border border-slate-200 hover:border-blue-400 hover:bg-blue-50 transition-all flex items-center justify-between group">
                <div>
                  <p className="font-medium text-slate-700">{p.name}</p>
                  <p className="text-xs text-slate-400">
                    {p.age ? `${p.age} tahun` : ''} {p.room_number ? `· Kamar ${p.room_number}` : ''}
                  </p>
                </div>
                <ChevronRight size={16} className="text-slate-300 group-hover:text-blue-400 transition-colors" />
              </button>
            ))}
          </div>
        </div>
      )}

      {/* ── STEP 2: Pilih Obat ──────────────────────────────────────────── */}
      {step === 2 && selectedPatient && (
        <div className="card">
          <div className="card-header">
            <div>
              <h3 className="font-semibold text-slate-700">
                Pilih Obat untuk <span className="text-blue-600">{selectedPatient.name}</span>
              </h3>
              <p className="text-xs text-slate-400 mt-0.5">Pilih obat yang ingin dicatat status minumnya</p>
            </div>
          </div>
          <div className="p-4 grid grid-cols-1 gap-2 max-h-80 overflow-y-auto">
            {prescriptions.length === 0 && (
              <div className="text-center text-slate-400 py-8">
                <p>Belum ada resep aktif untuk pasien ini</p>
                <p className="text-xs mt-1">Tambahkan resep terlebih dahulu di halaman Resep</p>
              </div>
            )}
            {prescriptions.map(rx => (
              <button key={rx.id} onClick={() => handleSelectPrescription(rx)}
                className="w-full text-left px-4 py-3 rounded-lg border border-slate-200 hover:border-blue-400 hover:bg-blue-50 transition-all flex items-center justify-between group">
                <div>
                  <p className="font-medium text-slate-700">{rx.medication_name}</p>
                  <p className="text-xs text-slate-400">{rx.dosage} · {rx.frequency}</p>
                </div>
                <ChevronRight size={16} className="text-slate-300 group-hover:text-blue-400 transition-colors" />
              </button>
            ))}
          </div>
        </div>
      )}

      {/* ── STEP 3: Konfirmasi ──────────────────────────────────────────── */}
      {step === 3 && selectedPatient && selectedPrescription && (
        <div className="card">
          <div className="card-body space-y-5 py-6">

            {/* Info pasien & obat */}
            <div className="text-center space-y-3">
              <div>
                <p className="text-slate-500 text-sm">Konfirmasi minum obat untuk</p>
                <p className="text-xl font-bold text-slate-800 mt-0.5">{selectedPatient.name}</p>
              </div>
              <div className="bg-slate-50 rounded-xl px-6 py-4 inline-block">
                <p className="text-2xl font-bold text-blue-700">{selectedPrescription.medication_name}</p>
                <p className="text-sm text-slate-500 mt-1">{selectedPrescription.dosage} · {selectedPrescription.frequency}</p>
              </div>
            </div>

            {/* Jadwal hari ini */}
            {todayReminders.length > 0 ? (
              <div>
                <p className="text-sm font-medium text-slate-600 mb-2">📅 Jadwal minum hari ini:</p>
                <div className="flex flex-wrap gap-2">
                  {todayReminders.map(r => {
                    const rMins    = parseTimeToMinutes(r.scheduled_time)
                    const isDue    = nowMins >= rMins
                    const isActive = activeReminder?.id === r.id
                    
                    if (r.already_logged) {
                      return (
                        <span key={r.id} className="px-3 py-1.5 rounded-lg text-sm font-mono font-semibold border-2 bg-green-50 border-green-200 text-green-600">
                          {r.scheduled_time?.slice(0, 5) || '-'}
                          <span className="ml-1 text-xs font-sans">(Selesai)</span>
                        </span>
                      )
                    }

                    return (
                      <span key={r.id} className={`px-3 py-1.5 rounded-lg text-sm font-mono font-semibold border-2 ${
                        isActive
                          ? 'bg-green-100 border-green-400 text-green-700'
                          : isDue
                          ? 'bg-slate-100 border-slate-200 text-slate-400 line-through'
                          : 'bg-blue-50 border-blue-200 text-blue-600'
                      }`}>
                        {r.scheduled_time?.slice(0, 5) || '-'}
                        {isActive && <span className="ml-1 text-xs font-sans">← Sekarang</span>}
                        {!isDue && !isActive && <span className="ml-1 text-xs font-sans">(belum)</span>}
                      </span>
                    )
                  })}
                </div>
              </div>
            ) : (
              <div className="flex items-center gap-2 text-slate-400 text-sm bg-slate-50 rounded-lg px-4 py-3">
                <Info size={16} />
                <span>Tidak ada jadwal reminder untuk obat ini hari ini.</span>
              </div>
            )}

            {/* Jam lokal sekarang */}
            <div className="flex items-center justify-center gap-2 bg-slate-800 text-white rounded-xl py-3">
              <Clock size={18} className="text-blue-300" />
              <span className="font-mono text-2xl font-bold">
                {currentTime.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
              </span>
              <span className="text-xs text-slate-400 ml-1">WIB</span>
            </div>

            {/* ── Belum waktunya / Selesai ─────────────────────────────────────────── */}
            {todayReminders.length > 0 && !canConfirm && (
              <div className={`border-2 rounded-xl p-5 text-center ${todayReminders.every(r => r.already_logged) ? 'bg-green-50 border-green-200' : 'bg-amber-50 border-amber-200'}`}>
                {todayReminders.every(r => r.already_logged) ? (
                  <>
                    <CheckCircle size={28} className="mx-auto text-green-500 mb-2" />
                    <p className="text-green-700 font-bold text-lg">Semua Selesai</p>
                    <p className="text-green-600 text-sm mt-1">Seluruh jadwal minum obat ini untuk hari ini sudah dicatat.</p>
                  </>
                ) : (
                  <>
                    <AlertCircle size={28} className="mx-auto text-amber-500 mb-2" />
                    <p className="text-amber-700 font-bold text-lg">Belum Waktunya</p>
                    {nextUpcoming ? (
                      <>
                        <p className="text-amber-600 text-sm mt-1">
                          Silakan tunggu hingga pukul{' '}
                          <span className="font-mono font-bold text-base">{nextUpcoming.scheduled_time?.slice(0, 5)}</span>
                        </p>
                        <p className="text-amber-500 text-xs mt-2">
                          Tombol konfirmasi akan aktif tepat saat jadwal tiba
                        </p>
                      </>
                    ) : (
                      <p className="text-amber-600 text-sm mt-1">Tidak ada jadwal minum lagi hari ini yang belum diselesaikan.</p>
                    )}
                  </>
                )}
              </div>
            )}

            {/* ── Waktunya konfirmasi ─────────────────────────────────────── */}
            {(canConfirm || todayReminders.length === 0) && (
              <div className="space-y-3">
                <p className="text-center text-slate-600 font-medium">Apakah obat sudah diminum?</p>
                <div className="flex gap-4 justify-center flex-wrap">
                  <button
                    onClick={() => handleConfirm('missed')}
                    disabled={confirming}
                    className="flex items-center gap-2 px-8 py-3 rounded-xl border-2 border-red-200 text-red-600 font-semibold hover:bg-red-50 hover:border-red-400 transition-all disabled:opacity-50"
                  >
                    <XCircle size={20} /> Belum Diminum
                  </button>
                  <button
                    onClick={() => handleConfirm('taken')}
                    disabled={confirming}
                    className="flex items-center gap-2 px-8 py-3 rounded-xl bg-green-500 text-white font-semibold hover:bg-green-600 transition-all shadow-md disabled:opacity-50"
                  >
                    <CheckCircle size={20} />
                    {confirming ? 'Menyimpan...' : 'Sudah Diminum ✓'}
                  </button>
                </div>
              </div>
            )}

            <div className="text-center">
              <button onClick={() => { setStep(2); setSelectedPrescription(null); setTodayReminders([]) }}
                className="text-sm text-slate-400 hover:text-slate-600 underline">
                ← Ganti obat
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Riwayat Log ────────────────────────────────────────────────── */}
      {selectedPatient && (
        <div className="card">
          <div className="card-header">
            <h3 className="font-semibold text-slate-700">
              Riwayat Minum Obat — {selectedPatient.name}
            </h3>
            <span className="badge-gray badge">{logs.length} entri</span>
          </div>
          <div className="p-0">
            <LogTable logs={logs} loading={loadingLogs} />
          </div>
        </div>
      )}

      {/* ── Empty state ─────────────────────────────────────────────────── */}
      {!selectedPatient && step === 1 && (
        <div className="card p-10 text-center text-slate-400">
          <ClipboardList size={40} className="mx-auto mb-3 opacity-30" />
          <p>Pilih pasien di atas untuk mulai mencatat</p>
        </div>
      )}
    </div>
  )
}

export default LogsPage
