'use client';

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import Link from 'next/link';
import { Header } from '../components/Header';
import { DonutSegment } from '../components/CircularCharts';
import { DashboardCircularSection } from '../components/DashboardCircularSection';
import { DashboardDateFilter, DateFilterPreset } from '../components/DashboardDateFilter';
import { DashboardRecentOrders } from '../components/DashboardRecentOrders';
import { StatCard } from '../components/StatCard';
import {
  fetchAdminOrders,
  fetchCategories,
  fetchAdminProducts,
  notifyProductCountSync,
} from '../lib/api';
import { Order, OrderStatus, Category, Product } from '../lib/types';
import {
  RefreshCw,
  Plus,
  Boxes,
  ShoppingBag,
  TrendingUp,
  PackageCheck,
  AlertTriangle,
} from 'lucide-react';

/* -------------------------------------------------------------------------- */
/* Constants                                                                  */
/* -------------------------------------------------------------------------- */

const POLL_INTERVAL_MS = 5000;
const PRODUCT_LIMIT = 400;
const FULFILLMENT_TARGET = 70; // % tối thiểu để coi là "Đạt chỉ tiêu"

const ACTIVE_STATUSES: OrderStatus[] = ['completed', 'shipping', 'processing'];
// Đơn VNPay đã thanh toán và vẫn đang trên đường hoàn tất
const PAID_IN_PROGRESS_STATUSES: OrderStatus[] = ['paid', 'processing', 'shipping'];

const CATEGORY_COLORS = ['#f59e0b', '#3b82f6', '#10b981', '#6366f1', '#a855f7'];

// Chỉ dùng khi API chưa trả về danh mục nào
const FALLBACK_DONUT_SEGMENTS: DonutSegment[] = [
  { id: 'c1', label: 'Áo Sơ Mi Nam', value: 25, count: 25, color: '#f59e0b' },
  { id: 'c2', label: 'Áo Polo & T-Shirt', value: 25, count: 25, color: '#3b82f6' },
  { id: 'c3', label: 'Quần Tây & Kaki', value: 25, count: 25, color: '#10b981' },
  { id: 'c4', label: 'Quần Jeans Nam', value: 25, count: 25, color: '#6366f1' },
  { id: 'c5', label: 'Áo Khoác & Blazer', value: 25, count: 25, color: '#a855f7' },
];

/* -------------------------------------------------------------------------- */
/* Date helpers                                                               */
/* -------------------------------------------------------------------------- */

interface DayRange {
  from?: string; // YYYY-MM-DD (bao gồm)
  to?: string; // YYYY-MM-DD (bao gồm)
}

function toLocalDateString(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function parseLocalDate(s: string): Date {
  const [y, m, d] = s.split('-').map(Number);
  return new Date(y, m - 1, d);
}

function shiftDays(base: Date, days: number): Date {
  const d = new Date(base);
  d.setDate(d.getDate() + days);
  return d;
}

function formatDayVN(s: string): string {
  return s.split('-').reverse().join('/');
}

/** Quy đổi preset + giá trị tuỳ chỉnh thành khoảng ngày cụ thể. */
function getRange(
  preset: DateFilterPreset,
  customDay: string,
  fromDay: string,
  toDay: string
): DayRange {
  const now = new Date();
  const today = toLocalDateString(now);

  switch (preset) {
    case 'today':
      return { from: today, to: today };
    case 'yesterday': {
      const y = toLocalDateString(shiftDays(now, -1));
      return { from: y, to: y };
    }
    case '7days': // 7 ngày gần nhất, tính cả hôm nay
      return { from: toLocalDateString(shiftDays(now, -6)), to: today };
    case '30days':
      return { from: toLocalDateString(shiftDays(now, -29)), to: today };
    case 'custom_day':
      return customDay ? { from: customDay, to: customDay } : {};
    case 'custom_range': {
      // Tự đảo nếu người dùng chọn "từ" lớn hơn "đến"
      if (fromDay && toDay && fromDay > toDay) return { from: toDay, to: fromDay };
      return { from: fromDay || undefined, to: toDay || undefined };
    }
    default:
      return {};
  }
}

/** Khoảng liền trước có cùng độ dài (để tính xu hướng). Trả về null nếu không so sánh được. */
function getPreviousRange(range: DayRange): DayRange | null {
  if (!range.from || !range.to) return null;
  const from = parseLocalDate(range.from);
  const to = parseLocalDate(range.to);
  const length = Math.round((to.getTime() - from.getTime()) / 86_400_000) + 1;
  const prevTo = shiftDays(from, -1);
  const prevFrom = shiftDays(prevTo, -(length - 1));
  return { from: toLocalDateString(prevFrom), to: toLocalDateString(prevTo) };
}

function inRange(dayKey: string | null, range: DayRange): boolean {
  if (!dayKey) return false;
  if (range.from && dayKey < range.from) return false;
  if (range.to && dayKey > range.to) return false;
  return true;
}

/* -------------------------------------------------------------------------- */
/* Stats helpers                                                              */
/* -------------------------------------------------------------------------- */

interface DatedOrder {
  order: Order;
  dayKey: string | null; // null nếu createdAt không hợp lệ
}

/**
 * Đơn được tính vào doanh thu thực thu:
 * - Mọi đơn đã hoàn tất (COD thu tiền khi giao, VNPay đã thu trước đó).
 * - Đơn VNPay đã thanh toán dù đang xử lý/giao (tiền đã về, không nên "biến mất" khỏi doanh thu).
 * Đơn COD chưa hoàn tất và đơn huỷ/chờ thanh toán không được tính.
 */
function isRevenueOrder(order: Order): boolean {
  if (order.status === 'completed') return true;
  return order.paymentMethod === 'vnpay' && PAID_IN_PROGRESS_STATUSES.includes(order.status);
}

function sumRevenue(list: DatedOrder[]): number {
  return list
    .filter(({ order }) => isRevenueOrder(order))
    .reduce((acc, { order }) => acc + (Number(order.total) || 0), 0);
}

function formatTrend(current: number, previous: number): { label: string; up: boolean } | null {
  if (previous <= 0) return null;
  const pct = Math.round(((current - previous) / previous) * 100);
  return { label: `${pct > 0 ? '+' : ''}${pct}%`, up: pct >= 0 };
}

function formatCompact(n: number): string {
  return n >= 1000 ? `${(n / 1000).toFixed(1)}K` : `${n}`;
}

// Tồn kho chỉ nằm ở variants. Nếu API danh sách không trả variants thì sản phẩm đó tính 0.
function getProductStock(p: Product): number {
  return (p.variants ?? []).reduce((sum, v) => sum + (v.stock || 0), 0);
}

/* -------------------------------------------------------------------------- */
/* Page                                                                       */
/* -------------------------------------------------------------------------- */

export default function DashboardPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);

  // Date filter state
  const [preset, setPreset] = useState<DateFilterPreset>('all');
  const [customDay, setCustomDay] = useState('');
  const [fromDay, setFromDay] = useState('');
  const [toDay, setToDay] = useState('');

  const mountedRef = useRef(true);
  const inFlightRef = useRef(false);

  useEffect(() => {
    mountedRef.current = true;
    return () => {
      mountedRef.current = false;
    };
  }, []);

  const loadData = useCallback(async (isManualRefresh = false) => {
    // Tránh chồng request khi server phản hồi chậm hơn chu kỳ polling
    if (inFlightRef.current) return;
    inFlightRef.current = true;
    if (isManualRefresh) setIsRefreshing(true);

    try {
      // allSettled: một API lỗi không làm mất dữ liệu của các API còn lại
      const [catsRes, ordsRes, prodsRes] = await Promise.allSettled([
        fetchCategories(),
        fetchAdminOrders(),
        fetchAdminProducts({ limit: PRODUCT_LIMIT }),
      ]);

      if (!mountedRef.current) return;

      const failed: string[] = [];

      if (catsRes.status === 'fulfilled') setCategories(catsRes.value);
      else failed.push('danh mục');

      if (ordsRes.status === 'fulfilled') setOrders(ordsRes.value);
      else failed.push('đơn hàng');

      if (prodsRes.status === 'fulfilled') {
        const items = prodsRes.value.items || [];
        setProducts(items);
        notifyProductCountSync(items.length);
      } else {
        failed.push('sản phẩm');
      }

      if (failed.length > 0) {
        console.error('Dashboard: không tải được', failed.join(', '));
        setLoadError(`Không tải được dữ liệu ${failed.join(', ')}. Đang hiển thị dữ liệu gần nhất.`);
      } else {
        setLoadError(null);
      }
    } finally {
      inFlightRef.current = false;
      if (mountedRef.current) {
        setLoading(false);
        if (isManualRefresh) setIsRefreshing(false);
      }
    }
  }, []);

  // Tải lần đầu
  useEffect(() => {
    loadData();
  }, [loadData]);

  // Realtime polling: tạm dừng khi tab bị ẩn, tải lại ngay khi quay lại tab
  useEffect(() => {
    const interval = setInterval(() => {
      if (!document.hidden) loadData();
    }, POLL_INTERVAL_MS);

    const onVisibility = () => {
      if (!document.hidden) loadData();
    };
    document.addEventListener('visibilitychange', onVisibility);

    return () => {
      clearInterval(interval);
      document.removeEventListener('visibilitychange', onVisibility);
    };
  }, [loadData]);

  /* ----------------------------- Orders & filter ---------------------------- */

  // Tính ngày của từng đơn một lần duy nhất
  const datedOrders = useMemo<DatedOrder[]>(() => {
    const list = Array.isArray(orders) ? orders : [];
    return list.map((order) => {
      const d = new Date(order.createdAt);
      return { order, dayKey: Number.isNaN(d.getTime()) ? null : toLocalDateString(d) };
    });
  }, [orders]);

  const range = useMemo(
    () => getRange(preset, customDay, fromDay, toDay),
    [preset, customDay, fromDay, toDay]
  );

  const filteredDated = useMemo(() => {
    if (preset === 'all') return datedOrders;
    return datedOrders.filter(({ dayKey }) => inRange(dayKey, range));
  }, [datedOrders, preset, range]);

  const filteredOrders = useMemo(() => filteredDated.map((d) => d.order), [filteredDated]);

  const previousDated = useMemo(() => {
    const prev = getPreviousRange(range);
    if (!prev) return null;
    return datedOrders.filter(({ dayKey }) => inRange(dayKey, prev));
  }, [datedOrders, range]);

  /* --------------------------------- KPIs ----------------------------------- */

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
      // Tỉ lệ hoàn tất = đơn đã giao thành công / tổng đơn (khớp với phụ đề thẻ)
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

  /* ------------------------------ Category donut ---------------------------- */

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

  /* --------------------------------- Render --------------------------------- */

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

        {/* 1. Welcome & actions */}
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
                onClick={() => loadData(true)}
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

        {/* 2. Date filter */}
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
          onReset={() => {
            setPreset('all');
            setCustomDay('');
            setFromDay('');
            setToDay('');
          }}
          ordersCount={stats.total}
          revenue={stats.revenue}
        />

        {/* 3. KPI cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          <StatCard
            title="Doanh thu thực thu"
            value={`${stats.revenue.toLocaleString('vi-VN')} ₫`}
            subtitle="Đơn hoàn tất hoặc VNPay đã thanh toán"
            icon={TrendingUp}
            trend={stats.revenueTrend?.label ?? '—'}
            trendUp={stats.revenueTrend?.up ?? true}
            color="emerald"
          />

          <StatCard
            title="Tổng đơn tiếp nhận"
            value={stats.total}
            subtitle={`${stats.activeCount} đơn đang xử lý, giao hoặc đã xong`}
            icon={ShoppingBag}
            trend={stats.ordersTrend?.label ?? (stats.total > 0 ? '—' : 'Chưa có')}
            trendUp={stats.ordersTrend?.up ?? stats.total > 0}
            color="blue"
          />

          <StatCard
            title="Tỉ lệ hoàn tất đơn"
            value={`${stats.fulfillmentRate}%`}
            subtitle={`${stats.completedCount}/${stats.total} đơn giao thành công`}
            icon={PackageCheck}
            trend={stats.fulfillmentRate >= FULFILLMENT_TARGET ? 'Đạt chỉ tiêu' : 'Dưới chỉ tiêu'}
            trendUp={stats.fulfillmentRate >= FULFILLMENT_TARGET}
            color="amber"
          />

          <StatCard
            title="Sản phẩm & Tồn kho"
            value={`${products.length} SP`}
            subtitle={`${totalStockDisplay} tồn kho sẵn sàng xuất`}
            icon={Boxes}
            trend={`${categories.length} Danh mục`}
            trendUp={true}
            color="purple"
          />
        </div>

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