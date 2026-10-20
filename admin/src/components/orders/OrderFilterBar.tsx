'use client';

import React from 'react';
import { Filter, Search, Calendar, FileSpreadsheet, Clock } from 'lucide-react';
import { OrderStatus } from '../../lib/types';
import { STATUS_TABS } from '../../hooks/useOrders';
import { getVNToday, getVNYesterday, getVNThisMonth } from '../../lib/date-utils';

interface OrderFilterBarProps {
  activeTab: OrderStatus | 'all';
  setActiveTab: (tab: OrderStatus | 'all') => void;
  searchQuery: string;
  setSearchQuery: (query: string) => void;
  filterDate: string;
  setFilterDate: (date: string) => void;
  filterMonth: string;
  setFilterMonth: (month: string) => void;
  filteredCount: number;
  onExportExcel: () => void;
}

export function OrderFilterBar({
  activeTab,
  setActiveTab,
  searchQuery,
  setSearchQuery,
  filterDate,
  setFilterDate,
  filterMonth,
  setFilterMonth,
  filteredCount,
  onExportExcel,
}: OrderFilterBarProps) {
  const vnToday = getVNToday();
  const vnYesterday = getVNYesterday();
  const vnThisMonth = getVNThisMonth();

  const isTodayActive = filterDate === vnToday;
  const isYesterdayActive = filterDate === vnYesterday;
  const isThisMonthActive = filterMonth === vnThisMonth;
  const isAllDatesActive = !filterDate && !filterMonth;

  return (
    <div className="space-y-4">
      {/* Status Filter Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 bg-white p-3 rounded-2xl border border-slate-200 shadow-2xs">
        <Filter className="w-4 h-4 text-slate-500 ml-2 mr-1" />
        {STATUS_TABS.map((tab) => (
          <button
            key={tab.value}
            onClick={() => setActiveTab(tab.value)}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all shrink-0 cursor-pointer ${
              activeTab === tab.value
                ? 'bg-amber-500 text-slate-950 shadow-xs font-bold'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200 hover:text-slate-900'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Search, Date Filter & Excel Export Toolbar */}
      <div className="flex flex-col lg:flex-row items-stretch lg:items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-slate-200 shadow-2xs">
        {/* Search box */}
        <div className="flex items-center gap-2.5 bg-slate-50 px-3.5 py-2 rounded-xl border border-slate-200 flex-1 max-w-md">
          <Search className="w-4 h-4 text-slate-400 shrink-0" />
          <input
            type="text"
            placeholder="Tìm theo mã đơn (#MS...), tên khách, SĐT..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="bg-transparent text-xs text-slate-900 placeholder:text-slate-400 focus:outline-none w-full"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              className="text-slate-400 hover:text-slate-600 text-xs"
            >
              ✕
            </button>
          )}
        </div>

        {/* Date Presets & Pickers */}
        <div className="flex flex-wrap items-center gap-2.5">
          {/* Quick Preset Buttons */}
          <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-xl text-xs">
            <button
              type="button"
              onClick={() => {
                setFilterDate('');
                setFilterMonth('');
              }}
              className={`px-2.5 py-1 rounded-lg text-xs font-medium transition-colors cursor-pointer ${
                isAllDatesActive
                  ? 'bg-white text-slate-900 font-bold shadow-2xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Tất cả
            </button>
            <button
              type="button"
              onClick={() => {
                setFilterDate(vnToday);
                setFilterMonth('');
              }}
              className={`px-2.5 py-1 rounded-lg text-xs font-medium transition-colors cursor-pointer flex items-center gap-1 ${
                isTodayActive
                  ? 'bg-amber-500 text-slate-950 font-bold shadow-2xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Clock className="w-3 h-3" />
              Hôm nay
            </button>
            <button
              type="button"
              onClick={() => {
                setFilterDate(vnYesterday);
                setFilterMonth('');
              }}
              className={`px-2.5 py-1 rounded-lg text-xs font-medium transition-colors cursor-pointer ${
                isYesterdayActive
                  ? 'bg-white text-slate-900 font-bold shadow-2xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Hôm qua
            </button>
            <button
              type="button"
              onClick={() => {
                setFilterMonth(vnThisMonth);
                setFilterDate('');
              }}
              className={`px-2.5 py-1 rounded-lg text-xs font-medium transition-colors cursor-pointer ${
                isThisMonthActive
                  ? 'bg-white text-slate-900 font-bold shadow-2xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Tháng này
            </button>
          </div>

          {/* Filter by exact Day input */}
          <div className="flex items-center gap-1.5 bg-slate-50 px-2.5 py-1.5 rounded-xl border border-slate-200 text-xs">
            <Calendar className="w-3.5 h-3.5 text-amber-600 shrink-0" />
            <input
              type="date"
              value={filterDate}
              onChange={(e) => {
                setFilterDate(e.target.value);
                if (e.target.value) setFilterMonth('');
              }}
              className="bg-transparent text-xs text-slate-800 focus:outline-none cursor-pointer"
            />
            {filterDate && (
              <button
                onClick={() => setFilterDate('')}
                className="text-slate-400 hover:text-slate-600 text-xs ml-1"
              >
                ✕
              </button>
            )}
          </div>

          {/* Filter by Month input */}
          <div className="flex items-center gap-1.5 bg-slate-50 px-2.5 py-1.5 rounded-xl border border-slate-200 text-xs">
            <span className="text-[11px] text-slate-500">Tháng:</span>
            <input
              type="month"
              value={filterMonth}
              onChange={(e) => {
                setFilterMonth(e.target.value);
                if (e.target.value) setFilterDate('');
              }}
              className="bg-transparent text-xs text-slate-800 focus:outline-none cursor-pointer"
            />
            {filterMonth && (
              <button
                onClick={() => setFilterMonth('')}
                className="text-slate-400 hover:text-slate-600 text-xs ml-1"
              >
                ✕
              </button>
            )}
          </div>

          {/* Export Excel / CSV Button */}
          <button
            onClick={onExportExcel}
            title="Xuất danh sách đơn hàng đã lọc ra file Excel/CSV (UTF-8 tiếng Việt)"
            className="px-3.5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs flex items-center gap-1.5 transition-all shadow-xs cursor-pointer shrink-0"
          >
            <FileSpreadsheet className="w-4 h-4 stroke-[2.5]" />
            <span>Xuất Excel ({filteredCount})</span>
          </button>
        </div>
      </div>
    </div>
  );
}
