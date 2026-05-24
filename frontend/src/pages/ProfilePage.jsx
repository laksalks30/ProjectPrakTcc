// ============ FILE: frontend/src/pages/ProfilePage.jsx ============
import React, { useState } from 'react'
import { useAuth } from '../context/AuthContext'
import { authService } from '../services/api'
import { User, Mail, Phone, Shield, Upload, Save, Key } from 'lucide-react'
import toast from 'react-hot-toast'

const ProfilePage = () => {
  const { user, updateUser } = useAuth()
  const [loading, setLoading] = useState(false)
  const [photoPreview, setPhotoPreview] = useState(user?.avatar_url || null)
  const [photoFile, setPhotoFile] = useState(null)
  const [activeTab, setActiveTab] = useState('profile')
  const [form, setForm] = useState({ name: user?.name || '', phone: user?.phone || '' })
  const [pwForm, setPwForm] = useState({ password: '', confirmPassword: '' })
  const [pwErrors, setPwErrors] = useState({})

  const roleBadge = {
    admin: { label: 'Admin', cls: 'bg-purple-100 text-purple-700' },
    user: { label: 'User Biasa', cls: 'bg-blue-100 text-blue-700' },
  }
  const role = roleBadge[user?.role] || roleBadge.user

  const handlePhotoChange = (e) => {
    const file = e.target.files[0]
    if (!file) return
    if (file.size > 5 * 1024 * 1024) { toast.error('Foto maksimal 5MB'); return }
    setPhotoFile(file)
    setPhotoPreview(URL.createObjectURL(file))
  }

  const handleProfileUpdate = async (e) => {
    e.preventDefault()
    if (!form.name || form.name.trim().length < 2) { toast.error('Nama minimal 2 karakter'); return }
    setLoading(true)
    try {
      const fd = new FormData()
      fd.append('name', form.name)
      if (form.phone) fd.append('phone', form.phone)
      if (photoFile) fd.append('avatar', photoFile)
      const res = await authService.updateProfile(fd)
      updateUser(res.data.data.user)
      toast.success('Profil berhasil diperbarui!')
    } catch (e) {
      toast.error(e.response?.data?.message || 'Gagal memperbarui profil')
    } finally { setLoading(false) }
  }

  const handlePasswordUpdate = async (e) => {
    e.preventDefault()
    const errs = {}
    if (!pwForm.password || pwForm.password.length < 6) errs.password = 'Password minimal 6 karakter'
    if (pwForm.password !== pwForm.confirmPassword) errs.confirmPassword = 'Konfirmasi password tidak cocok'
    if (Object.keys(errs).length > 0) { setPwErrors(errs); return }
    setPwErrors({})
    setLoading(true)
    try {
      const fd = new FormData()
      fd.append('password', pwForm.password)
      await authService.updateProfile(fd)
      toast.success('Password berhasil diubah!')
      setPwForm({ password: '', confirmPassword: '' })
    } catch (e) {
      toast.error(e.response?.data?.message || 'Gagal mengubah password')
    } finally { setLoading(false) }
  }

  return (
    <div className="max-w-2xl mx-auto space-y-5 animate-fade-in">
      <div>
        <h1 className="page-title">Profil Saya</h1>
        <p className="page-subtitle">Kelola informasi akun Anda</p>
      </div>

      {/* Profile Header Card */}
      <div className="card p-6">
        <div className="flex items-center gap-5">
          <div className="relative">
            <div className="w-20 h-20 rounded-2xl bg-gradient-medical overflow-hidden flex items-center justify-center">
              {photoPreview
                ? <img src={photoPreview} alt="Avatar" className="w-full h-full object-cover" />
                : <span className="text-white text-2xl font-bold">{user?.name?.charAt(0)?.toUpperCase()}</span>}
            </div>
            <label htmlFor="avatar-upload"
              className="absolute -bottom-1 -right-1 w-7 h-7 bg-primary-500 rounded-lg flex items-center justify-center cursor-pointer hover:bg-primary-600 transition-colors shadow-md">
              <Upload size={13} className="text-white" />
            </label>
            <input id="avatar-upload" type="file" accept="image/*" className="hidden" onChange={handlePhotoChange} />
          </div>
          <div>
            <h2 className="text-xl font-bold text-slate-800">{user?.name}</h2>
            <p className="text-slate-500 text-sm">{user?.email}</p>
            <span className={`inline-block mt-1.5 text-xs font-semibold px-2.5 py-0.5 rounded-full ${role.cls}`}>{role.label}</span>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-200">
        {[
          { key: 'profile', label: 'Info Profil', icon: User },
          { key: 'password', label: 'Ubah Password', icon: Key },
        ].map(tab => (
          <button key={tab.key} onClick={() => setActiveTab(tab.key)}
            className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === tab.key
                ? 'border-primary-500 text-primary-600'
                : 'border-transparent text-slate-500 hover:text-slate-700'
            }`}>
            <tab.icon size={15} />
            {tab.label}
          </button>
        ))}
      </div>

      {/* Profile Tab */}
      {activeTab === 'profile' && (
        <div className="card animate-fade-in">
          <div className="card-header"><h3 className="font-semibold text-slate-700">Informasi Pribadi</h3></div>
          <form onSubmit={handleProfileUpdate} className="card-body space-y-4">
            <div>
              <label className="form-label">Nama Lengkap</label>
              <div className="relative">
                <User size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                <input className="form-input pl-10" placeholder="Nama lengkap"
                  value={form.name} onChange={e => setForm(p => ({ ...p, name: e.target.value }))} />
              </div>
            </div>
            <div>
              <label className="form-label">Email</label>
              <div className="relative">
                <Mail size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                <input className="form-input pl-10 bg-slate-50 cursor-not-allowed" value={user?.email || ''} disabled />
              </div>
              <p className="text-xs text-slate-400 mt-1">Email tidak dapat diubah</p>
            </div>
            <div>
              <label className="form-label">Nomor HP</label>
              <div className="relative">
                <Phone size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                <input className="form-input pl-10" placeholder="+62 812 3456 7890"
                  value={form.phone} onChange={e => setForm(p => ({ ...p, phone: e.target.value }))} />
              </div>
            </div>
            <div>
              <label className="form-label">Role</label>
              <div className="relative">
                <Shield size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                <input className="form-input pl-10 bg-slate-50 cursor-not-allowed capitalize" value={user?.role || ''} disabled />
              </div>
            </div>
            {photoFile && (
              <div className="p-3 bg-primary-50 rounded-lg border border-primary-100 text-sm text-primary-700">
                📸 Foto baru akan disimpan bersama perubahan profil
              </div>
            )}
            <button type="submit" className="btn-primary w-full" disabled={loading}>
              {loading ? <><span className="spinner w-4 h-4" /> Menyimpan...</> : <><Save size={16} /> Simpan Perubahan</>}
            </button>
          </form>
        </div>
      )}

      {/* Password Tab */}
      {activeTab === 'password' && (
        <div className="card animate-fade-in">
          <div className="card-header"><h3 className="font-semibold text-slate-700">Ubah Password</h3></div>
          <form onSubmit={handlePasswordUpdate} className="card-body space-y-4">
            <div>
              <label className="form-label">Password Baru</label>
              <input type="password" className={`form-input ${pwErrors.password ? 'form-input-error' : ''}`}
                placeholder="Minimal 6 karakter"
                value={pwForm.password} onChange={e => setPwForm(p => ({ ...p, password: e.target.value }))} />
              {pwErrors.password && <p className="form-error">{pwErrors.password}</p>}
            </div>
            <div>
              <label className="form-label">Konfirmasi Password Baru</label>
              <input type="password" className={`form-input ${pwErrors.confirmPassword ? 'form-input-error' : ''}`}
                placeholder="Ulangi password baru"
                value={pwForm.confirmPassword} onChange={e => setPwForm(p => ({ ...p, confirmPassword: e.target.value }))} />
              {pwErrors.confirmPassword && <p className="form-error">{pwErrors.confirmPassword}</p>}
            </div>
            <button type="submit" className="btn-primary w-full" disabled={loading}>
              {loading ? <><span className="spinner w-4 h-4" /> Menyimpan...</> : <><Key size={16} /> Ubah Password</>}
            </button>
          </form>
        </div>
      )}
    </div>
  )
}

export default ProfilePage
