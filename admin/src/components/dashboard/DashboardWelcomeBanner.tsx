'use client';

import React from 'react';
import Link from 'next/link';
import { RefreshCw, Boxes, ShoppingBag, Plus } from 'lucide-react';
import { POLL_INTERVAL_MS } from '../../hooks/useDashboard';

interface DashboardWelcomeBannerProps {
  isRefreshing: boolean;
  onRefresh: () => void;
}

export function DashboardWelcomeBanner({ isRefreshing, onRefresh }: DashboardWelcomeBannerProps) {
  return (
    <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-2xs">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2.5">
            <h2 className="text-xl font-bold text-slate-900 tracking-tight">
              Chào mừng trở lại Quản trị viên
            </h2>
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse motion-reduce:animate-none"></span>
              Trực tiếp {POLL_INTERVAL_MS / 1000}s
            </span>
          </div>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Theo dõi hiệu suất doanh thu, lưu lượng đơn hàng và chỉ số kho vận thời trang nam theo thời gian thực
          </p>
        </div>

        <div className="flex items-center flex-wrap gap-2.5">
          <button
            type="button"
            onClick={onRefresh}
            disabled={isRefreshing}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 border border-slate-200 rounded-xl transition-colors cursor-pointer disabled:opacity-60 focus-visible:outline-2 focus-visible:outline-blue-600"
            title="Làm mới dữ liệu từ server"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin text-blue-600' : ''}`} />
            Làm mới
          </button>

          <Link
            href="/inventory"
            className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-semibold text-slate-700 bg-white hover:bg-slate-50 border border-slate-300 rounded-xl transition-colors shadow-2xs"
          >
            <Boxes className="w-3.5 h-3.5 text-slate-500" />
            Kho hàng
          </Link>

          <Link
            href="/orders"
            className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-semibold text-slate-700 bg-white hover:bg-slate-50 border border-slate-300 rounded-xl transition-colors shadow-2xs"
          >
            <ShoppingBag className="w-3.5 h-3.5 text-slate-500" />
            Đơn hàng
          </Link>

          <Link
            href="/products"
            className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-xl transition-colors shadow-2xs cursor-pointer"
          >
            <Plus className="w-3.5 h-3.5" />
            Thêm sản phẩm
          </Link>
        </div>
      </div>
    </div>
  );
}
