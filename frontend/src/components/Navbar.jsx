// ============ FILE: frontend/src/components/Navbar.jsx ============
import React from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { Bell, Search, User } from 'lucide-react'

const pageTitles = {
  '/dashboard': 'Dashboard',
  '/patients': 'Data Lansia',
  '/patients/add': 'Tambah Lansia',
  '/medications': 'Master Obat',
  '/medications/add': 'Tambah Obat',
  '/prescriptions/add': 'Tambah Resep',
  '/reminders': 'Jadwal Reminder',
  '/logs': 'Riwayat Log',
  '/profile': 'Profil Saya',
}

const Navbar = () => {
  const { user } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  const currentTitle = pageTitles[location.pathname] ||
    (location.pathname.startsWith('/patients/') ? 'Detail Lansia' : 'ObatLansia')

  const today = new Date().toLocaleDateString('id-ID', {
    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
  })

  return (
    <header className="bg-white border-b border-slate-100 px-6 py-3 flex items-center justify-between">
      <div>
        <h2 className="text-lg font-semibold text-slate-800">{currentTitle}</h2>
        <p className="text-xs text-slate-400">{today}</p>
      </div>

      <div className="flex items-center gap-3">
        <button
          onClick={() => navigate('/profile')}
          className="flex items-center gap-2.5 px-3 py-1.5 rounded-lg hover:bg-slate-50 transition-colors"
        >
          <div className="w-8 h-8 rounded-full bg-gradient-medical flex items-center justify-center text-white text-xs font-bold">
            {user?.avatar_url ? (
              <img src={user.avatar_url} alt={user.name} className="w-8 h-8 rounded-full object-cover" />
            ) : (
              user?.name?.charAt(0).toUpperCase()
            )}
          </div>
          <div className="text-left hidden sm:block">
            <p className="text-sm font-semibold text-slate-700 leading-tight">{user?.name}</p>
            <p className="text-xs text-slate-400 capitalize">{user?.role}</p>
          </div>
        </button>
      </div>
    </header>
  )
}

export default Navbar
