// ============ FILE: frontend/src/components/PatientCard.jsx ============
import React from 'react'
import { useNavigate } from 'react-router-dom'
import { User, MapPin, Droplets, Phone, Eye, Trash2 } from 'lucide-react'

const PatientCard = ({ patient, onDelete }) => {
  const navigate = useNavigate()
  const age = patient.birth_date
    ? new Date().getFullYear() - new Date(patient.birth_date).getFullYear()
    : '-'

  return (
    <div className="card hover:shadow-card-hover transition-all duration-200 group">
      <div className="p-5">
        <div className="flex items-start gap-4">
          <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-primary-400 to-secondary-500 flex items-center justify-center flex-shrink-0 overflow-hidden">
            {patient.photo_url ? (
              <img src={patient.photo_url} alt={patient.name} className="w-full h-full object-cover" />
            ) : (
              <User size={24} className="text-white" />
            )}
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="font-semibold text-slate-800 text-base truncate">{patient.name}</h3>
            <p className="text-sm text-slate-500">{age} tahun • {patient.gender === 'male' ? 'Laki-laki' : 'Perempuan'}</p>
            <div className="flex flex-wrap gap-x-3 gap-y-1 mt-2">
              {patient.blood_type && (
                <span className="flex items-center gap-1 text-xs text-slate-500">
                  <Droplets size={11} className="text-red-400" />
                  Gol. {patient.blood_type}
                </span>
              )}
              {patient.address && (
                <span className="flex items-center gap-1 text-xs text-slate-500 truncate max-w-[180px]">
                  <MapPin size={11} className="text-slate-400 flex-shrink-0" />
                  {patient.address}
                </span>
              )}
            </div>
          </div>
        </div>

        {patient.medical_notes && (
          <div className="mt-3 p-2.5 bg-amber-50 rounded-lg border border-amber-100">
            <p className="text-xs text-amber-700 line-clamp-2">{patient.medical_notes}</p>
          </div>
        )}

        <div className="flex gap-2 mt-4">
          <button
            onClick={() => navigate(`/patients/${patient.id}`)}
            className="flex-1 btn-secondary btn-sm flex items-center justify-center gap-1.5"
          >
            <Eye size={13} />
            Detail
          </button>
          <button
            onClick={() => onDelete && onDelete(patient.id)}
            className="btn btn-sm bg-red-50 text-red-500 border border-red-200 hover:bg-red-100"
          >
            <Trash2 size={13} />
          </button>
        </div>
      </div>
    </div>
  )
}

export default PatientCard
