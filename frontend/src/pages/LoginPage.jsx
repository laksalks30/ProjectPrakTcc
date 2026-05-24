// ============ FILE: frontend/src/pages/LoginPage.jsx ============
import React, { useState, useCallback } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { Heart, Eye, EyeOff, Mail, Lock } from 'lucide-react'

const LoginPage = () => {
  const { login, isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const [form, setForm] = useState({ email: '', password: '' })
  const [errors, setErrors] = useState({})
  const [loading, setLoading] = useState(false)
  const [showPassword, setShowPassword] = useState(false)

  if (isAuthenticated) { navigate('/dashboard', { replace: true }); return null }

  const validate = useCallback(() => {
    const errs = {}
    if (!form.email) errs.email = 'Email wajib diisi'
    else if (!/\S+@\S+\.\S+/.test(form.email)) errs.email = 'Format email tidak valid'
    if (!form.password) errs.password = 'Password wajib diisi'
    else if (form.password.length < 5) errs.password = 'Password minimal 5 karakter'
    return errs
  }, [form])

  const handleChange = useCallback((e) => {
    const { name, value } = e.target
    setForm(p => ({ ...p, [name]: value }))
  }, [])

  const handleSubmit = useCallback(async (e) => {
    e.preventDefault()
    const errs = validate()
    if (Object.keys(errs).length > 0) { setErrors(errs); return }
    setErrors({})
    setLoading(true)
    const result = await login(form.email, form.password)
    if (result.success) navigate('/dashboard', { replace: true })
    setLoading(false)
  }, [form, validate, login, navigate])

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-600 via-primary-700 to-secondary-700 flex items-center justify-center p-4">
      <div className="w-full max-w-md animate-slide-up">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center mx-auto mb-4">
            <Heart size={32} className="text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white">ObatLansia</h1>
          <p className="text-primary-200 mt-1 text-sm">Pengingat Minum Obat untuk Lansia</p>
        </div>

        {/* Card */}
        <div className="bg-white rounded-2xl shadow-2xl p-8">
          <h2 className="text-xl font-bold text-slate-800 mb-1">Selamat Datang</h2>
          <p className="text-slate-500 text-sm mb-6">Masuk ke akun Anda untuk melanjutkan</p>

          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Email */}
            <div>
              <label className="form-label">Email</label>
              <div className="relative">
                <Mail size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="email"
                  name="email"
                  className={`form-input pl-10 ${errors.email ? 'form-input-error' : ''}`}
                  placeholder="contoh@email.com"
                  value={form.email}
                  onChange={handleChange}
                  autoComplete="email"
                />
              </div>
              {errors.email && <p className="form-error">{errors.email}</p>}
            </div>

            {/* Password */}
            <div>
              <label className="form-label">Password</label>
              <div className="relative">
                <Lock size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  name="password"
                  className={`form-input pl-10 pr-10 ${errors.password ? 'form-input-error' : ''}`}
                  placeholder="Masukkan password"
                  value={form.password}
                  onChange={handleChange}
                  autoComplete="current-password"
                />
                <button type="button" onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
              {errors.password && <p className="form-error">{errors.password}</p>}
            </div>

            <button type="submit" className="btn-primary w-full btn-lg" disabled={loading}>
              {loading ? <span className="spinner w-4 h-4" /> : null}
              {loading ? 'Memproses...' : 'Masuk'}
            </button>
          </form>

          <div className="mt-4 p-3 bg-slate-50 rounded-lg border border-slate-100">
          </div>

          <p className="text-center text-sm text-slate-500 mt-5">
            Belum punya akun?{' '}
            <Link to="/register" className="text-primary-600 hover:text-primary-700 font-semibold">Daftar sekarang</Link>
          </p>
        </div>
      </div>
    </div>
  )
}

export default LoginPage
