// ============ FILE: frontend/src/pages/RegisterPage.jsx ============
import React, { useState, useCallback, memo } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { Heart, Eye, EyeOff, Mail, Lock, User, Phone } from 'lucide-react'

// Memoized Field component to prevent re-creation on every render
const Field = memo(({ label, icon: Icon, name, type = 'text', placeholder, value, error, onChange, children }) => (
  <div>
    <label className="form-label">{label}</label>
    {children || (
      <div className="relative">
        {Icon && <Icon size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />}
        <input
          type={type}
          name={name}
          className={`form-input ${Icon ? 'pl-10' : ''} ${error ? 'form-input-error' : ''}`}
          placeholder={placeholder}
          value={value}
          onChange={onChange}
        />
      </div>
    )}
    {error && <p className="form-error">{error}</p>}
  </div>
))

Field.displayName = 'Field'

const RegisterPage = () => {
  const { register, isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const [form, setForm] = useState({ name: '', email: '', password: '', confirmPassword: '', role: 'user', phone: '' })
  const [errors, setErrors] = useState({})
  const [loading, setLoading] = useState(false)
  const [showPassword, setShowPassword] = useState(false)

  if (isAuthenticated) { navigate('/dashboard', { replace: true }); return null }

  const validate = useCallback(() => {
    const errs = {}
    if (!form.name || form.name.length < 2) errs.name = 'Nama minimal 2 karakter'
    if (!form.email) errs.email = 'Email wajib diisi'
    else if (!/\S+@\S+\.\S+/.test(form.email)) errs.email = 'Format email tidak valid'
    if (!form.password || form.password.length < 6) errs.password = 'Password minimal 6 karakter'
    if (form.password !== form.confirmPassword) errs.confirmPassword = 'Konfirmasi password tidak cocok'
    return errs
  }, [form])

  const handleChange = useCallback((e) => {
    const { name, value } = e.target
    setForm(p => ({ ...p, [name]: value }))
  }, [])

  const handleRoleChange = useCallback((e) => {
    setForm(p => ({ ...p, role: e.target.value }))
  }, [])

  const handleSubmit = useCallback(async (e) => {
    e.preventDefault()
    const errs = validate()
    if (Object.keys(errs).length > 0) { setErrors(errs); return }
    setErrors({})
    setLoading(true)
    const payload = { name: form.name, email: form.email, password: form.password, role: form.role }
    if (form.phone) payload.phone = form.phone
    const result = await register(payload)
    if (result.success) navigate('/login', { replace: true })
    setLoading(false)
  }, [form, validate, register, navigate])

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-600 via-primary-700 to-secondary-700 flex items-center justify-center p-4">
      <div className="w-full max-w-md animate-slide-up">
        <div className="text-center mb-6">
          <div className="w-14 h-14 bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center mx-auto mb-3">
            <Heart size={28} className="text-white" />
          </div>
          <h1 className="text-2xl font-bold text-white">ObatLansia</h1>
        </div>

        <div className="bg-white rounded-2xl shadow-2xl p-8">
          <h2 className="text-xl font-bold text-slate-800 mb-1">Buat Akun Baru</h2>
          <p className="text-slate-500 text-sm mb-6">Daftar untuk mulai menggunakan ObatLansia</p>

          <form onSubmit={handleSubmit} className="space-y-4">
            <Field 
              label="Nama Lengkap" 
              icon={User} 
              name="name" 
              placeholder="Nama lengkap Anda"
              value={form.name}
              error={errors.name}
              onChange={handleChange}
            />
            <Field 
              label="Email" 
              icon={Mail} 
              name="email" 
              type="email" 
              placeholder="contoh@email.com"
              value={form.email}
              error={errors.email}
              onChange={handleChange}
            />
            <Field 
              label="Nomor HP (opsional)" 
              icon={Phone} 
              name="phone" 
              placeholder="+62 812 3456 7890"
              value={form.phone}
              error={errors.phone}
              onChange={handleChange}
            />


            <div>
              <label className="form-label">Password</label>
              <div className="relative">
                <Lock size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  name="password"
                  className={`form-input pl-10 pr-10 ${errors.password ? 'form-input-error' : ''}`}
                  placeholder="Minimal 6 karakter"
                  value={form.password}
                  onChange={handleChange}
                />
                <button type="button" onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
              {errors.password && <p className="form-error">{errors.password}</p>}
            </div>

            <div>
              <label className="form-label">Konfirmasi Password</label>
              <div className="relative">
                <Lock size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  name="confirmPassword"
                  className={`form-input pl-10 ${errors.confirmPassword ? 'form-input-error' : ''}`}
                  placeholder="Ulangi password"
                  value={form.confirmPassword}
                  onChange={handleChange}
                />
              </div>
              {errors.confirmPassword && <p className="form-error">{errors.confirmPassword}</p>}
            </div>

            <button type="submit" className="btn-primary w-full btn-lg mt-2" disabled={loading}>
              {loading && <span className="spinner w-4 h-4" />}
              {loading ? 'Mendaftar...' : 'Buat Akun'}
            </button>
          </form>

          <p className="text-center text-sm text-slate-500 mt-5">
            Sudah punya akun?{' '}
            <Link to="/login" className="text-primary-600 hover:text-primary-700 font-semibold">Masuk di sini</Link>
          </p>
        </div>
      </div>
    </div>
  )
}

export default RegisterPage
