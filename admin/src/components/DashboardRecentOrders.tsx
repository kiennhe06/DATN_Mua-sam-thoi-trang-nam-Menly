'use client';

import React from 'react';
import Link from 'next/link';
import { OrderStatusBadge } from './Badge';
import { Order } from '../lib/types';
import { ShoppingBag, ArrowRight, Clock, MapPin, CreditCard, ChevronRight } from 'lucide-react';

interface DashboardRecentOrdersProps {
  orders: Order[];
  productsCount?: number;
  totalRevenue?: number;
  loading: boolean;
  hideStats?: boolean;
}

import { formatVNDateTime } from '../lib/date-utils';

function formatOrderDateTime(dateStr: string) {
  return formatVNDateTime(dateStr);
}

export function DashboardRecentOrders({
  orders,
  loading,
}: DashboardRecentOrdersProps) {
  const recentOrders = orders.slice(0, 8);

  return (
    <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-2xs">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-5">
        <div>
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 rounded-lg bg-sky-50 text-sky-700 border border-sky-200 flex items-center justify-center">
              <ShoppingBag className="w-4 h-4" />
            </div>
            <h2 className="text-base font-bold text-slate-900">Đơn hàng mới nhất</h2>
            <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 border border-slate-200">
              {recentOrders.length}/{orders.length} đơn
            </span>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Giao dịch phát sinh theo thời gian thực từ ứng dụng di động Flutter và website
          </p>
        </div>

        <Link
          href="/orders"
          className="inline-flex items-center gap-1.5 text-xs text-blue-700 hover:text-blue-800 font-bold px-3 py-1.5 rounded-xl bg-blue-50/70 hover:bg-blue-100/70 border border-blue-200/80 transition-colors w-fit"
        >
          Xem tất cả đơn hàng <ArrowRight className="w-3.5 h-3.5" />
        </Link>
      </div>

      {loading ? (
        <div className="py-16 text-center text-slate-400 text-sm flex flex-col items-center justify-center gap-2">
          <div className="w-6 h-6 border-2 border-blue-600 border-t-transparent rounded-full animate-spin" />
          <span>Đang đồng bộ dữ liệu đơn hàng...</span>
        </div>
      ) : orders.length === 0 ? (
        <div className="py-16 text-center text-slate-400 text-sm flex flex-col items-center justify-center gap-2">
          <ShoppingBag className="w-8 h-8 text-slate-300" />
          <p className="font-medium text-slate-600">Chưa có đơn hàng nào trong khoảng thời gian này</p>
          <p className="text-xs text-slate-400">Đơn hàng mới sẽ tự động hiển thị khi khách hàng hoàn tất thanh toán</p>
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm min-w-[760px]">
            <thead>
              <tr className="border-b border-slate-200 text-xs text-slate-500 uppercase tracking-wider font-bold bg-slate-50/80">
                <th className="py-3 px-3.5">Mã đơn</th>
                <th className="py-3 px-3.5">Thời gian</th>
                <th className="py-3 px-3.5">Khách hàng</th>
                <th className="py-3 px-3.5">Địa chỉ giao</th>
                <th className="py-3 px-3.5">Thanh toán</th>
                <th className="py-3 px-3.5 text-right">Tổng tiền</th>
                <th className="py-3 px-3.5 text-center">Trạng thái</th>
                <th className="py-3 px-3.5 text-center">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {recentOrders.map((ord) => {
                const { time, date } = formatOrderDateTime(ord.createdAt);
                const customerName = ord.shippingAddress?.name || ord.shipName || 'Khách vãng lai';
                const customerPhone = ord.shippingAddress?.phone || ord.shipPhone || 'N/A';
                const destination = ord.shippingAddress?.address || ord.shipAddress || 'Địa chỉ tiêu chuẩn';

                return (
                  <tr key={ord.id} className="hover:bg-slate-50/80 transition-colors group">
                    {/* Mã đơn */}
                    <td className="py-3 px-3.5">
                      <span className="font-mono font-bold text-sky-700 text-xs bg-sky-50 px-2 py-1 rounded-md border border-sky-200/80 group-hover:border-sky-300">
                        #{ord.code}
                      </span>
                    </td>

                    {/* Thời gian */}
                    <td className="py-3 px-3.5 whitespace-nowrap text-xs text-slate-500">
                      <div className="flex items-center gap-1.5 font-medium text-slate-700">
                        <Clock className="w-3 h-3 text-slate-400" />
                        <span>{time}</span>
                      </div>
                      <span className="text-[11px] text-slate-400 font-mono">{date}</span>
                    </td>

                    {/* Khách hàng */}
                    <td className="py-3 px-3.5">
                      <p className="font-semibold text-slate-900 text-xs">{customerName}</p>
                      <p className="text-[11px] text-slate-400 font-mono mt-0.5">{customerPhone}</p>
                    </td>

                    {/* Địa chỉ */}
                    <td className="py-3 px-3.5 max-w-[200px]">
                      <div className="flex items-center gap-1 text-slate-600 text-xs truncate" title={destination}>
                        <MapPin className="w-3 h-3 text-slate-400 shrink-0" />
                        <span className="truncate">{destination}</span>
                      </div>
                    </td>

                    {/* Phương thức thanh toán */}
                    <td className="py-3 px-3.5 whitespace-nowrap">
                      <span
                        className={`inline-flex items-center gap-1 text-[11px] font-bold px-2 py-0.5 rounded-full border ${
                          ord.paymentMethod === 'vnpay'
                            ? 'bg-indigo-50 text-indigo-700 border-indigo-200'
                            : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                        }`}
                      >
                        <CreditCard className="w-3 h-3" />
                        {ord.paymentMethod === 'vnpay' ? 'VNPay' : 'COD'}
                      </span>
                    </td>

                    {/* Tổng tiền */}
                    <td className="py-3 px-3.5 text-right font-bold text-slate-900 font-mono whitespace-nowrap">
                      {ord.total.toLocaleString('vi-VN')} ₫
                    </td>

                    {/* Trạng thái */}
                    <td className="py-3 px-3.5 text-center whitespace-nowrap">
                      <OrderStatusBadge status={ord.status} />
                    </td>

                    {/* Thao tác */}
                    <td className="py-3 px-3.5 text-center whitespace-nowrap">
                      <Link
                        href={`/orders?search=${ord.code}`}
                        className="inline-flex items-center gap-1 text-xs font-semibold text-slate-600 hover:text-blue-700 hover:bg-slate-100 px-2 py-1 rounded-lg transition-colors"
                        title="Xem chi tiết đơn hàng"
                      >
                        Chi tiết <ChevronRight className="w-3 h-3" />
                      </Link>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
