import React, { useState, useEffect, useRef } from 'react'
import { X, Clock, User, Pill, BellRing, AlarmClock } from 'lucide-react'

const AlarmModal = ({ reminder, onDismiss, onSnooze, onTaken }) => {
  const [pulse, setPulse] = useState(true)
  const intervalRef = useRef(null)

  useEffect(() => {
    intervalRef.current = setInterval(() => {
      setPulse(p => !p)
    }, 600)
    return () => clearInterval(intervalRef.current)
  }, [])

  if (!reminder) return null

  const formatTime = (time) => {
    if (!time) return '--:--'
    return time.length >= 5 ? time.substring(0, 5) : time
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm animate-fade-in">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md mx-4 overflow-hidden">
        {/* Header with gradient */}
        <div className="bg-gradient-to-r from-teal-500 to-cyan-500 p-6 text-center relative">
          <button
            onClick={onDismiss}
            className="absolute top-3 right-3 text-white/70 hover:text-white transition-colors"
          >
            <X size={20} />
          </button>

          <div className={`inline-flex items-center justify-center w-20 h-20 rounded-full bg-white/20 mb-4 transition-transform duration-500 ${pulse ? 'scale-110' : 'scale-100'}`}>
            <BellRing size={40} className="text-white" />
          </div>

          <h2 className="text-2xl font-bold text-white mb-1">
            Waktunya Minum Obat!
          </h2>
          <p className="text-4xl font-light text-white/90 font-mono">
            {formatTime(reminder.scheduled_time)}
          </p>
        </div>

        {/* Content */}
        <div className="p-6 space-y-4">
          <div className="flex items-center gap-3 p-3 bg-slate-50 rounded-xl">
            <div className="w-10 h-10 rounded-lg bg-teal-100 flex items-center justify-center flex-shrink-0">
              <User size={20} className="text-teal-600" />
            </div>
            <div>
              <p className="text-xs text-slate-400">Pasien</p>
              <p className="font-semibold text-slate-700">
                {reminder.patient_name || 'Pasien'}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3 p-3 bg-slate-50 rounded-xl">
            <div className="w-10 h-10 rounded-lg bg-indigo-100 flex items-center justify-center flex-shrink-0">
              <Pill size={20} className="text-indigo-600" />
            </div>
            <div>
              <p className="text-xs text-slate-400">Obat</p>
              <p className="font-semibold text-slate-700">
                {reminder.medication_name || 'Obat'}
              </p>
              {reminder.notes && (
                <p className="text-xs text-slate-400 mt-0.5">{reminder.notes}</p>
              )}
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="p-6 pt-0 space-y-3">
          <button
            onClick={() => onTaken && onTaken(reminder)}
            className="w-full py-3 bg-teal-500 hover:bg-teal-600 text-white font-semibold rounded-xl transition-colors flex items-center justify-center gap-2"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
            Sudah Diminum
          </button>

          <div className="flex gap-3">
            <button
              onClick={() => onSnooze && onSnooze(reminder)}
              className="flex-1 py-2.5 border border-slate-200 text-slate-600 hover:bg-slate-50 font-medium rounded-xl transition-colors flex items-center justify-center gap-2 text-sm"
            >
              <AlarmClock size={16} />
              Tunda 5 Menit
            </button>
            <button
              onClick={onDismiss}
              className="flex-1 py-2.5 border border-slate-200 text-slate-400 hover:bg-slate-50 font-medium rounded-xl transition-colors text-sm"
            >
              Tutup
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default AlarmModal
