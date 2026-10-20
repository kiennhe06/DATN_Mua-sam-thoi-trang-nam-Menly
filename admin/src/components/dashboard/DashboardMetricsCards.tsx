'use client';

import React from 'react';
import { TrendingUp, ShoppingBag, PackageCheck, Boxes } from 'lucide-react';
import { StatCard } from '../StatCard';
import { FULFILLMENT_TARGET } from '../../hooks/useDashboard';

interface DashboardMetricsCardsProps {
  revenue: number;
  revenueTrend: { label: string; up: boolean } | null;
  totalOrders: number;
  activeCount: number;
  ordersTrend: { label: string; up: boolean } | null;
  fulfillmentRate: number;
  completedCount: number;
  productsCount: number;
  totalStockDisplay: string;
  categoriesCount: number;
}

export function DashboardMetricsCards({
  revenue,
  revenueTrend,
  totalOrders,
  activeCount,
  ordersTrend,
  fulfillmentRate,
  completedCount,
  productsCount,
  totalStockDisplay,
  categoriesCount,
}: DashboardMetricsCardsProps) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
      <StatCard
        title="Doanh thu thực thu"
        value={`${revenue.toLocaleString('vi-VN')} ₫`}
        subtitle="Đơn hoàn tất hoặc VNPay đã thanh toán"
        icon={TrendingUp}
        trend={revenueTrend?.label ?? '—'}
        trendUp={revenueTrend?.up ?? true}
        color="emerald"
      />

      <StatCard
        title="Tổng đơn tiếp nhận"
        value={totalOrders}
        subtitle={`${activeCount} đơn đang xử lý, giao hoặc đã xong`}
        icon={ShoppingBag}
        trend={ordersTrend?.label ?? (totalOrders > 0 ? '—' : 'Chưa có')}
        trendUp={ordersTrend?.up ?? totalOrders > 0}
        color="blue"
      />

      <StatCard
        title="Tỉ lệ hoàn tất đơn"
        value={`${fulfillmentRate}%`}
        subtitle={`${completedCount}/${totalOrders} đơn giao thành công`}
        icon={PackageCheck}
        trend={fulfillmentRate >= FULFILLMENT_TARGET ? 'Đạt chỉ tiêu' : 'Dưới chỉ tiêu'}
        trendUp={fulfillmentRate >= FULFILLMENT_TARGET}
        color="amber"
      />

      <StatCard
        title="Sản phẩm & Tồn kho"
        value={`${productsCount} SP`}
        subtitle={`${totalStockDisplay} tồn kho sẵn sàng xuất`}
        icon={Boxes}
        trend={`${categoriesCount} Danh mục`}
        trendUp={true}
        color="purple"
      />
    </div>
  );
}
