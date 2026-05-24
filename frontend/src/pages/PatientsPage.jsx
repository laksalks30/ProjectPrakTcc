// ============ FILE: frontend/src/pages/PatientsPage.jsx ============
import React, { useEffect, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { patientService } from '../services/api'
import PatientCard from '../components/PatientCard'
import { Plus, Search, Users, List, Grid } from 'lucide-react'
import toast from 'react-hot-toast'
import { useAuth } from '../context/AuthContext'

const PatientsPage = () => {
  const navigate = useNavigate()
  const { user } = useAuth()
  const [patients, setPatients] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const [meta, setMeta] = useState({ total: 0, totalPages: 1 })
  const [view, setView] = useState('grid')
  const limit = 9

  const fetchPatients = useCallback(async () => {
    setLoading(true)
    try {
      const res = await patientService.getAll({ page, limit, search: search || undefined })
      setPatients(res.data.data.patients || [])
      if (res.data.meta) setMeta(res.data.meta)
    } catch (e) {
      toast.error('Gagal memuat data lansia')
    } finally {
      setLoading(false)
    }
  }, [page, search])

  useEffect(() => { fetchPatients() }, [fetchPatients])

  const handleSearch = (e) => { setSearch(e.target.value); setPage(1) }

  const handleDelete = async (id) => {
    if (!window.confirm('Yakin ingin menghapus data lansia ini?')) return
    try {
      await patientService.delete(id)
      toast.success('Data lansia berhasil dihapus')
      fetchPatients()
    } catch (e) {
      toast.error('Gagal menghapus data lansia')
    }
  }

  return (
    <div className="space-y-5 animate-fade-in">
      <div className="page-header">
        <div>
          <h1 className="page-title">Data Lansia</h1>
          <p className="page-subtitle">{meta.total} lansia terdaftar</p>
        </div>
        {user?.role === 'user' && (
          <button onClick={() => navigate('/patients/add')} className="btn-primary">
            <Plus size={16} /> Tambah Lansia
          </button>
        )}
      </div>

      {/* Search & View Toggle */}
      <div className="flex gap-3 items-center">
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            className="form-input pl-10"
            placeholder="Cari nama lansia..."
            value={search}
            onChange={handleSearch}
          />
        </div>
        <div className="flex gap-1 border border-slate-200 rounded-lg p-1 bg-white">
          <button onClick={() => setView('grid')}
            className={`p-1.5 rounded ${view === 'grid' ? 'bg-primary-100 text-primary-600' : 'text-slate-400 hover:text-slate-600'}`}>
            <Grid size={16} />
          </button>
          <button onClick={() => setView('list')}
            className={`p-1.5 rounded ${view === 'list' ? 'bg-primary-100 text-primary-600' : 'text-slate-400 hover:text-slate-600'}`}>
            <List size={16} />
          </button>
        </div>
      </div>

      {/* Content */}
      {loading ? (
        <div className="flex items-center justify-center py-20">
          <div className="spinner w-8 h-8" />
        </div>
      ) : patients.length === 0 ? (
        <div className="card p-12 text-center">
          <Users size={48} className="mx-auto text-slate-200 mb-4" />
          <p className="text-slate-500 font-medium">Belum ada data lansia</p>
          {user?.role === 'user' && (
            <>
              <p className="text-slate-400 text-sm mt-1">Klik tombol "Tambah Lansia" untuk menambahkan data</p>
              <button onClick={() => navigate('/patients/add')} className="btn-primary mt-4 mx-auto">
                <Plus size={16} /> Tambah Lansia Pertama
              </button>
            </>
          )}
        </div>
      ) : (
        <>
          {view === 'grid' ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {patients.map(p => <PatientCard key={p.id} patient={p} onDelete={user?.role === 'user' ? handleDelete : undefined} />)}
            </div>
          ) : (
            <div className="table-container">
              <table className="table">
                <thead>
                  <tr>
                    <th>Nama</th>
                    <th>Usia / Gender</th>
                    <th>Golongan Darah</th>
                    <th>Alamat</th>
                    <th>Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  {patients.map(p => {
                    const age = p.birth_date ? new Date().getFullYear() - new Date(p.birth_date).getFullYear() : '-'
                    return (
                      <tr key={p.id}>
                        <td className="font-medium text-slate-800">{p.name}</td>
                        <td>{age} thn / {p.gender === 'male' ? 'L' : 'P'}</td>
                        <td>{p.blood_type || '-'}</td>
                        <td className="max-w-xs truncate">{p.address || '-'}</td>
                        <td>
                          <div className="flex gap-2">
                            <button onClick={() => navigate(`/patients/${p.id}`)} className="btn-secondary btn-sm">Detail</button>
                            {user?.role === 'user' && (
                              <button onClick={() => handleDelete(p.id)} className="btn btn-sm bg-red-50 text-red-500 border border-red-200 hover:bg-red-100">Hapus</button>
                            )}
                          </div>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          )}

          {/* Pagination */}
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

export default PatientsPage
