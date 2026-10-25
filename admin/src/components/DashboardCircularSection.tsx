'use client';

import React, { useState, useMemo } from 'react';
import Link from 'next/link';
import {
  Activity,
  CheckCircle2,
  Clock,
  AlertCircle,
  ChevronRight,
  CreditCard,
  ExternalLink,
  Edit,
  ShoppingBag,
  ArrowRight,
} from 'lucide-react';
import { CircularProgressRing, DonutChart, DonutSegment } from './CircularCharts';
import { Modal } from './Modal';
import { OrderStatusBadge } from './Badge';
import { ChangeOrderStatusModal } from './ChangeOrderStatusModal';
import { updateOrderStatus } from '../lib/api';
import { Order, OrderStatus } from '../lib/types';

export interface DashboardCircularSectionProps {
  orderFulfillmentRate: number;
  completedOrProcessing: number;
  totalOrdersCount: number;
  totalRevenue: number;
  finalDonutSegments: DonutSegment[];
  dateLabel?: string;
  orders?: Order[];
  onOrderUpdated?: () => void;
}

import { formatVNDateTime } from '../lib/date-utils';

function formatVnd(amount: number): string {
  return `${new Intl.NumberFormat('vi-VN').format(amount)} ₫`;
}

function formatDateTime(dateStr: string) {
  return formatVNDateTime(dateStr);
}

export function DashboardCircularSection({
  orderFulfillmentRate: _orderFulfillmentRate,
  completedOrProcessing,
  totalOrdersCount,
  totalRevenue,
  finalDonutSegments,
  dateLabel,
  orders,
  onOrderUpdated,
}: DashboardCircularSectionProps) {
  // Modal states
  const [isUnprocessedModalOpen, setIsUnprocessedModalOpen] = useState(false);
  const [unprocessedFilter, setUnprocessedFilter] = useState<'all' | 'processing' | 'paid' | 'pending_payment'>('all');

  // Change status modal states
  const [statusModalOrder, setStatusModalOrder] = useState<Order | null>(null);
  const [newStatus, setNewStatus] = useState<OrderStatus>('shipping');
  const [statusNote, setStatusNote] = useState('');
  const [updatingStatus, setUpdatingStatus] = useState(false);
  const [, setStatusFeedback] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const fullRevenueVnd = formatVnd(totalRevenue);

  // Group orders if orders list is available
  const hasOrdersList = Array.isArray(orders);
  const orderList = useMemo(() => (hasOrdersList ? orders : []), [hasOrdersList, orders]);

  // Unprocessed orders: pending_payment, paid, processing
  const unprocessedOrders = useMemo(
    () => orderList.filter((o) => ['pending_payment', 'paid', 'processing'].includes(o.status)),
    [orderList]
  );

  // Processed orders: shipping, completed
  const processedOrders = useMemo(
    () => orderList.filter((o) => ['shipping', 'completed'].includes(o.status)),
    [orderList]
  );

  const completedOrders = useMemo(
    () => orderList.filter((o) => o.status === 'completed'),
    [orderList]
  );

  const shippingOrders = useMemo(
    () => orderList.filter((o) => o.status === 'shipping'),
    [orderList]
  );

  const processingOrders = useMemo(
    () => orderList.filter((o) => o.status === 'processing'),
    [orderList]
  );

  const pendingPaymentOrders = useMemo(
    () => orderList.filter((o) => o.status === 'pending_payment'),
    [orderList]
  );

  const paidOrders = useMemo(
    () => orderList.filter((o) => o.status === 'paid'),
    [orderList]
  );

  // Effective metrics
  const effectiveTotal = hasOrdersList ? orderList.length : totalOrdersCount;
  const effectiveProcessed = hasOrdersList ? processedOrders.length : completedOrProcessing;
  const effectiveUnprocessed = hasOrdersList
    ? unprocessedOrders.length
    : Math.max(0, effectiveTotal - effectiveProcessed);

  const processingRate =
    effectiveTotal > 0 ? Math.round((effectiveProcessed / effectiveTotal) * 100) : 0;

  // Revenue breakdown by payment method
  const codOrders = useMemo(
    () => orderList.filter((o) => o.paymentMethod === 'cod'),
    [orderList]
  );
  const vnpayOrders = useMemo(
    () => orderList.filter((o) => o.paymentMethod === 'vnpay'),
    [orderList]
  );

  const codRevenue = useMemo(
    () =>
      codOrders
        .filter((o) => o.status === 'completed' || o.status === 'shipping')
        .reduce((sum, o) => sum + (o.total || 0), 0),
    [codOrders]
  );

  const vnpayRevenue = useMemo(
    () =>
      vnpayOrders
        .filter((o) => o.status !== 'cancelled' && o.status !== 'pending_payment')
        .reduce((sum, o) => sum + (o.total || 0), 0),
    [vnpayOrders]
  );

  const averageOrderValue = useMemo(() => {
    const validOrdersCount = completedOrders.length || orderList.length;
    return validOrdersCount > 0 ? Math.round(totalRevenue / validOrdersCount) : 0;
  }, [completedOrders.length, orderList.length, totalRevenue]);

  // Filtered list inside unprocessed modal
  const filteredUnprocessedList = useMemo(() => {
    if (unprocessedFilter === 'all') return unprocessedOrders;
    return unprocessedOrders.filter((o) => o.status === unprocessedFilter);
  }, [unprocessedOrders, unprocessedFilter]);

  // Handler for updating order status from modal
  async function handleSaveStatus() {
    if (!statusModalOrder) return;
    setUpdatingStatus(true);
    setStatusFeedback(null);
    try {
      await updateOrderStatus(statusModalOrder.id, newStatus, statusNote);
      setStatusFeedback({ text: 'Cập nhật trạng thái đơn hàng thành công!', type: 'success' });
      setStatusModalOrder(null);
      setStatusNote('');
      if (onOrderUpdated) {
        onOrderUpdated();
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Lỗi khi cập nhật trạng thái';
      setStatusFeedback({ text: msg, type: 'error' });
    } finally {
      setUpdatingStatus(false);
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Activity className="w-4 h-4 text-blue-600" />
          <h2 className="text-base font-bold text-slate-900 tracking-tight">
            Chỉ số Vận hành & Cơ cấu Danh mục {dateLabel ? `(${dateLabel})` : ''}
          </h2>
        </div>

        {effectiveUnprocessed > 0 && (
          <button
            type="button"
            onClick={() => setIsUnprocessedModalOpen(true)}
            className="inline-flex items-center gap-1.5 text-xs font-bold text-amber-700 bg-amber-50 hover:bg-amber-100 border border-amber-300 px-3 py-1.5 rounded-xl transition-colors cursor-pointer"
          >
            <Clock className="w-3.5 h-3.5" />
            <span>Có {effectiveUnprocessed} đơn chưa xử lý</span>
          </button>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
        {/* 2 Circular Rings: Tỷ lệ Xử lý Đơn & Doanh thu (5 cols) */}
        <div className="lg:col-span-5 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-1 gap-5">
          {/* Card 1: Tỷ lệ Xử lý Đơn */}
          <CircularProgressRing
            value={processingRate}
            size={180}
            strokeWidth={14}
            title="Tỷ lệ Xử lý Đơn"
            subtitle={
              effectiveTotal > 0
                ? `${effectiveProcessed}/${effectiveTotal} đơn đã xử lý / hoàn tất`
                : '0/0 đơn hàng'
            }
            strokeColor="#2563eb"
            badge={
              effectiveUnprocessed > 0
                ? `${effectiveUnprocessed} đơn chưa xử lý`
                : 'Đã xử lý tất cả'
            }
            badgeVariant={effectiveUnprocessed > 0 ? 'amber' : 'emerald'}
            footer={
              <div className="w-full space-y-2.5">
                {/* 2 stat boxes: Đã xử lý vs Chưa xử lý */}
                <div className="grid grid-cols-2 gap-2 text-xs w-full">
                  {/* Box 1: Đã xử lý */}
                  <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200 text-left">
                    <span className="text-slate-500 text-[11px] font-medium flex items-center gap-1">
                      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                      Đã xử lý
                    </span>
                    <p className="font-bold text-emerald-700 font-mono text-sm mt-0.5">
                      {effectiveProcessed} / {effectiveTotal} đơn
                    </p>
                    <span className="text-[10px] text-slate-400 block mt-0.5 truncate">
                      {completedOrders.length} xong • {shippingOrders.length} đang giao
                    </span>
                  </div>

                  {/* Box 2: Chưa xử lý */}
                  <div
                    onClick={() => setIsUnprocessedModalOpen(true)}
                    className={`p-2.5 rounded-xl border text-left transition-all cursor-pointer ${
                      effectiveUnprocessed > 0
                        ? 'bg-amber-50/80 border-amber-300 hover:bg-amber-100/80 shadow-2xs'
                        : 'bg-slate-50 border-slate-200 hover:bg-slate-100/70'
                    }`}
                    title="Nhấp để xem danh sách chi tiết các đơn chưa xử lý"
                  >
                    <span className="text-slate-500 text-[11px] font-medium flex items-center justify-between">
                      <span className="flex items-center gap-1">
                        <Clock
                          className={`w-3.5 h-3.5 ${
                            effectiveUnprocessed > 0 ? 'text-amber-600' : 'text-slate-400'
                          }`}
                        />
                        Chưa xử lý
                      </span>
                      <span className="text-[10px] text-blue-600 hover:underline font-semibold">
                        Chi tiết
                      </span>
                    </span>
                    <p
                      className={`font-bold font-mono text-sm mt-0.5 ${
                        effectiveUnprocessed > 0 ? 'text-amber-700 font-black' : 'text-slate-700'
                      }`}
                    >
                      {effectiveUnprocessed} đơn
                    </p>
                    <span className="text-[10px] text-slate-400 block mt-0.5 truncate">
                      {effectiveUnprocessed > 0
                        ? `${processingOrders.length} đang xử lý • ${
                            paidOrders.length + pendingPaymentOrders.length
                          } chờ duyệt`
                        : 'Không có đơn tồn'}
                    </span>
                  </div>
                </div>

                {/* Quick action button when there are unprocessed orders */}
                {effectiveUnprocessed > 0 && (
                  <button
                    type="button"
                    onClick={() => setIsUnprocessedModalOpen(true)}
                    className="w-full py-2 px-3 rounded-xl bg-amber-500 hover:bg-amber-600 text-white text-xs font-bold flex items-center justify-center gap-1.5 transition-colors shadow-2xs cursor-pointer"
                  >
                    <AlertCircle className="w-3.5 h-3.5" />
                    <span>Xem {effectiveUnprocessed} đơn chưa xử lý</span>
                    <ChevronRight className="w-3.5 h-3.5 ml-auto" />
                  </button>
                )}
              </div>
            }
          />

          {/* Card 2: Doanh thu Thực thu */}
          <CircularProgressRing
            value={totalRevenue > 0 ? 100 : 0}
            size={180}
            strokeWidth={14}
            title={dateLabel ? `Doanh thu Thực thu (${dateLabel})` : 'Doanh thu Thực thu'}
            subtitle={`Tổng thực thu: ${fullRevenueVnd}`}
            valueDisplay={fullRevenueVnd}
            strokeColor="#059669"
            badge="Thực thu"
            badgeVariant="emerald"
            footer={
              <div className="w-full space-y-2.5">
                <div className="grid grid-cols-2 gap-2 text-xs w-full">
                  <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200 text-left">
                    <span className="text-slate-500 text-[11px] font-medium flex items-center gap-1">
                      <CreditCard className="w-3.5 h-3.5 text-blue-600" />
                      Thu COD
                    </span>
                    <p className="font-bold text-slate-800 font-mono text-sm mt-0.5 truncate">
                      {formatVnd(codRevenue)}
                    </p>
                    <span className="text-[10px] text-slate-400 block mt-0.5 truncate">
                      {codOrders.length} đơn tiền mặt
                    </span>
                  </div>

                  <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200 text-left">
                    <span className="text-slate-500 text-[11px] font-medium flex items-center gap-1">
                      <CreditCard className="w-3.5 h-3.5 text-emerald-600" />
                      Qua VNPay
                    </span>
                    <p className="font-bold text-emerald-700 font-mono text-sm mt-0.5 truncate">
                      {formatVnd(vnpayRevenue)}
                    </p>
                    <span className="text-[10px] text-slate-400 block mt-0.5 truncate">
                      {vnpayOrders.length} đơn trực tuyến
                    </span>
                  </div>
                </div>

                <div className="py-1.5 px-3 rounded-xl bg-slate-50 text-slate-600 text-[11px] font-medium flex items-center justify-between border border-slate-200">
                  <span>Giá trị TB / đơn (AOV):</span>
                  <span className="font-bold text-slate-900 font-mono">
                    {formatVnd(averageOrderValue)}
                  </span>
                </div>
              </div>
            }
          />
        </div>

        {/* Cơ cấu danh mục (Donut Chart) (7 cols) */}
        <div className="lg:col-span-7 flex flex-col">
          <DonutChart
            title="Phân bổ Cơ cấu Danh mục Sản phẩm"
            subtitle="Tỷ trọng 400 sản phẩm phân bổ đều qua 5 danh mục thời trang nam"
            segments={finalDonutSegments}
            totalLabel="400 SP"
            size={190}
            thickness={24}
          />
        </div>
      </div>

      {/* Modal: Danh sách những đơn chưa xử lý */}
      <Modal
        isOpen={isUnprocessedModalOpen}
        onClose={() => setIsUnprocessedModalOpen(false)}
        title={`Đơn hàng chưa xử lý (${unprocessedOrders.length})`}
      >
        <div className="space-y-4">
          <p className="text-xs text-slate-500">
            Danh sách các đơn hàng ở trạng thái <strong>Chờ thanh toán</strong>,{' '}
            <strong>Đã thanh toán</strong> hoặc <strong>Đang xử lý</strong> cần cửa hàng chuẩn bị,
            đóng gói và bàn giao vận chuyển.
          </p>

          {/* Quick status tabs inside modal */}
          {unprocessedOrders.length > 0 && (
            <div className="flex flex-wrap items-center gap-1.5 text-xs border-b border-slate-200 pb-3">
              <button
                type="button"
                onClick={() => setUnprocessedFilter('all')}
                className={`px-3 py-1 rounded-lg font-medium transition-colors cursor-pointer ${
                  unprocessedFilter === 'all'
                    ? 'bg-blue-600 text-white font-bold'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                Tất cả ({unprocessedOrders.length})
              </button>
              <button
                type="button"
                onClick={() => setUnprocessedFilter('processing')}
                className={`px-3 py-1 rounded-lg font-medium transition-colors cursor-pointer ${
                  unprocessedFilter === 'processing'
                    ? 'bg-blue-600 text-white font-bold'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                Đang xử lý ({processingOrders.length})
              </button>
              <button
                type="button"
                onClick={() => setUnprocessedFilter('paid')}
                className={`px-3 py-1 rounded-lg font-medium transition-colors cursor-pointer ${
                  unprocessedFilter === 'paid'
                    ? 'bg-blue-600 text-white font-bold'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                Đã thanh toán ({paidOrders.length})
              </button>
              <button
                type="button"
                onClick={() => setUnprocessedFilter('pending_payment')}
                className={`px-3 py-1 rounded-lg font-medium transition-colors cursor-pointer ${
                  unprocessedFilter === 'pending_payment'
                    ? 'bg-blue-600 text-white font-bold'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                Chờ thanh toán ({pendingPaymentOrders.length})
              </button>
            </div>
          )}

          {/* Table or Empty State */}
          {unprocessedOrders.length === 0 ? (
            <div className="py-12 flex flex-col items-center justify-center text-center gap-3">
              <div className="w-12 h-12 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center">
                <CheckCircle2 className="w-6 h-6" />
              </div>
              <h3 className="text-base font-bold text-slate-900">
                Không có đơn hàng nào chưa xử lý!
              </h3>
              <p className="text-xs text-slate-500 max-w-sm">
                Tất cả đơn hàng hiện tại đều đã được đóng gói giao hàng hoặc hoàn tất thành công.
              </p>
              <Link
                href="/orders"
                className="mt-2 inline-flex items-center gap-1.5 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-xl transition-colors shadow-2xs"
              >
                <ShoppingBag className="w-3.5 h-3.5" />
                <span>Xem toàn bộ đơn hàng trong hệ thống</span>
              </Link>
            </div>
          ) : filteredUnprocessedList.length === 0 ? (
            <div className="py-8 text-center text-slate-500 text-xs">
              Không có đơn nào phù hợp với bộ lọc trạng thái đã chọn.
            </div>
          ) : (
            <div className="overflow-x-auto max-h-[380px] overflow-y-auto border border-slate-200 rounded-xl">
              <table className="w-full text-left text-xs min-w-[620px]">
                <thead className="bg-slate-50 sticky top-0 border-b border-slate-200 text-slate-600 font-bold uppercase tracking-wider text-[11px]">
                  <tr>
                    <th className="py-2.5 px-3 text-left whitespace-nowrap">Mã đơn</th>
                    <th className="py-2.5 px-3 text-left whitespace-nowrap">Thời gian</th>
                    <th className="py-2.5 px-3 text-left whitespace-nowrap">Khách hàng</th>
                    <th className="py-2.5 px-3 text-center whitespace-nowrap">Thanh toán</th>
                    <th className="py-2.5 px-3 text-right whitespace-nowrap">Tổng tiền</th>
                    <th className="py-2.5 px-3 text-center whitespace-nowrap">Trạng thái</th>
                    <th className="py-2.5 px-3 text-center whitespace-nowrap">Thao tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {filteredUnprocessedList.map((ord) => {
                    const { time, date } = formatDateTime(ord.createdAt);
                    const customerName =
                      ord.shippingAddress?.name || ord.shipName || 'Khách vãng lai';
                    const customerPhone = ord.shippingAddress?.phone || ord.shipPhone || 'N/A';

                    return (
                      <tr key={ord.id} className="hover:bg-slate-50/80 transition-colors">
                        <td className="py-2.5 px-3 font-mono font-bold text-sky-700 whitespace-nowrap">
                          #{ord.code}
                        </td>
                        <td className="py-2.5 px-3 whitespace-nowrap">
                          <span className="font-semibold text-slate-800">{time}</span>
                          <span className="text-[10px] text-slate-400 block">{date}</span>
                        </td>
                        <td className="py-2.5 px-3 min-w-[120px]">
                          <p className="font-semibold text-slate-800 truncate max-w-[140px]">{customerName}</p>
                          <p className="text-[10px] text-slate-500 font-mono whitespace-nowrap">{customerPhone}</p>
                        </td>
                        <td className="py-2.5 px-3 text-center whitespace-nowrap">
                          <span
                            className={`inline-block px-2 py-0.5 rounded text-[10px] font-bold uppercase whitespace-nowrap ${
                              ord.paymentMethod === 'vnpay'
                                ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                : 'bg-slate-100 text-slate-700 border border-slate-200'
                            }`}
                          >
                            {ord.paymentMethod === 'vnpay' ? 'VNPay' : 'COD'}
                          </span>
                        </td>
                        <td className="py-2.5 px-3 text-right font-mono font-bold text-slate-900 whitespace-nowrap">
                          {formatVnd(ord.total)}
                        </td>
                        <td className="py-2.5 px-3 text-center whitespace-nowrap">
                          <OrderStatusBadge status={ord.status} />
                        </td>
                        <td className="py-2.5 px-3 text-center whitespace-nowrap">
                          <div className="flex items-center justify-center gap-1.5 whitespace-nowrap">
                            <button
                              type="button"
                              onClick={() => {
                                setStatusModalOrder(ord);
                                setNewStatus(
                                  ord.status === 'processing'
                                    ? 'shipping'
                                    : ord.status === 'paid'
                                    ? 'processing'
                                    : 'processing'
                                );
                              }}
                              className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-blue-50 hover:bg-blue-100 text-blue-700 border border-blue-200 rounded-lg text-xs font-semibold whitespace-nowrap transition-colors cursor-pointer shadow-xs"
                              title="Xử lý / Cập nhật trạng thái"
                            >
                              <Edit className="w-3.5 h-3.5 shrink-0" />
                              <span className="whitespace-nowrap">Xử lý</span>
                            </button>
                            <Link
                              href="/orders"
                              className="p-1.5 text-slate-400 hover:text-slate-600 transition-colors"
                              title="Xem chi tiết trên trang Quản lý đơn hàng"
                            >
                              <ExternalLink className="w-3.5 h-3.5" />
                            </Link>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}

          {/* Modal bottom actions */}
          <div className="pt-3 border-t border-slate-200 flex items-center justify-between">
            <span className="text-xs text-slate-500">
              {unprocessedOrders.length > 0
                ? `Tổng giá trị cần thu: ${formatVnd(
                    unprocessedOrders.reduce((sum, o) => sum + (o.total || 0), 0)
                  )}`
                : 'Hệ thống đã đồng bộ'}
            </span>

            <div className="flex items-center gap-2">
              <Link
                href="/orders"
                className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-semibold text-slate-700 bg-white hover:bg-slate-50 border border-slate-300 rounded-xl transition-colors shadow-2xs"
              >
                <span>Mở trang Đơn hàng</span>
                <ArrowRight className="w-3.5 h-3.5 text-slate-500" />
              </Link>
              <button
                type="button"
                onClick={() => setIsUnprocessedModalOpen(false)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold rounded-xl transition-colors cursor-pointer"
              >
                Đóng
              </button>
            </div>
          </div>
        </div>
      </Modal>

      {/* Change order status modal */}
      {statusModalOrder && (
        <ChangeOrderStatusModal
          selectedOrder={statusModalOrder}
          newStatus={newStatus}
          statusNote={statusNote}
          updating={updatingStatus}
          onClose={() => setStatusModalOrder(null)}
          onStatusChange={setNewStatus}
          onNoteChange={setStatusNote}
          onSave={handleSaveStatus}
        />
      )}
    </div>
  );
}
