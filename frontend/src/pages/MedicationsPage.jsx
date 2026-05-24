// ============ FILE: frontend/src/pages/MedicationsPage.jsx ============
import React, { useEffect, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { medicationService } from '../services/api'
import MedicationCard from '../components/MedicationCard'
import { Plus, Search, Pill } from 'lucide-react'
import toast from 'react-hot-toast'

const MedicationsPage = () => {
  const navigate = useNavigate()
  const [medications, setMedications] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const [meta, setMeta] = useState({ total: 0, totalPages: 1 })
  const limit = 12

  const fetchMedications = useCallback(async () => {
    setLoading(true)
    try {
      const res = await medicationService.getAll({ page, limit, search: search || undefined })
      setMedications(res.data.data.medications || [])
      if (res.data.meta) setMeta(res.data.meta)
    } catch {
      toast.error('Gagal memuat data obat')
    } finally {
      setLoading(false)
    }
  }, [page, search])

  useEffect(() => { fetchMedications() }, [fetchMedications])

  const handleDelete = async (id) => {
    if (!window.confirm('Yakin ingin menghapus data obat ini?')) return
    try {
      await medicationService.delete(id)
      toast.success('Data obat berhasil dihapus')
      fetchMedications()
    } catch {
      toast.error('Gagal menghapus data obat')
    }
  }

  return (
    <div className="space-y-5 animate-fade-in">
      <div className="page-header">
        <div>
          <h1 className="page-title">Master Obat</h1>
          <p className="page-subtitle">{meta.total} jenis obat terdaftar</p>
        </div>
        <button onClick={() => navigate('/medications/add')} className="btn-primary">
          <Plus size={16} /> Tambah Obat
        </button>
      </div>

      <div className="relative max-w-sm">
        <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
        <input type="text" className="form-input pl-10" placeholder="Cari nama obat..."
          value={search} onChange={e => { setSearch(e.target.value); setPage(1) }} />
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-20"><div className="spinner w-8 h-8" /></div>
      ) : medications.length === 0 ? (
        <div className="card p-12 text-center">
          <Pill size={48} className="mx-auto text-slate-200 mb-4" />
          <p className="text-slate-500 font-medium">Belum ada data obat</p>
          <button onClick={() => navigate('/medications/add')} className="btn-primary mt-4 mx-auto">
            <Plus size={16} /> Tambah Obat Pertama
          </button>
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {medications.map(m => (
              <MedicationCard key={m.id} medication={m} onDelete={handleDelete} />
            ))}
          </div>
          {meta.totalPages > 1 && (
            <div className="flex items-center justify-center gap-2 mt-4">
              <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}
                className="btn-secondary btn-sm disabled:opacity-40">← Prev</button>
              <span className="text-sm text-slate-600">Halaman {page} dari {meta.totalPages}</span>
              <button onClick={() => setPage(p => Math.min(meta.totalPages, p + 1))} disabled={page === meta.totalPages}
                className="btn-secondary btn-sm disabled:opacity-40">Next →</button>
            </div>
          )}
        </>
      )}
    </div>
  )
}

export default MedicationsPage
