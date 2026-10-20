'use client';

import React from 'react';
import { ShoppingBag, Calendar, AlertCircle, Truck, User, MapPin, CreditCard } from 'lucide-react';
import { Order } from '../../lib/types';
import { OrderStatusBadge } from '../Badge';
import { formatVNDateTime } from '../../lib/date-utils';

interface OrdersTableProps {
  orders: Order[];
  loading: boolean;
  onOpenStatusModal: (order: Order) => void;
}

export function OrdersTable({ orders, loading, onOpenStatusModal }: OrdersTableProps) {
  if (loading) {
    return <div className="p-16 text-center text-slate-500 text-sm">Đang tải đơn hàng...</div>;
  }

  if (orders.length === 0) {
    return (
      <div className="p-16 text-center text-slate-500 text-sm">
        Không tìm thấy đơn hàng nào ở bộ lọc này
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 gap-4">
      {orders.map((ord) => (
        <div
          key={ord.id}
          className="bg-white border border-slate-200 rounded-2xl p-5 hover:border-slate-300 hover:shadow-xs transition-all space-y-4 shadow-2xs"
        >
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-100">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-amber-50 border border-amber-200 flex items-center justify-center text-amber-600 font-bold">
                <ShoppingBag className="w-5 h-5" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <span className="font-mono font-bold text-slate-900 text-sm">#{ord.code}</span>
                  <OrderStatusBadge status={ord.status} />
                </div>
                <div className="flex items-center gap-3 text-[11px] text-slate-500 mt-0.5">
                  <span className="flex items-center gap-1 font-medium">
                    <Calendar className="w-3 h-3 text-amber-600" />
                    {formatVNDateTime(ord.createdAt).full}
                  </span>
                  <span>•</span>
                  <span className="font-mono text-slate-500">ID: {ord.id.slice(0, 8)}...</span>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <span className="text-base font-extrabold text-slate-900 font-mono">
                {ord.total.toLocaleString('vi-VN')} đ
              </span>
              {ord.status === 'cancelled' ? (
                <span className="px-3 py-1.5 rounded-xl text-xs font-semibold bg-rose-50 text-rose-600 border border-rose-200 flex items-center gap-1.5 cursor-not-allowed">
                  <AlertCircle className="w-3.5 h-3.5" />
                  Đã huỷ (Cố định)
                </span>
              ) : (
                <button
                  onClick={() => onOpenStatusModal(ord)}
                  className="px-3 py-1.5 rounded-xl text-xs font-semibold bg-slate-100 hover:bg-slate-200 text-slate-800 border border-slate-200 transition-all flex items-center gap-1.5 cursor-pointer"
                >
                  <Truck className="w-3.5 h-3.5" />
                  Đổi trạng thái
                </button>
              )}
            </div>
          </div>

          {/* Customer info & Item list */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-3 border-t border-slate-100 text-xs">
            <div className="space-y-1">
              <span className="text-slate-500 font-semibold flex items-center gap-1">
                <User className="w-3 h-3 text-slate-400" /> Người nhận:
              </span>
              <p className="text-slate-900 font-medium">{ord.shippingAddress?.name || ord.shipName || 'Khách vãng lai'}</p>
              <p className="text-slate-500">{ord.shippingAddress?.phone || ord.shipPhone || '---'}</p>
            </div>

            <div className="space-y-1">
              <span className="text-slate-500 font-semibold flex items-center gap-1">
                <MapPin className="w-3 h-3 text-slate-400" /> Địa chỉ giao hàng:
              </span>
              <p className="text-slate-700 leading-relaxed">{ord.shippingAddress?.address || ord.shipAddress || 'Tại quầy'}</p>
              {ord.shippingAddress?.note && (
                <p className="text-amber-600 text-[11px]">
                  * Ghi chú: {ord.shippingAddress.note}
                </p>
              )}
            </div>

            <div className="space-y-1">
              <span className="text-slate-500 font-semibold flex items-center gap-1">
                <CreditCard className="w-3 h-3 text-slate-400" /> Thanh toán:
              </span>
              <p className="text-slate-900 uppercase font-semibold">
                {ord.paymentMethod === 'vnpay' ? 'Thanh toán trực tuyến VNPay' : 'Thanh toán khi nhận hàng (COD)'}
              </p>
              <p className="text-slate-500 text-[11px]">
                Gồm {ord.items?.length || 0} mặt hàng trong giỏ
              </p>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
