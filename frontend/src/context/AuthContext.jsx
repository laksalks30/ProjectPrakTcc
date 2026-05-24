// ============ FILE: frontend/src/context/AuthContext.jsx ============
import React, { createContext, useContext, useState, useEffect, useCallback } from 'react'
import { authService } from '../services/api'
import toast from 'react-hot-toast'

const AuthContext = createContext(null)

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null)
  const [token, setToken] = useState(null)
  const [loading, setLoading] = useState(true)
  const [isAuthenticated, setIsAuthenticated] = useState(false)

  useEffect(() => {
    const storedToken = localStorage.getItem('token')
    const storedUser = localStorage.getItem('user')
    if (storedToken && storedUser) {
      try {
        setToken(storedToken)
        setUser(JSON.parse(storedUser))
        setIsAuthenticated(true)
      } catch {
        localStorage.removeItem('token')
        localStorage.removeItem('user')
      }
    }
    setLoading(false)
  }, [])

  const login = useCallback(async (email, password) => {
    try {
      const response = await authService.login({ email, password })
      const { token: newToken, user: userData } = response.data.data
      localStorage.setItem('token', newToken)
      localStorage.setItem('user', JSON.stringify(userData))
      setToken(newToken)
      setUser(userData)
      setIsAuthenticated(true)
      toast.success(`Selamat datang, ${userData.name}!`)
      return { success: true }
    } catch (error) {
      const message = error.response?.data?.message || 'Login gagal. Periksa email dan password.'
      toast.error(message)
      return { success: false, message }
    }
  }, [])

  const register = useCallback(async (formData) => {
    try {
      const response = await authService.register(formData)
      toast.success('Registrasi berhasil! Silakan login untuk melanjutkan.')
      return { success: true }
    } catch (error) {
      const message = error.response?.data?.message || 'Registrasi gagal. Coba lagi.'
      toast.error(message)
      return { success: false, message }
    }
  }, [])

  const logout = useCallback(async () => {
    try {
      await authService.logout()
    } catch {}
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    setToken(null)
    setUser(null)
    setIsAuthenticated(false)
    toast.success('Berhasil logout.')
  }, [])

  const updateUser = useCallback((updatedUser) => {
    setUser(updatedUser)
    localStorage.setItem('user', JSON.stringify(updatedUser))
  }, [])

  return (
    <AuthContext.Provider value={{ user, token, loading, isAuthenticated, login, register, logout, updateUser }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth must be used within AuthProvider')
  return context
}

export default AuthContext
