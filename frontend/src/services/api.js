// ============ FILE: frontend/src/services/api.js ============
import axios from 'axios'
import toast from 'react-hot-toast'

// Use proxy by default for dev, absolute URL for production
const AUTH_BASE = import.meta.env.PROD 
  ? (import.meta.env.VITE_AUTH_SERVICE_URL || 'http://localhost:8001')
  : '/api/auth'
  
const MED_BASE = import.meta.env.PROD 
  ? (import.meta.env.VITE_MEDICATION_SERVICE_URL || 'http://localhost:8002')
  : '/api'

// ─── Auth API Instance ───────────────────────────────────────────
const authApi = axios.create({
  baseURL: AUTH_BASE,
  headers: { 'Content-Type': 'application/json' },
  timeout: 15000,
})

// ─── Medication API Instance ─────────────────────────────────────
const medApi = axios.create({
  baseURL: MED_BASE,
  headers: { 'Content-Type': 'application/json' },
  timeout: 15000,
})

// ─── Request Interceptor: Attach JWT ─────────────────────────────
const attachToken = (config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
}

authApi.interceptors.request.use(attachToken)
medApi.interceptors.request.use(attachToken)

// ─── Response Interceptor: Handle 401 ────────────────────────────
const handleAuthError = (error) => {
  if (error.response?.status === 401) {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    window.location.href = '/login'
    toast.error('Sesi berakhir. Silakan login kembali.')
  }
  return Promise.reject(error)
}

authApi.interceptors.response.use((r) => r, handleAuthError)
medApi.interceptors.response.use((r) => r, handleAuthError)

// ============================================================
// AUTH API CALLS
// ============================================================
export const authService = {
  register: (data) => authApi.post('/register', data),
  login: (data) => authApi.post('/login', data),
  logout: () => authApi.post('/logout'),
  getProfile: () => authApi.get('/profile'),
  updateProfile: (formData) => authApi.put('/profile', formData),
  getUsers: (params) => authApi.get('/users', { params }),
  deleteUser: (id) => authApi.delete(`/users/${id}`),
}

// ============================================================
// PATIENT API CALLS
// ============================================================
export const patientService = {
  create: (data) => medApi.post('/patients', data),
  getAll: (params) => medApi.get('/patients', { params }),
  getById: (id) => medApi.get(`/patients/${id}`),
  update: (id, formData) => medApi.put(`/patients/${id}`, formData),
  delete: (id) => medApi.delete(`/patients/${id}`),
}

// ============================================================
// MEDICATION API CALLS
// ============================================================
export const medicationService = {
  create: (data) => medApi.post('/medications', data),
  getAll: (params) => medApi.get('/medications', { params }),
  update: (id, formData) => medApi.put(`/medications/${id}`, formData),
  delete: (id) => medApi.delete(`/medications/${id}`),
}

// ============================================================
// PRESCRIPTION API CALLS
// ============================================================
export const prescriptionService = {
  create: (data) => medApi.post('/prescriptions', data),
  getByPatient: (patientId, params) => medApi.get(`/prescriptions/patient/${patientId}`, { params }),
  update: (id, data) => medApi.put(`/prescriptions/${id}`, data),
}

// ============================================================
// REMINDER API CALLS
// ============================================================
export const reminderService = {
  create: (data) => medApi.post('/reminders', data),
  getByPatient: (patientId, params) => medApi.get(`/reminders/patient/${patientId}`, { params }),
  update: (id, data) => medApi.put(`/reminders/${id}`, data),
  delete: (id) => medApi.delete(`/reminders/${id}`),
}

// ============================================================
// LOG API CALLS
// ============================================================
export const logService = {
  create: (data) => medApi.post('/logs', data),
  getByPatient: (patientId, params) => medApi.get(`/logs/patient/${patientId}`, { params }),
}

// ============================================================
// DASHBOARD API CALLS
// ============================================================
export const dashboardService = {
  getStats: () => medApi.get('/dashboard/stats'),
}

export { authApi, medApi }
