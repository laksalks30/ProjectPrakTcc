// ============ FILE: frontend/src/components/LogTable.jsx ============
import React from 'react'
import { format } from 'date-fns'
import { id } from 'date-fns/locale'
import { CheckCircle, XCircle, MinusCircle, Clock } from 'lucide-react'

const statusConfig = {
  taken: { label: 'Diminum', icon: CheckCircle, className: 'status-taken', iconColor: 'text-green-500' },
  missed: { label: 'Terlewat', icon: XCircle, className: 'status-missed', iconColor: 'text-red-500' },
  skipped: { label: 'Dilewati', icon: MinusCircle, className: 'status-skipped', iconColor: 'text-yellow-500' },
  late: { label: 'Terlambat', icon: Clock, className: 'status-late', iconColor: 'text-orange-500' },
}

const LogTable = ({ logs, loading }) => {
  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="spinner w-8 h-8" />
      </div>
    )
  }

  if (!logs || logs.length === 0) {
    return (
      <div className="text-center py-12 text-slate-400">
        <Clock size={40} className="mx-auto mb-3 opacity-30" />
        <p className="text-sm">Belum ada riwayat log</p>
      </div>
    )
  }

  const formatDatetime = (dt) => {
    if (!dt) return '-'
    try {
      return format(new Date(dt), 'dd MMM yyyy HH:mm', { locale: id })
    } catch {
      return dt
    }
  }

  return (
    <div className="table-container">
      <table className="table">
        <thead>
          <tr>
            <th>Pasien</th>
            <th>Obat</th>
            <th>Jadwal</th>
            <th>Diminum</th>
            <th>Status</th>
            <th>Catatan</th>
          </tr>
        </thead>
        <tbody>
          {logs.map((log) => {
            const st = statusConfig[log.status] || statusConfig.missed
            const Icon = st.icon
            return (
              <tr key={log.id}>
                <td>
                  <span className="font-medium text-slate-700">{log.patient_name || `ID: ${log.patient_id}`}</span>
                </td>
                <td>
                  <span className="text-slate-600">{log.medication_name || `Resep #${log.prescription_id}`}</span>
                </td>
                <td>
                  <span className="text-slate-600 text-xs">{formatDatetime(log.scheduled_at)}</span>
                </td>
                <td>
                  <span className="text-slate-600 text-xs">{formatDatetime(log.taken_at)}</span>
                </td>
                <td>
                  <span className={`badge ${st.className} flex items-center gap-1 w-fit`}>
                    <Icon size={11} />
                    {st.label}
                  </span>
                </td>
                <td>
                  <span className="text-slate-500 text-xs">{log.notes || '-'}</span>
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}

export default LogTable
