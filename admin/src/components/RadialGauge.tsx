'use client';

import React from 'react';

export interface RadialGaugeProps {
  value: number; // 0 to 100
  title: string;
  subtitle: string;
  statusText?: string;
  size?: number;
}

export function RadialGauge({
  value,
  title,
  subtitle,
  statusText = 'An toàn',
  size = 180,
}: RadialGaugeProps) {
  const strokeWidth = 14;
  const radius = (size - strokeWidth) / 2;
  const semiCircumference = Math.PI * radius;
  const clampedValue = Math.min(100, Math.max(0, value));
  const strokeDashoffset = semiCircumference - (clampedValue / 100) * semiCircumference;

  // Solid Arc Color based on value - NO GRADIENTS
  const solidColor = clampedValue >= 80 ? '#10b981' : clampedValue >= 50 ? '#f59e0b' : '#ef4444';

  return (
    <div className="p-6 rounded-2xl bg-white border border-slate-200 hover:border-slate-300 transition-all duration-300 shadow-2xs flex flex-col items-center text-center">
      <div className="w-full text-left mb-2">
        <h3 className="font-bold text-slate-900 text-base">{title}</h3>
        <p className="text-xs text-slate-500 mt-0.5">{subtitle}</p>
      </div>

      <div className="relative my-2">
        <svg
          width={size}
          height={size / 2 + strokeWidth}
          viewBox={`0 0 ${size} ${size / 2 + strokeWidth}`}
          className="overflow-visible"
        >
          {/* Background Arc */}
          <path
            d={`M ${strokeWidth / 2} ${size / 2} A ${radius} ${radius} 0 0 1 ${size - strokeWidth / 2} ${size / 2}`}
            fill="none"
            stroke="#f1f5f9"
            strokeWidth={strokeWidth}
            strokeLinecap="round"
          />

          {/* Animated Value Arc with SOLID color - NO GRADIENT */}
          <path
            d={`M ${strokeWidth / 2} ${size / 2} A ${radius} ${radius} 0 0 1 ${size - strokeWidth / 2} ${size / 2}`}
            fill="none"
            stroke={solidColor}
            strokeWidth={strokeWidth}
            strokeDasharray={semiCircumference}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            className="transition-all duration-1000 ease-out"
          />
        </svg>

        <div className="absolute inset-x-0 bottom-1 flex flex-col items-center">
          <span className="text-3xl font-black text-slate-900 font-mono tracking-tight">
            {Math.round(clampedValue)}%
          </span>
          <span className="text-[11px] font-bold text-emerald-700 mt-0.5 uppercase tracking-wider">
            {statusText}
          </span>
        </div>
      </div>

      <div className="w-full grid grid-cols-2 gap-2 mt-4 pt-4 border-t border-slate-100 text-xs">
        <div className="p-2 rounded-xl bg-slate-50 border border-slate-200">
          <span className="text-slate-500 text-[11px] font-medium">Tồn khả dụng</span>
          <p className="font-bold text-emerald-700 font-mono text-sm mt-0.5">368 / 375 SKU</p>
        </div>
        <div className="p-2 rounded-xl bg-slate-50 border border-slate-200">
          <span className="text-slate-500 text-[11px] font-medium">Cảnh báo thiếu</span>
          <p className="font-bold text-amber-700 font-mono text-sm mt-0.5">7 SKU (&lt;30)</p>
        </div>
      </div>
    </div>
  );
}
