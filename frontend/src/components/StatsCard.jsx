// ============ FILE: frontend/src/components/StatsCard.jsx ============
import React from 'react'

const StatsCard = ({ title, value, subtitle, icon: Icon, color = 'primary', trend, onClick }) => {
  const colorMap = {
    primary: {
      bg: 'bg-primary-50',
      icon: 'bg-primary-500 text-white',
      text: 'text-primary-600',
    },
    blue: {
      bg: 'bg-blue-50',
      icon: 'bg-blue-500 text-white',
      text: 'text-blue-600',
    },
    green: {
      bg: 'bg-green-50',
      icon: 'bg-green-500 text-white',
      text: 'text-green-600',
    },
    orange: {
      bg: 'bg-orange-50',
      icon: 'bg-orange-500 text-white',
      text: 'text-orange-600',
    },
    red: {
      bg: 'bg-red-50',
      icon: 'bg-red-500 text-white',
      text: 'text-red-600',
    },
    purple: {
      bg: 'bg-purple-50',
      icon: 'bg-purple-500 text-white',
      text: 'text-purple-600',
    },
  }
  const c = colorMap[color] || colorMap.primary

  return (
    <div 
      className={`card p-5 flex items-center gap-4 hover:shadow-card-hover transition-shadow duration-200 ${onClick ? 'cursor-pointer hover:bg-slate-50' : ''}`}
      onClick={onClick}
    >
      <div className={`w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 ${c.icon}`}>
        {Icon && <Icon size={22} />}
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">{title}</p>
        <p className="text-2xl font-bold text-slate-800 leading-tight">{value}</p>
        {subtitle && <p className="text-xs text-slate-400 mt-0.5">{subtitle}</p>}
      </div>
      {trend !== undefined && (
        <div className={`text-xs font-semibold px-2 py-1 rounded-full ${trend >= 0 ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
          {trend >= 0 ? '▲' : '▼'} {Math.abs(trend)}%
        </div>
      )}
    </div>
  )
}

export default StatsCard
