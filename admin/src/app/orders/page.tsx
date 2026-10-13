'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { Header } from '../../components/Header';
import { OrderStatusBadge } from '../../components/Badge';
import { ChangeOrderStatusModal } from '../../components/ChangeOrderStatusModal';
import { fetchAdminOrders, updateOrderStatus } from '../../lib/api';
import { exportOrdersToCSV } from '../../lib/export-excel';
import { Order, OrderStatus } from '../../lib/types';
import {
  ShoppingBag,
  Filter,
  CheckCircle2,
  AlertCircle,
  Truck,
  CreditCard,
  User,
  MapPin,
  Calendar,
  FileSpreadsheet,
  Download,
  Search,
} from 'lucide-react';

const STATUS_TABS: { label: string; value: OrderStatus | 'all' }[] = [
  { label: 'Tất cả đơn', value: 'all' },
  { label: 'Chờ thanh toán', value: 'pending_payment' },
  { label: 'Đã thanh toán', value: 'paid' },
  { label: 'Đang xử lý', value: 'processing' },
  { label: 'Đang giao hàng', value: 'shipping' },
  { label: 'Đã hoàn tất', value: 'completed' },
  { label: 'Đã hủy', value: 'cancelled' },
];

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<OrderStatus | 'all'>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [filterMonth, setFilterMonth] = useState('');
  const [filterDate, setFilterDate] = useState('');

  // Updating status modal
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [newStatus, setNewStatus] = useState<OrderStatus>('processing');
  const [statusNote, setStatusNote] = useState('');
  const [updating, setUpdating] = useState(false);
  const [feedback, setFeedback] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const loadOrders = useCallback(async () => {
    setLoading(true);
    try {
      const data = await fetchAdminOrders(activeTab === 'all' ? undefined : activeTab);
      setOrders(data);
    } finally {
      setLoading(false);
    }
  }, [activeTab]);

  useEffect(() => {
    loadOrders();
  }, [loadOrders]);

  async function handleUpdateStatus() {
    if (!selectedOrder) return;
    if (selectedOrder.status === 'cancelled') {
      setFeedback({ text: 'Đơn hàng đã ở trạng thái ĐÃ HUỶ, không thể chuyển sang trạng thái khác', type: 'error' });
      setSelectedOrder(null);
      return;
    }
    setUpdating(true);
    setFeedback(null);
    try {
      await updateOrderStatus(selectedOrder.id, newStatus, statusNote);
      setFeedback({ text: 'Cập nhật trạng thái đơn hàng thành công!', type: 'success' });
      setOrders((prev) =>
        (Array.isArray(prev) ? prev : []).map((o) =>
          o.id === selectedOrder.id ? { ...o, status: newStatus } : o
        )
      );
      setSelectedOrder(null);
      setStatusNote('');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Lỗi khi cập nhật trạng thái đơn hàng';
      setFeedback({ text: msg, type: 'error' });
    } finally {
      setUpdating(false);
    }
  }

  const filteredOrders = useMemo(() => {
    return (Array.isArray(orders) ? orders : []).filter((o) => {
      // 1. Search filter
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase().trim();
        const codeMatch = (o.code || '').toLowerCase().includes(q);
        const nameMatch = (o.shippingAddress?.name || o.shipName || '').toLowerCase().includes(q);
        const phoneMatch = (o.shippingAddress?.phone || o.shipPhone || '').includes(q);
        const idMatch = (o.id || '').toLowerCase().includes(q);
        if (!codeMatch && !nameMatch && !phoneMatch && !idMatch) return false;
      }
      // 2. Date filter (exact day: YYYY-MM-DD)
      if (filterDate) {
        const oDate = (o.createdAt || '').slice(0, 10);
        if (oDate !== filterDate) return false;
      }
      // 3. Month filter (YYYY-MM)
      if (filterMonth) {
        const oMonth = (o.createdAt || '').slice(0, 7);
        if (oMonth !== filterMonth) return false;
      }
      return true;
    });
  }, [orders, searchQuery, filterDate, filterMonth]);

  const totalFilteredRevenue = useMemo(() => {
    return filteredOrders
      .filter((o) => o.status !== 'cancelled')
      .reduce((sum, o) => sum + (o.total || 0), 0);
  }, [filteredOrders]);

  const handleExportExcel = () => {
    if (filteredOrders.length === 0) {
      setFeedback({ text: 'Không có đơn hàng nào thỏa mãn điều kiện để xuất báo cáo!', type: 'error' });
      return;
    }
    const suffix = filterDate
      ? `Ngay_${filterDate}`
      : filterMonth
      ? `Thang_${filterMonth}`
      : activeTab !== 'all'
      ? `TrangThai_${activeTab}`
      : 'Tat_ca';
    exportOrdersToCSV(filteredOrders, `Bao_cao_don_hang_Menly_${suffix}`);
    setFeedback({
      text: `Đã xuất thành công ${filteredOrders.length} đơn hàng ra file Excel/CSV!`,
      type: 'success',
    });
  };

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Đơn hàng"
        subtitle="Theo dõi và chuyển đổi trạng thái quy trình đơn hàng MenShop"
        onRefresh={loadOrders}
      />

      <div className="p-8 space-y-6 flex-1">
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

          {/* Date & Month Filters */}
          <div className="flex flex-wrap items-center gap-3">
            {/* Filter by exact Day */}
            <div className="flex items-center gap-1.5 bg-slate-50 px-3 py-1.5 rounded-xl border border-slate-200 text-xs">
              <Calendar className="w-3.5 h-3.5 text-amber-600 shrink-0" />
              <span className="text-[11px] text-slate-500">Ngày:</span>
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

            {/* Filter by Month */}
            <div className="flex items-center gap-1.5 bg-slate-50 px-3 py-1.5 rounded-xl border border-slate-200 text-xs">
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
              onClick={handleExportExcel}
              title="Xuất danh sách đơn hàng đã lọc ra file Excel/CSV (UTF-8 tiếng Việt)"
              className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs flex items-center gap-2 transition-all shadow-xs cursor-pointer shrink-0"
            >
              <FileSpreadsheet className="w-4 h-4 stroke-[2.5]" />
              <span>Xuất Báo Cáo Excel/CSV ({filteredOrders.length})</span>
            </button>
          </div>
        </div>

        {/* Summary Mini Bar */}
        <div className="flex items-center justify-between text-xs px-2 text-slate-600">
          <span>
            Hiển thị <strong className="text-slate-900">{filteredOrders.length}</strong> đơn hàng
            {activeTab !== 'all' && ` (trạng thái: ${activeTab})`}
            {filterDate && ` vào ngày ${filterDate}`}
            {filterMonth && ` trong tháng ${filterMonth}`}
          </span>
          <span>
            Doanh thu thực thu:{' '}
            <strong className="text-rose-600 font-mono text-sm font-extrabold">
              {totalFilteredRevenue.toLocaleString('vi-VN')} đ
            </strong>
          </span>
        </div>

        {/* Feedback message */}
        {feedback && (
          <div
            className={`p-3 rounded-xl text-xs font-semibold flex items-center gap-2 ${
              feedback.type === 'success'
                ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                : 'bg-rose-50 text-rose-700 border border-rose-200'
            }`}
          >
            {feedback.type === 'success' ? (
              <CheckCircle2 className="w-4 h-4" />
            ) : (
              <AlertCircle className="w-4 h-4" />
            )}
            <span>{feedback.text}</span>
          </div>
        )}

        {/* Orders list */}
        <div className="space-y-4">
          {loading ? (
            <div className="p-16 text-center text-slate-500 text-sm">Đang tải đơn hàng...</div>
          ) : filteredOrders.length === 0 ? (
            <div className="p-16 text-center text-slate-500 text-sm">
              Không tìm thấy đơn hàng nào ở bộ lọc này
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-4">
              {filteredOrders.map((ord) => (
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
                          <span className="flex items-center gap-1">
                            <Calendar className="w-3 h-3" />
                            {new Date(ord.createdAt).toLocaleString('vi-VN')}
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
                          onClick={() => {
                            setSelectedOrder(ord);
                            setNewStatus(ord.status);
                          }}
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
                      <p className="text-slate-900 font-medium">{ord.shippingAddress.name}</p>
                      <p className="text-slate-500">{ord.shippingAddress.phone}</p>
                    </div>

                    <div className="space-y-1">
                      <span className="text-slate-500 font-semibold flex items-center gap-1">
                        <MapPin className="w-3 h-3 text-slate-400" /> Địa chỉ giao hàng:
                      </span>
                      <p className="text-slate-700 leading-relaxed">{ord.shippingAddress.address}</p>
                      {ord.shippingAddress.note && (
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
                        Gồm {ord.items.length} mặt hàng trong giỏ
                      </p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Change Status Modal */}
      <ChangeOrderStatusModal
        selectedOrder={selectedOrder}
        newStatus={newStatus}
        statusNote={statusNote}
        updating={updating}
        onClose={() => setSelectedOrder(null)}
        onStatusChange={setNewStatus}
        onNoteChange={setStatusNote}
        onSave={handleUpdateStatus}
      />
    </div>
  );
}
