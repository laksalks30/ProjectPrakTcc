// ============ FILE: frontend/src/components/Sidebar.jsx ============
import React, { useState } from 'react'
import { NavLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import {
  LayoutDashboard, Users, Pill, FileText, Bell, ClipboardList,
  User, LogOut, ChevronLeft, ChevronRight, Heart
} from 'lucide-react'

const navItems = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard', roles: ['admin', 'user'] },
  { to: '/patients', icon: Users, label: 'Data Lansia', roles: ['admin', 'user'] },
  { to: '/medications', icon: Pill, label: 'Master Obat', roles: ['admin'] },
  { to: '/prescriptions/add', icon: FileText, label: 'Tambah Resep', roles: ['admin'] },
  { to: '/reminders', icon: Bell, label: 'Jadwal Reminder', roles: ['user'] },
  { to: '/logs', icon: ClipboardList, label: 'Riwayat Log', roles: ['user'] },
  { to: '/profile', icon: User, label: 'Profil Saya', roles: ['admin', 'user'] },
]

const Sidebar = () => {
  const [collapsed, setCollapsed] = useState(false)
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = async () => {
    await logout()
    navigate('/login')
  }

  const roleBadge = {
    admin: { label: 'Admin', color: 'bg-purple-100 text-purple-700' },
    user: { label: 'User', color: 'bg-blue-100 text-blue-700' },
  }
  const role = roleBadge[user?.role] || roleBadge.user

  return (
    <aside
      className={`flex flex-col bg-white border-r border-slate-100 shadow-sm transition-all duration-300 ${
        collapsed ? 'w-16' : 'w-64'
      }`}
    >
      {/* Logo */}
      <div className={`flex items-center gap-3 px-4 py-5 border-b border-slate-100 ${collapsed ? 'justify-center' : ''}`}>
        <div className="w-9 h-9 bg-gradient-medical rounded-xl flex items-center justify-center flex-shrink-0">
          <Heart size={18} className="text-white" />
        </div>
        {!collapsed && (
          <div>
            <h1 className="font-bold text-slate-800 text-sm leading-tight">ObatLansia</h1>
            <p className="text-xs text-slate-400">Pengingat Minum Obat</p>
          </div>
        )}
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        {navItems
          .filter(item => item.roles.includes(user?.role || 'user'))
          .map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) =>
              `sidebar-link ${isActive ? 'active' : ''} ${collapsed ? 'justify-center px-2' : ''}`
            }
            title={collapsed ? label : ''}
          >
            <Icon size={18} className="flex-shrink-0" />
            {!collapsed && <span>{label}</span>}
          </NavLink>
        ))}
      </nav>

      {/* User Info & Logout */}
      <div className="border-t border-slate-100 p-3">
        {!collapsed && user && (
          <div className="flex items-center gap-3 px-2 py-2 mb-2 rounded-lg bg-slate-50">
            <div className="w-8 h-8 rounded-full bg-gradient-medical flex items-center justify-center text-white text-xs font-bold flex-shrink-0">
              {user.avatar_url ? (
                <img src={user.avatar_url} alt={user.name} className="w-8 h-8 rounded-full object-cover" />
              ) : (
                user.name?.charAt(0).toUpperCase()
              )}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-slate-700 truncate">{user.name}</p>
              <span className={`text-xs px-1.5 py-0.5 rounded font-medium ${role.color}`}>{role.label}</span>
            </div>
          </div>
        )}
        <button
          onClick={handleLogout}
          className={`sidebar-link w-full text-red-500 hover:bg-red-50 hover:text-red-600 ${collapsed ? 'justify-center px-2' : ''}`}
          title={collapsed ? 'Logout' : ''}
        >
          <LogOut size={18} />
          {!collapsed && <span>Logout</span>}
        </button>
      </div>

      {/* Collapse Toggle */}
      <button
        onClick={() => setCollapsed(!collapsed)}
        className="absolute left-full top-1/2 -translate-y-1/2 w-5 h-10 bg-white border border-slate-200 rounded-r-lg flex items-center justify-center text-slate-400 hover:text-primary-600 hover:bg-primary-50 transition-colors shadow-sm"
        style={{ marginLeft: '-1px' }}
      >
        {collapsed ? <ChevronRight size={12} /> : <ChevronLeft size={12} />}
      </button>
    </aside>
  )
}

export default Sidebar
