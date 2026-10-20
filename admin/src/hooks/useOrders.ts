'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { fetchAdminOrders, updateOrderStatus } from '../lib/api';
import { exportOrdersToCSV } from '../lib/export-excel';
import { Order, OrderStatus } from '../lib/types';
import {
  toVNLocalDateString,
  toVNLocalMonthString,
  getVNToday,
  getVNYesterday,
  getVNThisMonth,
} from '../lib/date-utils';

export const ORDERS_POLL_INTERVAL_MS = 5000;

export const STATUS_TABS: { label: string; value: OrderStatus | 'all' }[] = [
  { label: 'Tất cả đơn', value: 'all' },
  { label: 'Chờ thanh toán', value: 'pending_payment' },
  { label: 'Đã thanh toán', value: 'paid' },
  { label: 'Đang xử lý', value: 'processing' },
  { label: 'Đang giao hàng', value: 'shipping' },
  { label: 'Đã hoàn tất', value: 'completed' },
  { label: 'Đã hủy', value: 'cancelled' },
];

export function useOrders() {
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

  const loadOrders = useCallback(async (showSpinner = true) => {
    if (showSpinner) setLoading(true);
    try {
      const data = await fetchAdminOrders(activeTab === 'all' ? undefined : activeTab);
      if (Array.isArray(data)) {
        setOrders(data);
      }
    } finally {
      if (showSpinner) setLoading(false);
    }
  }, [activeTab]);

  useEffect(() => {
    loadOrders(true);
    const timer = setInterval(() => {
      loadOrders(false);
    }, ORDERS_POLL_INTERVAL_MS);
    return () => clearInterval(timer);
  }, [loadOrders]);

  async function handleUpdateStatus() {
    if (!selectedOrder) return;
    if (selectedOrder.status === 'cancelled') {
      setFeedback({
        text: 'Đơn hàng đã ở trạng thái ĐÃ HUỶ, không thể chuyển sang trạng thái khác',
        type: 'error',
      });
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

  const setFilterToday = () => {
    setFilterDate(getVNToday());
    setFilterMonth('');
  };

  const setFilterYesterday = () => {
    setFilterDate(getVNYesterday());
    setFilterMonth('');
  };

  const setFilterThisMonth = () => {
    setFilterMonth(getVNThisMonth());
    setFilterDate('');
  };

  const clearDateFilter = () => {
    setFilterDate('');
    setFilterMonth('');
  };

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
      // 2. Date filter (exact day in VN timezone: YYYY-MM-DD)
      if (filterDate) {
        const oDate = toVNLocalDateString(o.createdAt);
        if (oDate !== filterDate) return false;
      }
      // 3. Month filter (VN timezone: YYYY-MM)
      if (filterMonth) {
        const oMonth = toVNLocalMonthString(o.createdAt);
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
      setFeedback({
        text: 'Không có đơn hàng nào thỏa mãn điều kiện để xuất báo cáo!',
        type: 'error',
      });
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

  const openStatusModal = (order: Order) => {
    setSelectedOrder(order);
    setNewStatus(order.status);
  };

  const closeStatusModal = () => {
    setSelectedOrder(null);
  };

  return {
    orders,
    filteredOrders,
    loading,
    activeTab,
    setActiveTab,
    searchQuery,
    setSearchQuery,
    filterMonth,
    setFilterMonth,
    filterDate,
    setFilterDate,
    setFilterToday,
    setFilterYesterday,
    setFilterThisMonth,
    clearDateFilter,
    totalFilteredRevenue,
    selectedOrder,
    newStatus,
    setNewStatus,
    statusNote,
    setStatusNote,
    updating,
    feedback,
    loadOrders,
    handleUpdateStatus,
    handleExportExcel,
    openStatusModal,
    closeStatusModal,
  };
}
