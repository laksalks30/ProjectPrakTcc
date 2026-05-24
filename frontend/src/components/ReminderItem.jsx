// ============ FILE: frontend/src/components/ReminderItem.jsx ============
import React from 'react'
import { Clock, User, Pill, Trash2, ToggleLeft, ToggleRight } from 'lucide-react'

const ReminderItem = ({ reminder, onDelete, onToggle }) => {
  const daysMap = {
    monday: 'Sen', tuesday: 'Sel', wednesday: 'Rab', thursday: 'Kam',
    friday: 'Jum', saturday: 'Sab', sunday: 'Min'
  }
  const allDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
  const days = reminder.days_of_week || allDays
  const isAllDays = days.length === 7

  const formatTime = (time) => {
    if (!time) return '-'
    const [h, m] = time.split(':')
    const hour = parseInt(h)
    const ampm = hour >= 12 ? 'PM' : 'AM'
    const displayHour = hour > 12 ? hour - 12 : hour || 12
    return `${displayHour.toString().padStart(2, '0')}:${m} ${ampm}`
  }

  return (
    <div className={`card border ${reminder.is_active ? 'border-primary-100' : 'border-slate-200 opacity-60'} p-4`}>
      <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-3 flex-1 min-w-0">
          <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${
            reminder.is_active ? 'bg-primary-100 text-primary-600' : 'bg-slate-100 text-slate-400'
          }`}>
            <Clock size={18} />
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <span className="font-bold text-lg text-slate-800">{formatTime(reminder.scheduled_time)}</span>
              {reminder.is_active ? (
                <span className="badge-green badge">Aktif</span>
              ) : (
                <span className="badge-gray badge">Nonaktif</span>
              )}
            </div>
            <div className="flex items-center gap-3 mt-1">
              {reminder.patient_name && (
                <span className="flex items-center gap-1 text-xs text-slate-500">
                  <User size={11} />
                  {reminder.patient_name}
                </span>
              )}
              {reminder.medication_name && (
                <span className="flex items-center gap-1 text-xs text-slate-500">
                  <Pill size={11} />
                  {reminder.medication_name}
                </span>
              )}
            </div>
            <div className="flex gap-1 mt-2 flex-wrap">
              {isAllDays ? (
                <span className="text-xs text-primary-600 font-medium">Setiap hari</span>
              ) : (
                allDays.map(day => (
                  <span key={day} className={`text-xs px-1.5 py-0.5 rounded font-medium ${
                    days.includes(day) ? 'bg-primary-100 text-primary-700' : 'bg-slate-100 text-slate-400'
                  }`}>
                    {daysMap[day]}
                  </span>
                ))
              )}
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2 flex-shrink-0">
          {onToggle && (
            <button
              onClick={() => onToggle(reminder.id, !reminder.is_active)}
              className="text-slate-400 hover:text-primary-600 transition-colors"
              title={reminder.is_active ? 'Nonaktifkan' : 'Aktifkan'}
            >
              {reminder.is_active ? <ToggleRight size={24} className="text-primary-500" /> : <ToggleLeft size={24} />}
            </button>
          )}
          {onDelete && (
            <button
              onClick={() => onDelete(reminder.id)}
              className="text-slate-300 hover:text-red-500 transition-colors"
            >
              <Trash2 size={16} />
            </button>
          )}
        </div>
      </div>
      {reminder.notes && (
        <p className="text-xs text-slate-400 mt-2 pl-13">{reminder.notes}</p>
      )}
    </div>
  )
}

export default ReminderItem
