'use client';

import React from 'react';
import { Calendar, Filter, RotateCcw } from 'lucide-react';

export type DateFilterPreset = 'all' | 'today' | 'yesterday' | '7days' | '30days' | 'custom_day' | 'custom_range';

interface DashboardDateFilterProps {
  preset: DateFilterPreset;
  customDay: string;
  fromDay: string;
  toDay: string;
  onPresetChange: (preset: DateFilterPreset) => void;
  onCustomDayChange: (day: string) => void;
  onRangeChange: (from: string, to: string) => void;
  onReset: () => void;
  ordersCount: number;
  revenue: number;
}

export function DashboardDateFilter({
  preset,
  customDay,
  fromDay,
  toDay,
  onPresetChange,
  onCustomDayChange,
  onRangeChange,
  onReset,
  ordersCount,
  revenue,
}: DashboardDateFilterProps) {
  const formattedRevenue = `${new Intl.NumberFormat('vi-VN').format(revenue)} ₫`;

  const presetButtons: { label: string; value: DateFilterPreset }[] = [
    { label: 'Tất cả', value: 'all' },
    { label: 'Hôm nay', value: 'today' },
    { label: 'Hôm qua', value: 'yesterday' },
    { label: '7 ngày qua', value: '7days' },
    { label: '30 ngày qua', value: '30days' },
  ];

  return (
    <div className="bg-white border border-slate-200 rounded-2xl p-5 space-y-4 shadow-2xs">
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        {/* Title & Presets */}
        <div className="flex flex-wrap items-center gap-2">
          <div className="flex items-center gap-2 text-slate-700 font-bold text-xs mr-2">
            <Filter className="w-4 h-4 text-blue-600" />
            <span>Lọc ngày:</span>
          </div>

          {presetButtons.map((btn) => (
            <button
              key={btn.value}
              type="button"
              onClick={() => onPresetChange(btn.value)}
              className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
                preset === btn.value
                  ? 'bg-blue-600 text-white font-bold shadow-2xs'
                  : 'bg-slate-100 text-slate-600 hover:text-slate-900 hover:bg-slate-200 border border-slate-200'
              }`}
            >
              {btn.label}
            </button>
          ))}
        </div>

        {/* Live Filter Result Summary */}
        <div className="flex items-center gap-3 bg-slate-50 border border-slate-200 px-4 py-2 rounded-xl text-xs">
          <span className="text-slate-500 font-medium">Kết quả lọc:</span>
          <span className="font-bold text-blue-700 font-mono">{ordersCount} đơn</span>
          <span className="text-slate-300">|</span>
          <span className="font-extrabold text-rose-600 font-mono">{formattedRevenue}</span>
        </div>
      </div>

      {/* Custom Date Pickers */}
      <div className="pt-3 border-t border-slate-100 flex flex-wrap items-center gap-4 text-xs">
        {/* Single specific date picker */}
        <div className="flex items-center gap-2">
          <span className="text-slate-600 flex items-center gap-1.5 font-medium">
            <Calendar className="w-3.5 h-3.5 text-blue-600" />
            Chọn ngày cụ thể:
          </span>
          <input
            type="date"
            value={customDay}
            onChange={(e) => onCustomDayChange(e.target.value)}
            className={`px-2.5 py-1.5 rounded-xl bg-white border text-slate-800 font-mono text-xs focus:outline-none focus:border-blue-500 ${
              preset === 'custom_day' ? 'border-blue-500 text-blue-700 font-bold' : 'border-slate-300'
            }`}
          />
        </div>

        {/* Date range picker */}
        <div className="flex items-center gap-2">
          <span className="text-slate-600 font-medium">Khoảng ngày:</span>
          <input
            type="date"
            value={fromDay}
            onChange={(e) => onRangeChange(e.target.value, toDay)}
            className={`px-2 py-1.5 rounded-xl bg-white border text-slate-800 font-mono text-xs focus:outline-none focus:border-blue-500 ${
              preset === 'custom_range' ? 'border-blue-500 font-semibold' : 'border-slate-300'
            }`}
          />
          <span className="text-slate-400">-</span>
          <input
            type="date"
            value={toDay}
            onChange={(e) => onRangeChange(fromDay, e.target.value)}
            className={`px-2 py-1.5 rounded-xl bg-white border text-slate-800 font-mono text-xs focus:outline-none focus:border-blue-500 ${
              preset === 'custom_range' ? 'border-blue-500 font-semibold' : 'border-slate-300'
            }`}
          />
        </div>

        {/* Reset button if not all */}
        {preset !== 'all' && (
          <button
            type="button"
            onClick={onReset}
            className="flex items-center gap-1 px-3 py-1.5 rounded-xl text-slate-600 hover:text-blue-700 bg-slate-100 hover:bg-blue-50 border border-slate-200 transition-colors ml-auto cursor-pointer text-xs font-medium"
            title="Xem tất cả ngày"
          >
            <RotateCcw className="w-3 h-3" />
            <span>Mặc định (Tất cả)</span>
          </button>
        )}
      </div>
    </div>
  );
}
