// ============ FILE: frontend/src/components/MedicationCard.jsx ============
import React from 'react'
import { Pill, Tag, Package, Trash2, Edit } from 'lucide-react'

const MedicationCard = ({ medication, onDelete, onEdit }) => {
  return (
    <div className="card hover:shadow-card-hover transition-all duration-200">
      <div className="p-5">
        <div className="flex items-start gap-3">
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-teal-400 to-primary-500 flex items-center justify-center flex-shrink-0 overflow-hidden">
            {medication.photo_url ? (
              <img src={medication.photo_url} alt={medication.name} className="w-full h-full object-cover" />
            ) : (
              <Pill size={20} className="text-white" />
            )}
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="font-semibold text-slate-800 text-sm leading-tight truncate">{medication.name}</h3>
            {medication.generic_name && (
              <p className="text-xs text-slate-400 truncate">{medication.generic_name}</p>
            )}
            <div className="flex flex-wrap gap-1.5 mt-2">
              {medication.category && (
                <span className="flex items-center gap-1 badge badge-blue text-xs">
                  <Tag size={10} />
                  {medication.category}
                </span>
              )}
              <span className="flex items-center gap-1 badge badge-gray text-xs">
                <Package size={10} />
                {medication.unit}
              </span>
            </div>
          </div>
        </div>

        {medication.description && (
          <p className="text-xs text-slate-500 mt-3 line-clamp-2">{medication.description}</p>
        )}

        <div className="flex gap-2 mt-4">
          {onEdit && (
            <button
              onClick={() => onEdit(medication)}
              className="flex-1 btn-secondary btn-sm flex items-center justify-center gap-1.5"
            >
              <Edit size={12} />
              Edit
            </button>
          )}
          {onDelete && (
            <button
              onClick={() => onDelete(medication.id)}
              className="btn btn-sm bg-red-50 text-red-500 border border-red-200 hover:bg-red-100"
            >
              <Trash2 size={12} />
            </button>
          )}
        </div>
      </div>
    </div>
  )
}

export default MedicationCard
