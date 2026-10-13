'use client';

import React from 'react';

export interface CircularProgressRingProps {
  value: number; // 0 to 100
  size?: number;
  strokeWidth?: number;
  title: string;
  subtitle: string;
  valueDisplay?: string;
  gradientFrom?: string; // Kept for backwards-compatibility; will use as solid stroke color
  gradientTo?: string;
  strokeColor?: string;
  badge?: string;
  badgeVariant?: 'emerald' | 'amber' | 'blue' | 'rose';
  footer?: React.ReactNode;
}

const BADGE_STYLES = {
  emerald: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  amber: 'bg-amber-50 text-amber-700 border-amber-200',
  rose: 'bg-rose-50 text-rose-700 border-rose-200',
  blue: 'bg-blue-50 text-blue-700 border-blue-200',
};

export function CircularProgressRing({
  value,
  size = 180,
  strokeWidth = 14,
  title,
  subtitle,
  valueDisplay,
  gradientFrom = '#f59e0b',
  strokeColor,
  badge,
  badgeVariant = 'emerald',
  footer,
}: CircularProgressRingProps) {
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const clampedValue = Math.min(100, Math.max(0, value));
  const strokeDashoffset = circumference - (clampedValue / 100) * circumference;

  // Solid stroke color - NO GRADIENT
  const solidColor = strokeColor || gradientFrom || '#f59e0b';

  return (
    <div className="flex flex-col items-center justify-between p-5 rounded-2xl bg-white border border-slate-200 hover:border-slate-300 transition-all duration-300 shadow-2xs relative group h-full">
      {badge && (
        <span
          className={`absolute top-4 right-4 text-[10px] font-bold px-2 py-0.5 rounded-full border ${
            BADGE_STYLES[badgeVariant] || BADGE_STYLES.emerald
          }`}
        >
          {badge}
        </span>
      )}

      <div className="w-full text-left mb-3">
        <h4 className="text-xs font-bold text-slate-500 uppercase tracking-wider">{title}</h4>
      </div>

      <div className="relative flex items-center justify-center my-2">
        <svg width={size} height={size} className="rotate-[-90deg] transition-all">
          {/* Background circle track */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke="#f1f5f9"
            strokeWidth={strokeWidth}
            fill="transparent"
          />

          {/* Animated Value circle with SOLID stroke color - NO GRADIENT */}
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke={solidColor}
            strokeWidth={strokeWidth}
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            fill="transparent"
            className="transition-all duration-1000 ease-out"
          />
        </svg>

        {/* Center Text */}
        <div className="absolute inset-0 flex flex-col items-center justify-center text-center px-2">
          <span
            className={`font-black text-slate-900 tracking-tight font-mono whitespace-nowrap ${
              (valueDisplay?.length || 0) > 10
                ? 'text-base sm:text-lg'
                : (valueDisplay?.length || 0) > 6
                ? 'text-lg sm:text-xl'
                : 'text-2xl sm:text-3xl'
            }`}
          >
            {valueDisplay || `${Math.round(clampedValue)}%`}
          </span>
        </div>
      </div>

      <p className="text-xs text-slate-500 text-center mt-2 leading-relaxed font-medium">{subtitle}</p>

      {footer && <div className="w-full mt-4 pt-3.5 border-t border-slate-100">{footer}</div>}
    </div>
  );
}
