'use client';

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import {
  fetchAdminOrders,
  fetchCategories,
  fetchAdminProducts,
  notifyProductCountSync,
} from '../lib/api';
import { Order, OrderStatus, Category, Product } from '../lib/types';
import { DateFilterPreset } from '../components/DashboardDateFilter';
import { DonutSegment } from '../components/CircularCharts';

export const POLL_INTERVAL_MS = 5000;
export const PRODUCT_LIMIT = 400;
export const FULFILLMENT_TARGET = 70;

export const ACTIVE_STATUSES: OrderStatus[] = ['completed', 'shipping', 'processing'];
export const PAID_IN_PROGRESS_STATUSES: OrderStatus[] = ['paid', 'processing', 'shipping'];
export const CATEGORY_COLORS = ['#f59e0b', '#3b82f6', '#10b981', '#6366f1', '#a855f7'];

export const FALLBACK_DONUT_SEGMENTS: DonutSegment[] = [
  { id: 'c1', label: 'Áo Sơ Mi Nam', value: 25, count: 25, color: '#f59e0b' },
  { id: 'c2', label: 'Áo Polo & T-Shirt', value: 25, count: 25, color: '#3b82f6' },
  { id: 'c3', label: 'Quần Tây & Kaki', value: 25, count: 25, color: '#10b981' },
  { id: 'c4', label: 'Quần Jeans Nam', value: 25, count: 25, color: '#6366f1' },
  { id: 'c5', label: 'Áo Khoác & Blazer', value: 25, count: 25, color: '#a855f7' },
];

import {
  toVNLocalDateString,
  getVNToday,
  getVNYesterday,
  shiftVNDays,
  formatVNDayDisplay,
  parseVNLocalDate,
} from '../lib/date-utils';

export interface DayRange {
  from?: string;
  to?: string;
}

export const toLocalDateString = toVNLocalDateString;
export const parseLocalDate = parseVNLocalDate;
export const formatDayVN = formatVNDayDisplay;

export function shiftDays(base: Date, days: number): Date {
  const d = new Date(base);
  d.setDate(d.getDate() + days);
  return d;
}

export function getRange(
  preset: DateFilterPreset,
  customDay: string,
  fromDay: string,
  toDay: string
): DayRange {
  const today = getVNToday();

  switch (preset) {
    case 'today':
      return { from: today, to: today };
    case 'yesterday': {
      const y = getVNYesterday();
      return { from: y, to: y };
    }
    case '7days':
      return { from: shiftVNDays(today, -6), to: today };
    case '30days':
      return { from: shiftVNDays(today, -29), to: today };
    case 'custom_day':
      return customDay ? { from: customDay, to: customDay } : {};
    case 'custom_range':
      return { from: fromDay || undefined, to: toDay || undefined };
    case 'all':
    default:
      return {};
  }
}

export function getPreviousRange(range: DayRange): DayRange | null {
  if (!range.from || !range.to) return null;
  const start = parseVNLocalDate(range.from);
  const end = parseVNLocalDate(range.to);
  const diffDays = Math.round((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1;
  if (diffDays <= 0 || diffDays > 365) return null;

  const prevEnd = shiftVNDays(range.from, -1);
  const prevStart = shiftVNDays(prevEnd, -(diffDays - 1));
  return {
    from: prevStart,
    to: prevEnd,
  };
}

export function orderInDayRange(o: Order, range: DayRange): boolean {
  if (!range.from && !range.to) return true;
  if (!o.createdAt) return false;
  const day = toVNLocalDateString(o.createdAt);
  if (range.from && day < range.from) return false;
  if (range.to && day > range.to) return false;
  return true;
}

export function sumRevenue(list: Order[]): number {
  return list.reduce((acc, o) => {
    if (o.status === 'cancelled') return acc;
    if (o.status === 'completed') return acc + (o.total || 0);
    if (o.paymentMethod === 'vnpay' && PAID_IN_PROGRESS_STATUSES.includes(o.status)) {
      return acc + (o.total || 0);
    }
    return acc;
  }, 0);
}

export function formatTrend(curr: number, prev: number): { label: string; up: boolean } {
  if (prev === 0) {
    if (curr === 0) return { label: '0%', up: true };
    return { label: '+100%', up: true };
  }
  const pct = Math.round(((curr - prev) / prev) * 100);
  return {
    label: `${pct >= 0 ? '+' : ''}${pct}%`,
    up: pct >= 0,
  };
}

export function getProductStock(p: Product): number {
  if (typeof (p as any).stock === 'number') return (p as any).stock;
  if (Array.isArray(p.variants) && p.variants.length > 0) {
    return p.variants.reduce((sum, v) => sum + (v.stock || 0), 0);
  }
  return 0;
}

export function formatCompact(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}k`;
  return String(n);
}

export function useDashboard() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [preset, setPreset] = useState<DateFilterPreset>('all');
  const [customDay, setCustomDay] = useState('');
  const [fromDay, setFromDay] = useState('');
  const [toDay, setToDay] = useState('');

  const isMountedRef = useRef(true);
  useEffect(() => {
    isMountedRef.current = true;
    return () => {
      isMountedRef.current = false;
    };
  }, []);

  const loadData = useCallback(async (manual = false) => {
    if (manual) setIsRefreshing(true);
    setLoadError(null);
    try {
      const [ordData, catData, prodData] = await Promise.all([
        fetchAdminOrders(),
        fetchCategories(),
        fetchAdminProducts({ limit: PRODUCT_LIMIT }),
      ]);
      if (!isMountedRef.current) return;

      if (Array.isArray(ordData)) setOrders(ordData);
      if (Array.isArray(catData)) setCategories(catData);
      if (prodData && Array.isArray(prodData.items)) {
        setProducts(prodData.items);
        notifyProductCountSync(prodData.items.length);
      }
    } catch (err) {
      if (!isMountedRef.current) return;
      setLoadError(err instanceof Error ? err.message : 'Không thể kết nối đến máy chủ API');
    } finally {
      if (isMountedRef.current) {
        setLoading(false);
        if (manual) setIsRefreshing(false);
      }
    }
  }, []);

  useEffect(() => {
    loadData();
    const timer = setInterval(() => {
      loadData(false);
    }, POLL_INTERVAL_MS);
    return () => clearInterval(timer);
  }, [loadData]);

  const currentRange = useMemo(
    () => getRange(preset, customDay, fromDay, toDay),
    [preset, customDay, fromDay, toDay]
  );

  const previousRange = useMemo(() => getPreviousRange(currentRange), [currentRange]);

  const filteredOrders = useMemo(() => {
    return orders.filter((o) => orderInDayRange(o, currentRange));
  }, [orders, currentRange]);

  const filteredDated = useMemo(() => {
    return orders.filter((o) => orderInDayRange(o, currentRange));
  }, [orders, currentRange]);

  const previousDated = useMemo(() => {
    if (!previousRange) return null;
    return orders.filter((o) => orderInDayRange(o, previousRange));
  }, [orders, previousRange]);

  const stats = useMemo(() => {
    const total = filteredOrders.length;
    const activeCount = filteredOrders.filter((o) => ACTIVE_STATUSES.includes(o.status)).length;
    const completedCount = filteredOrders.filter((o) => o.status === 'completed').length;
    const revenue = sumRevenue(filteredDated);

    return {
      total,
      activeCount,
      completedCount,
      revenue,
      fulfillmentRate: total > 0 ? Math.round((completedCount / total) * 100) : 0,
      revenueTrend: previousDated ? formatTrend(revenue, sumRevenue(previousDated)) : null,
      ordersTrend: previousDated ? formatTrend(total, previousDated.length) : null,
    };
  }, [filteredOrders, filteredDated, previousDated]);

  const dateLabel = useMemo(() => {
    switch (preset) {
      case 'today':
        return 'Hôm nay';
      case 'yesterday':
        return 'Hôm qua';
      case '7days':
        return '7 ngày qua';
      case '30days':
        return '30 ngày qua';
      case 'custom_day':
        return customDay ? `Ngày ${formatDayVN(customDay)}` : 'Tất cả thời gian';
      case 'custom_range':
        if (!fromDay && !toDay) return 'Tất cả thời gian';
        return `${fromDay ? formatDayVN(fromDay) : '...'} - ${toDay ? formatDayVN(toDay) : '...'}`;
      default:
        return 'Tất cả thời gian';
    }
  }, [preset, customDay, fromDay, toDay]);

  const totalStockDisplay = useMemo(
    () => formatCompact(products.reduce((acc, p) => acc + getProductStock(p), 0)),
    [products]
  );

  const donutSegments = useMemo<DonutSegment[]>(() => {
    const counts = new Map<string, number>();
    products.forEach((p) => {
      counts.set(p.categoryId, (counts.get(p.categoryId) || 0) + 1);
    });

    const segments = categories
      .map((cat, idx) => {
        const count = counts.get(cat.id) || 0;
        return {
          id: cat.id,
          label: cat.name,
          value: count,
          count,
          color: CATEGORY_COLORS[idx % CATEGORY_COLORS.length],
        };
      })
      .filter((s) => s.count > 0);

    return segments.length > 0 ? segments : FALLBACK_DONUT_SEGMENTS;
  }, [categories, products]);

  const resetDateFilter = () => {
    setPreset('all');
    setCustomDay('');
    setFromDay('');
    setToDay('');
  };

  return {
    orders,
    categories,
    products,
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
  };
}
