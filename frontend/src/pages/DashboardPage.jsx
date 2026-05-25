// ============ FILE: frontend/src/pages/DashboardPage.jsx ============
import React, { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { dashboardService } from '../services/api'
import StatsCard from '../components/StatsCard'
import { Users, Pill, Bell, TrendingUp, CheckCircle, XCircle, Clock, MinusCircle } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line } from 'recharts'

const DashboardPage = () => {
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)
  const navigate = useNavigate()

  useEffect(() => {
    fetchStats()
  }, [])

  const fetchStats = async () => {
    setLoading(true)
    try {
      const res = await dashboardService.getStats()
      setStats(res.data.data)
    } catch (e) {
      console.error('Failed to load dashboard stats:', e)
    } finally {
      setLoading(false)
    }
  }

  const statusLabel = { taken: 'Diminum', missed: 'Terlewat', skipped: 'Dilewati', late: 'Terlambat' }
  const statusColor = { taken: '#14b8a6', missed: '#ef4444', skipped: '#f59e0b', late: '#f97316' }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="flex flex-col items-center gap-3">
          <div className="spinner w-8 h-8" />
          <p className="text-slate-400 text-sm">Memuat dashboard...</p>
        </div>
      </div>
    )
  }

  const overview = stats?.overview || {}
  const weeklyTrend = stats?.weekly_trend || []
  const todayReminders = stats?.today_reminders || []
  const statusBreakdown = stats?.status_breakdown || {}
  const patientCompliance = stats?.patient_compliance || []

  const breakdownData = Object.entries(statusBreakdown).map(([key, val]) => ({
    name: statusLabel[key] || key,
    count: val,
    fill: statusColor[key] || '#94a3b8'
  }))

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Stats Overview */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard
          title="Total Lansia"
          value={overview.total_patients || 0}
          subtitle="Pasien terdaftar"
          icon={Users}
          color="primary"
          onClick={() => navigate('/patients')}
        />
        <StatsCard
          title="Resep Aktif"
          value={overview.active_prescriptions || 0}
          subtitle="Resep berjalan"
          icon={Pill}
          color="blue"
        />
        <StatsCard
          title="Reminder Aktif"
          value={overview.active_reminders || 0}
          subtitle="Jadwal pengingat"
          icon={Bell}
          color="purple"
        />
        <StatsCard
          title="Kepatuhan 30 Hari"
          value={`${overview.compliance_rate_30d || 0}%`}
          subtitle={`${overview.taken_logs_30d || 0} dari ${overview.total_logs_30d || 0} dosis`}
          icon={TrendingUp}
          color={overview.compliance_rate_30d >= 80 ? 'green' : overview.compliance_rate_30d >= 60 ? 'orange' : 'red'}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Weekly Trend Chart */}
        <div className="lg:col-span-2 card">
          <div className="card-header">
            <div>
              <h3 className="font-semibold text-slate-800">Tren Kepatuhan 7 Hari</h3>
              <p className="text-xs text-slate-400">Persentase minum obat tepat waktu</p>
            </div>
          </div>
          <div className="card-body">
            <ResponsiveContainer width="100%" height={220}>
              <LineChart data={weeklyTrend}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis dataKey="day" tick={{ fontSize: 12, fill: '#94a3b8' }} />
                <YAxis domain={[0, 100]} tick={{ fontSize: 12, fill: '#94a3b8' }} unit="%" />
                <Tooltip
                  contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 16px rgba(0,0,0,0.1)', fontSize: '12px' }}
                  formatter={(val) => [`${val}%`, 'Kepatuhan']}
                />
                <Line type="monotone" dataKey="rate" stroke="#14b8a6" strokeWidth={2.5} dot={{ fill: '#14b8a6', r: 4 }} activeDot={{ r: 6 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Status Breakdown */}
        <div className="card">
          <div className="card-header">
            <h3 className="font-semibold text-slate-800">Status 30 Hari</h3>
          </div>
          <div className="card-body space-y-3">
            {breakdownData.length > 0 ? breakdownData.map(item => (
              <div key={item.name} className="flex items-center gap-3">
                <div className="w-3 h-3 rounded-full flex-shrink-0" style={{ backgroundColor: item.fill }} />
                <span className="text-sm text-slate-600 flex-1">{item.name}</span>
                <span className="text-sm font-bold text-slate-800">{item.count}</span>
              </div>
            )) : (
              <p className="text-sm text-slate-400 text-center py-4">Belum ada data</p>
            )}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Today's Reminders */}
        <div className="card">
          <div className="card-header">
            <div>
              <h3 className="font-semibold text-slate-800">Reminder Hari Ini</h3>
              <p className="text-xs text-slate-400">{todayReminders.length} jadwal</p>
            </div>
          </div>
          <div className="divide-y divide-slate-50 max-h-72 overflow-y-auto">
            {todayReminders.length === 0 ? (
              <div className="text-center py-8 text-slate-400 text-sm">Tidak ada reminder hari ini</div>
            ) : todayReminders.map((r, idx) => (
              <div key={idx} className="px-6 py-3 flex items-center gap-3 hover:bg-slate-50">
                <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 ${r.logged_today ? 'bg-green-100' : 'bg-orange-100'}`}>
                  {r.logged_today ? <CheckCircle size={16} className="text-green-600" /> : <Clock size={16} className="text-orange-600" />}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-slate-700 truncate">{r.patient_name}</p>
                  <p className="text-xs text-slate-400">{r.medication_name} — {r.scheduled_time}</p>
                </div>
                {r.today_status && (
                  <span className={`badge badge-${r.today_status === 'taken' ? 'green' : r.today_status === 'missed' ? 'red' : 'yellow'} text-xs`}>
                    {statusLabel[r.today_status]}
                  </span>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Patient Compliance */}
        <div className="card">
          <div className="card-header">
            <div>
              <h3 className="font-semibold text-slate-800">Kepatuhan per Pasien</h3>
              <p className="text-xs text-slate-400">30 hari terakhir</p>
            </div>
            <button onClick={() => navigate('/patients')} className="btn-secondary btn-sm">Lihat Semua</button>
          </div>
          <div className="divide-y divide-slate-50 max-h-72 overflow-y-auto">
            {patientCompliance.length === 0 ? (
              <div className="text-center py-8 text-slate-400 text-sm">Belum ada data</div>
            ) : patientCompliance.slice(0, 6).map((p, idx) => (
              <div key={idx} className="px-6 py-3 flex items-center gap-3 hover:bg-slate-50 cursor-pointer"
                onClick={() => navigate(`/patients/${p.patient_id}`)}>
                <div className="w-8 h-8 rounded-lg bg-gradient-medical flex items-center justify-center text-white text-xs font-bold flex-shrink-0">
                  {p.patient_name?.charAt(0)}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-slate-700 truncate">{p.patient_name}</p>
                  <div className="flex items-center gap-2 mt-1">
                    <div className="flex-1 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all"
                        style={{
                          width: `${p.compliance_rate}%`,
                          backgroundColor: p.compliance_rate >= 80 ? '#14b8a6' : p.compliance_rate >= 60 ? '#f97316' : '#ef4444'
                        }}
                      />
                    </div>
                    <span className="text-xs font-bold text-slate-600 w-10 text-right">{p.compliance_rate}%</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

export default DashboardPage
