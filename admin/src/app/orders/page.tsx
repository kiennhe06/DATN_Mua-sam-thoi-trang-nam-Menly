'use client';

import React from 'react';
import { Header } from '../../components/Header';
import { ChangeOrderStatusModal } from '../../components/ChangeOrderStatusModal';
import { OrderFilterBar } from '../../components/orders/OrderFilterBar';
import { OrdersTable } from '../../components/orders/OrdersTable';
import { useOrders } from '../../hooks/useOrders';
import { CheckCircle2, AlertCircle } from 'lucide-react';
import { formatVNDayDisplay, getVNToday } from '../../lib/date-utils';

export default function OrdersPage() {
  const {
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
  } = useOrders();

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Đơn hàng"
        subtitle="Theo dõi và chuyển đổi trạng thái quy trình đơn hàng MenShop"
        onRefresh={loadOrders}
      />

      <div className="p-8 space-y-6 flex-1">
        {/* Filters and search */}
        <OrderFilterBar
          activeTab={activeTab}
          setActiveTab={setActiveTab}
          searchQuery={searchQuery}
          setSearchQuery={setSearchQuery}
          filterDate={filterDate}
          setFilterDate={setFilterDate}
          filterMonth={filterMonth}
          setFilterMonth={setFilterMonth}
          filteredCount={filteredOrders.length}
          onExportExcel={handleExportExcel}
        />

        {/* Summary Mini Bar */}
        <div className="flex items-center justify-between text-xs px-2 text-slate-600">
          <span>
            Hiển thị <strong className="text-slate-900">{filteredOrders.length}</strong> đơn hàng
            {activeTab !== 'all' && ` (trạng thái: ${activeTab})`}
            {filterDate && (
              <> vào ngày <strong className="text-amber-700">{filterDate === getVNToday() ? `Hôm nay (${formatVNDayDisplay(filterDate)})` : formatVNDayDisplay(filterDate)}</strong></>
            )}
            {filterMonth && ` trong tháng ${filterMonth}`}
          </span>
          <span>
            Doanh thu thực thu:{' '}
            <strong className="text-rose-600 font-mono text-sm font-extrabold">
              {totalFilteredRevenue.toLocaleString('vi-VN')} đ
            </strong>
          </span>
        </div>

        {/* Feedback alert */}
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

        {/* Orders List Component */}
        <OrdersTable
          orders={filteredOrders}
          loading={loading}
          onOpenStatusModal={openStatusModal}
        />
      </div>

      {/* Change Status Modal */}
      <ChangeOrderStatusModal
        selectedOrder={selectedOrder}
        newStatus={newStatus}
        statusNote={statusNote}
        updating={updating}
        onClose={closeStatusModal}
        onStatusChange={setNewStatus}
        onNoteChange={setStatusNote}
        onSave={handleUpdateStatus}
      />
    </div>
  );
}
