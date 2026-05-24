// ============ FILE: frontend/src/App.jsx ============
import React from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuth } from './context/AuthContext'
import ProtectedRoute from './components/ProtectedRoute'

// Pages
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import DashboardPage from './pages/DashboardPage'
import PatientsPage from './pages/PatientsPage'
import AddPatientPage from './pages/AddPatientPage'
import PatientDetailPage from './pages/PatientDetailPage'
import MedicationsPage from './pages/MedicationsPage'
import AddMedicationPage from './pages/AddMedicationPage'
import AddPrescriptionPage from './pages/AddPrescriptionPage'
import RemindersPage from './pages/RemindersPage'
import LogsPage from './pages/LogsPage'
import ProfilePage from './pages/ProfilePage'

const App = () => {
  const { loading } = useAuth()

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-50 to-secondary-50">
        <div className="flex flex-col items-center gap-4">
          <div className="w-16 h-16 spinner" style={{ width: '3rem', height: '3rem', borderWidth: '3px' }} />
          <p className="text-slate-500 text-sm font-medium">Memuat aplikasi...</p>
        </div>
      </div>
    )
  }

  return (
    <Routes>
      {/* Public Routes */}
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />

      {/* Protected Routes */}
      <Route element={<ProtectedRoute />}>
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/patients" element={<PatientsPage />} />
        <Route path="/patients/add" element={<AddPatientPage />} />
        <Route path="/patients/:id" element={<PatientDetailPage />} />
        <Route path="/medications" element={<MedicationsPage />} />
        <Route path="/medications/add" element={<AddMedicationPage />} />
        <Route path="/prescriptions/add" element={<AddPrescriptionPage />} />
        <Route path="/reminders" element={<RemindersPage />} />
        <Route path="/logs" element={<LogsPage />} />
        <Route path="/profile" element={<ProfilePage />} />
      </Route>

      {/* Redirects */}
      <Route path="/" element={<Navigate to="/dashboard" replace />} />
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  )
}

export default App
