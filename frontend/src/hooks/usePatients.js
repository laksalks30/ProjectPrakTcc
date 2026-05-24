// ============ FILE: frontend/src/hooks/usePatients.js ============
import { useState, useCallback } from 'react'
import { patientService } from '../services/api'
import toast from 'react-hot-toast'

const usePatients = () => {
  const [patients, setPatients] = useState([])
  const [patient, setPatient] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [meta, setMeta] = useState({ total: 0, page: 1, limit: 10, totalPages: 1 })

  const fetchPatients = useCallback(async (params = {}) => {
    setLoading(true)
    setError(null)
    try {
      const res = await patientService.getAll(params)
      setPatients(res.data.data.patients || [])
      if (res.data.meta) setMeta(res.data.meta)
    } catch (err) {
      const msg = err.response?.data?.message || 'Gagal memuat data pasien.'
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  const fetchPatient = useCallback(async (id) => {
    setLoading(true)
    setError(null)
    try {
      const res = await patientService.getById(id)
      setPatient(res.data.data.patient)
      return res.data.data.patient
    } catch (err) {
      const msg = err.response?.data?.message || 'Gagal memuat detail pasien.'
      setError(msg)
      return null
    } finally {
      setLoading(false)
    }
  }, [])

  const createPatient = useCallback(async (formData) => {
    setLoading(true)
    try {
      const res = await patientService.create(formData)
      toast.success('Data lansia berhasil ditambahkan!')
      return { success: true, data: res.data.data.patient }
    } catch (err) {
      const msg = err.response?.data?.message || 'Gagal menambah pasien.'
      toast.error(msg)
      return { success: false, message: msg }
    } finally {
      setLoading(false)
    }
  }, [])

  const updatePatient = useCallback(async (id, formData) => {
    setLoading(true)
    try {
      const res = await patientService.update(id, formData)
      toast.success('Data lansia berhasil diperbarui!')
      return { success: true, data: res.data.data.patient }
    } catch (err) {
      const msg = err.response?.data?.message || 'Gagal memperbarui pasien.'
      toast.error(msg)
      return { success: false, message: msg }
    } finally {
      setLoading(false)
    }
  }, [])

  const deletePatient = useCallback(async (id) => {
    try {
      await patientService.delete(id)
      setPatients(prev => prev.filter(p => p.id !== id))
      toast.success('Data lansia berhasil dihapus!')
      return { success: true }
    } catch (err) {
      const msg = err.response?.data?.message || 'Gagal menghapus pasien.'
      toast.error(msg)
      return { success: false, message: msg }
    }
  }, [])

  return {
    patients, patient, loading, error, meta,
    fetchPatients, fetchPatient, createPatient, updatePatient, deletePatient
  }
}

export default usePatients
