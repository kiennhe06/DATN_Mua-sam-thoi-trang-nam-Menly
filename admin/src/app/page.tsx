'use client';

import React from 'react';
import { Header } from '../components/Header';
import { DashboardCircularSection } from '../components/DashboardCircularSection';
import { DashboardDateFilter } from '../components/DashboardDateFilter';
import { DashboardRecentOrders } from '../components/DashboardRecentOrders';
import { DashboardWelcomeBanner } from '../components/dashboard/DashboardWelcomeBanner';
import { DashboardMetricsCards } from '../components/dashboard/DashboardMetricsCards';
import { useDashboard } from '../hooks/useDashboard';
import { AlertTriangle } from 'lucide-react';

export default function DashboardPage() {
  const {
    products,
    categories,
    loading,
    isRefreshing,
    loadError,
    preset,
    setPreset,
    customDay,
    setCustomDay,
    fromDay,
    setFromDay,
    toDay,
    setToDay,
    filteredOrders,
    stats,
    dateLabel,
    totalStockDisplay,
    donutSegments,
    loadData,
    resetDateFilter,
  } = useDashboard();

  return (
    <div className="flex-1 flex flex-col bg-slate-50 min-h-screen">
      <Header
        title="Bảng điều khiển Tổng quan"
        subtitle="Hệ thống giám sát mua bán & vận hành Menly Fashion"
        onRefresh={() => loadData(true)}
      />

      <div className="p-6 sm:p-8 space-y-7 flex-1">
        {loadError && (
          <div
            role="alert"
            className="flex items-center gap-2.5 px-4 py-3 text-xs sm:text-sm font-medium text-amber-800 bg-amber-50 border border-amber-200 rounded-xl"
          >
            <AlertTriangle className="w-4 h-4 shrink-0" />
            {loadError}
          </div>
        )}

        {/* 1. Welcome & quick actions banner */}
        <DashboardWelcomeBanner
          isRefreshing={isRefreshing}
          onRefresh={() => loadData(true)}
        />

        {/* 2. Date filter toolbar */}
        <DashboardDateFilter
          preset={preset}
          customDay={customDay}
          fromDay={fromDay}
          toDay={toDay}
          onPresetChange={setPreset}
          onCustomDayChange={(day) => {
            setCustomDay(day);
            setPreset('custom_day');
          }}
          onRangeChange={(from, to) => {
            setFromDay(from);
            setToDay(to);
            setPreset('custom_range');
          }}
          onReset={resetDateFilter}
          ordersCount={stats.total}
          revenue={stats.revenue}
        />

        {/* 3. KPI metrics cards */}
        <DashboardMetricsCards
          revenue={stats.revenue}
          revenueTrend={stats.revenueTrend}
          totalOrders={stats.total}
          activeCount={stats.activeCount}
          ordersTrend={stats.ordersTrend}
          fulfillmentRate={stats.fulfillmentRate}
          completedCount={stats.completedCount}
          productsCount={products.length}
          totalStockDisplay={totalStockDisplay}
          categoriesCount={categories.length}
        />

        {/* 4. Analytics & category structure */}
        <DashboardCircularSection
          orderFulfillmentRate={stats.fulfillmentRate}
          completedOrProcessing={stats.activeCount}
          totalOrdersCount={stats.total}
          totalRevenue={stats.revenue}
          finalDonutSegments={donutSegments}
          dateLabel={dateLabel}
          orders={filteredOrders}
          onOrderUpdated={() => loadData(true)}
        />

        {/* 5. Recent orders */}
        <div className="w-full">
          <DashboardRecentOrders
            orders={filteredOrders}
            productsCount={products.length}
            totalRevenue={stats.revenue}
            loading={loading}
            hideStats={true}
          />
        </div>
      </div>
    </div>
  );
}