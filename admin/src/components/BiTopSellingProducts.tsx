'use client';

import React, { useState, useMemo } from 'react';
import { Order, Product, Category, OrderStatus } from '../lib/types';
import {
  Trophy,
  Flame,
  TrendingUp,
  PackageCheck,
  DollarSign,
  ArrowUpDown,
  Download,
  Eye,
  X,
  Calendar,
  User,
  ShoppingBag,
  ExternalLink,
} from 'lucide-react';

interface BiTopSellingProductsProps {
  orders: Order[];
  products: Product[];
  categories?: Category[];
}

export interface OrderContribution {
  orderId: string;
  orderCode: string;
  customerName: string;
  phone: string;
  createdAt: string;
  status: OrderStatus;
  paymentMethod: string;
  size: string;
  color: string;
  quantity: number;
  unitPrice: number;
  lineTotal: number;
}

export interface BestSellerItem {
  id: string;
  name: string;
  categoryName: string;
  thumbnailUrl: string | null;
  soldQuantity: number;
  revenue: number;
  orderCount: number;
  currentStock: number;
  orders: OrderContribution[];
}

export type RevenueStatusFilter = 'realized' | 'completed' | 'all_active';

export function BiTopSellingProducts({ orders, products, categories = [] }: BiTopSellingProductsProps) {
  const [sortBy, setSortBy] = useState<'quantity' | 'revenue'>('revenue');
  const [statusFilter, setStatusFilter] = useState<RevenueStatusFilter>('realized');
  const [selectedAuditItem, setSelectedAuditItem] = useState<BestSellerItem | null>(null);

  // Lọc đơn hàng theo trạng thái thực tế nhất
  const effectiveOrders = useMemo(() => {
    return orders.filter((o) => {
      if (statusFilter === 'realized') {
        // Thực tế nhất: Đơn đã giao hoàn tất (completed) hoặc đã thanh toán thành công (paid)
        return o.status === 'completed' || o.status === 'paid';
      }
      if (statusFilter === 'completed') {
        // Chỉ đơn đã giao thành công và hoàn tất
        return o.status === 'completed';
      }
      // Tất cả đơn hợp lệ phát sinh (loại bỏ đơn hủy)
      return o.status !== 'cancelled';
    });
  }, [orders, statusFilter]);

  // Compute best sellers từ 100% dữ liệu đơn hàng thực tế
  const bestSellers = useMemo(() => {
    const salesMap = new Map<
      string,
      {
        name: string;
        soldQuantity: number;
        revenue: number;
        orderCount: number;
        contributions: OrderContribution[];
      }
    >();

    // 1. Accumulate sales from orders thực tế
    effectiveOrders.forEach((order) => {
      (order.items || []).forEach((item) => {
        const key = item.productName?.trim() || 'Sản phẩm khác';
        const curr = salesMap.get(key) || {
          name: key,
          soldQuantity: 0,
          revenue: 0,
          orderCount: 0,
          contributions: [],
        };
        const qty = item.quantity || 1;
        const price = item.unitPrice || 0;
        curr.soldQuantity += qty;
        curr.revenue += qty * price;
        curr.orderCount += 1;
        curr.contributions.push({
          orderId: order.id,
          orderCode: order.code,
          customerName: order.shippingAddress?.name || order.shipName || 'Khách hàng',
          phone: order.shippingAddress?.phone || order.shipPhone || '',
          createdAt: order.createdAt,
          status: order.status,
          paymentMethod: order.paymentMethod,
          size: item.size || 'M',
          color: item.color || 'Trắng',
          quantity: qty,
          unitPrice: price,
          lineTotal: qty * price,
        });
        salesMap.set(key, curr);
      });
    });

    const list: BestSellerItem[] = [];

    // Match with products catalog for images and details
    salesMap.forEach((sales, nameKey) => {
      const matchedProd = products.find(
        (p) =>
          p.name.toLowerCase().trim() === nameKey.toLowerCase().trim() ||
          p.slug.toLowerCase().includes(nameKey.toLowerCase()) ||
          nameKey.toLowerCase().includes(p.name.toLowerCase())
      );

      const matchedCat = matchedProd?.categoryId
        ? categories.find((c) => c.id === matchedProd.categoryId)
        : null;

      const currentStock =
        matchedProd?.variants?.reduce((s, v) => s + (v.stock || 0), 0) ?? 0;

      list.push({
        id: matchedProd?.id || `item-${list.length + 1}`,
        name: nameKey,
        categoryName: matchedCat?.name || 'Thời trang Nam',
        thumbnailUrl:
          matchedProd?.thumbnailUrl ||
          'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=800',
        soldQuantity: sales.soldQuantity,
        revenue: sales.revenue,
        orderCount: sales.orderCount,
        currentStock,
        orders: sales.contributions,
      });
    });

    // 100% dữ liệu thực tế: Không thêm dữ liệu ảo (mockSold) khi danh sách trống hoặc ít đơn

    // Sort list
    if (sortBy === 'quantity') {
      list.sort((a, b) => b.soldQuantity - a.soldQuantity);
    } else {
      list.sort((a, b) => b.revenue - a.revenue);
    }

    return list.slice(0, 10); // Top 10 best sellers thực tế
  }, [effectiveOrders, products, categories, sortBy]);

  const maxVal = useMemo(() => {
    if (bestSellers.length === 0) return 1;
    return sortBy === 'quantity' ? bestSellers[0].soldQuantity : bestSellers[0].revenue;
  }, [bestSellers, sortBy]);

  const handleExportBestSellersCSV = () => {
    if (bestSellers.length === 0) return;
    const headers = [
      'Xếp hạng',
      'Tên sản phẩm',
      'Danh mục',
      'Số lượng đã bán (cái)',
      'Tổng doanh thu (VNĐ)',
      'Số lượt đặt hàng',
      'Tồn kho hiện tại (cái)',
    ];
    const rows = bestSellers.map((item, idx) => [
      `"${idx + 1}"`,
      `"${item.name.replace(/"/g, '""')}"`,
      `"${item.categoryName}"`,
      `"${item.soldQuantity}"`,
      `"${item.revenue}"`,
      `"${item.orderCount}"`,
      `"${item.currentStock}"`,
    ]);
    const csvContent = '\uFEFF' + [headers.join(','), ...rows.map((r) => r.join(','))].join('\r\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `Top_san_pham_ban_chay_Menly_${Date.now()}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  return (
    <div className="w-full bg-white border border-slate-200 rounded-2xl p-6 shadow-2xs">
      {/* Header */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 mb-6 pb-4 border-b border-slate-200">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl bg-amber-50 border border-amber-200 flex items-center justify-center text-amber-600">
            <Flame className="w-4 h-4 fill-amber-500 text-amber-500" />
          </div>
          <div>
            <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
              Top Doanh Thu & Sản Phẩm Bán Chạy
              <span className="text-[10px] bg-emerald-50 text-emerald-700 border border-emerald-200 px-2 py-0.5 rounded-full font-mono font-bold">
                DỮ LIỆU THỰC TẾ ({effectiveOrders.length} ĐƠN)
              </span>
            </h3>
            <p className="text-[11px] text-slate-500 mt-0.5">
              Thống kê sản lượng và doanh thu thu về từ đơn hàng thực tế (không dùng số liệu giả định)
            </p>
          </div>
        </div>

        {/* Controls: Status filter, Sort toggle & Export */}
        <div className="flex flex-wrap items-center gap-2.5">
          {/* Status scope selector */}
          <div className="flex items-center bg-slate-100 p-1 rounded-xl border border-slate-200 text-xs">
            <button
              onClick={() => setStatusFilter('realized')}
              title="Chỉ tính đơn đã hoàn tất giao hàng (completed) hoặc đã thanh toán (paid)"
              className={`px-2.5 py-1 rounded-lg font-medium transition-all cursor-pointer ${
                statusFilter === 'realized'
                  ? 'bg-white text-emerald-800 border border-slate-200 shadow-2xs font-bold'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Thực thu (Đã giao / Đã thanh toán)
            </button>
            <button
              onClick={() => setStatusFilter('completed')}
              title="Chỉ tính đơn đã giao hàng thành công hoàn tất"
              className={`px-2.5 py-1 rounded-lg font-medium transition-all cursor-pointer ${
                statusFilter === 'completed'
                  ? 'bg-white text-emerald-800 border border-slate-200 shadow-2xs font-bold'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Đã giao hoàn tất
            </button>
            <button
              onClick={() => setStatusFilter('all_active')}
              title="Tính tất cả các đơn hợp lệ đang xử lý, đang giao hoặc đã hoàn tất"
              className={`px-2.5 py-1 rounded-lg font-medium transition-all cursor-pointer ${
                statusFilter === 'all_active'
                  ? 'bg-white text-emerald-800 border border-slate-200 shadow-2xs font-bold'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Tất cả đơn (trừ hủy)
            </button>
          </div>

          {/* Metric Sort toggle */}
          <div className="flex items-center bg-slate-100 p-1 rounded-xl border border-slate-200 text-xs">
            <button
              onClick={() => setSortBy('revenue')}
              className={`px-3 py-1 rounded-lg font-semibold transition-all cursor-pointer ${
                sortBy === 'revenue'
                  ? 'bg-amber-500 text-slate-950 font-bold shadow-2xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Theo doanh thu (VNĐ)
            </button>
            <button
              onClick={() => setSortBy('quantity')}
              className={`px-3 py-1 rounded-lg font-semibold transition-all cursor-pointer ${
                sortBy === 'quantity'
                  ? 'bg-amber-500 text-slate-950 font-bold shadow-2xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Theo số lượng (pcs)
            </button>
          </div>

          <button
            onClick={handleExportBestSellersCSV}
            disabled={bestSellers.length === 0}
            title="Xuất bảng xếp hạng Top sản phẩm bán chạy ra CSV"
            className="p-1.5 rounded-xl bg-slate-50 hover:bg-slate-100 disabled:opacity-40 disabled:cursor-not-allowed text-slate-700 border border-slate-200 transition-colors cursor-pointer"
          >
            <Download className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Leaderboard Table / Empty State */}
      {bestSellers.length === 0 ? (
        <div className="py-12 px-4 rounded-xl bg-slate-50 border border-slate-200 text-center">
          <PackageCheck className="w-10 h-10 mx-auto mb-3 text-slate-400" />
          <h4 className="text-sm font-semibold text-slate-700">
            Chưa có sản phẩm nào phát sinh doanh thu thực tế
          </h4>
          <p className="text-xs text-slate-500 mt-1 max-w-md mx-auto">
            Hệ thống chỉ thống kê dựa trên đơn hàng thực tế tồn tại. Hiện tại chưa có đơn hàng nào
            thỏa mãn tiêu chí lọc <span className="text-emerald-700 font-bold">({statusFilter === 'realized' ? 'Đã hoàn thành hoặc Đã thanh toán' : statusFilter === 'completed' ? 'Đã hoàn tất' : 'Đơn hợp lệ'})</span>.
          </p>
          {statusFilter !== 'all_active' && (
            <button
              onClick={() => setStatusFilter('all_active')}
              className="mt-4 px-3.5 py-1.5 rounded-lg bg-white hover:bg-slate-50 border border-slate-200 text-slate-800 text-xs font-semibold cursor-pointer transition-colors shadow-2xs"
            >
              Thử xem toàn bộ đơn phát sinh (kể cả đang giao)
            </button>
          )}
        </div>
      ) : (
      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs">
          <thead>
            <tr className="text-slate-500 border-b border-slate-200 font-bold bg-slate-50/70">
              <th className="py-2.5 px-3 text-center w-12">Hạng</th>
              <th className="py-2.5 px-3">Sản phẩm</th>
              <th className="py-2.5 px-3">Danh mục</th>
              <th className={`py-2.5 px-3 text-right transition-colors ${
                sortBy === 'quantity'
                  ? 'text-amber-800 bg-amber-50 font-bold border-b-2 border-amber-500'
                  : ''
              }`}>
                {sortBy === 'quantity' ? 'Đã bán ↓ (Đang xếp)' : 'Đã bán'}
              </th>
              <th className="py-2.5 px-3 min-w-[140px]">
                {sortBy === 'revenue' ? 'Tỷ trọng Doanh thu' : 'Tỷ trọng Sản lượng'}
              </th>
              <th className={`py-2.5 px-3 text-right transition-colors ${
                sortBy === 'revenue'
                  ? 'text-emerald-800 bg-emerald-50 font-bold border-b-2 border-emerald-500'
                  : ''
              }`}>
                {sortBy === 'revenue' ? 'Doanh thu thu về ↓ (Đang xếp)' : 'Doanh thu thu về'}
              </th>
              <th className="py-2.5 px-3 text-center">Tồn kho</th>
              <th className="py-2.5 px-3 text-center w-24">Đối chiếu</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-slate-800">
            {bestSellers.map((item, idx) => {
              const currentMetric = sortBy === 'quantity' ? item.soldQuantity : item.revenue;
              const percent = maxVal > 0 ? Math.round((currentMetric / maxVal) * 100) : 0;

              // Rank styling
              let rankBadge = (
                <span className="w-6 h-6 rounded-full bg-slate-800 text-slate-400 font-mono font-bold text-[11px] flex items-center justify-center mx-auto">
                  {idx + 1}
                </span>
              );
              if (idx === 0) {
                rankBadge = (
                  <span className="w-6 h-6 rounded-full bg-amber-400/20 text-amber-300 border border-amber-400/40 font-bold text-xs flex items-center justify-center mx-auto shadow-sm shadow-amber-400/30">
                    🥇
                  </span>
                );
              } else if (idx === 1) {
                rankBadge = (
                  <span className="w-6 h-6 rounded-full bg-slate-300/20 text-slate-200 border border-slate-300/40 font-bold text-xs flex items-center justify-center mx-auto">
                    🥈
                  </span>
                );
              } else if (idx === 2) {
                rankBadge = (
                  <span className="w-6 h-6 rounded-full bg-amber-700/20 text-amber-500 border border-amber-700/40 font-bold text-xs flex items-center justify-center mx-auto">
                    🥉
                  </span>
                );
              }

              return (
                <tr
                  key={item.id}
                  onClick={() => setSelectedAuditItem(item)}
                  className="hover:bg-slate-50 transition-colors cursor-pointer group"
                >
                  <td className="py-3 px-3 text-center">{rankBadge}</td>
                  <td className="py-3 px-3 max-w-xs">
                    <div className="flex items-center gap-3">
                      {item.thumbnailUrl && (
                        <img
                          src={item.thumbnailUrl}
                          alt={item.name}
                          className="w-10 h-11 object-cover rounded-lg border border-slate-200 bg-slate-100 shrink-0"
                        />
                      )}
                      <div>
                        <p className="font-bold text-slate-900 group-hover:text-amber-700 transition-colors line-clamp-1">{item.name}</p>
                        <p className="text-[10px] text-slate-400 mt-0.5 font-mono">
                          {item.orderCount} lượt đặt
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className="py-3 px-3">
                    <span className="px-2 py-0.5 rounded-full text-[10px] bg-slate-100 border border-slate-200 text-slate-700 font-semibold">
                      {item.categoryName}
                    </span>
                  </td>
                  <td className={`py-3 px-3 text-right font-mono text-xs transition-colors ${
                    sortBy === 'quantity'
                      ? 'bg-amber-50 text-amber-800 font-black'
                      : 'text-slate-700 font-semibold'
                  }`}>
                    {item.soldQuantity.toLocaleString('vi-VN')} pcs
                  </td>
                  <td className="py-3 px-3">
                    <div className="flex items-center gap-2">
                      <div className="flex-1 h-2 rounded-full bg-slate-100 border border-slate-200 overflow-hidden">
                        <div
                          style={{ width: `${percent}%` }}
                          className={`h-full rounded-full transition-all duration-500 ${
                            sortBy === 'revenue'
                              ? idx === 0
                                ? 'bg-emerald-600'
                                : 'bg-sky-600'
                              : idx === 0
                              ? 'bg-amber-500'
                              : 'bg-indigo-600'
                          }`}
                        />
                      </div>
                      <span className="text-[10px] font-mono text-slate-500 w-8 text-right font-semibold">
                        {percent}%
                      </span>
                    </div>
                  </td>
                  <td className={`py-3 px-3 text-right font-mono text-xs transition-colors ${
                    sortBy === 'revenue'
                      ? 'bg-emerald-50 text-emerald-800 font-black'
                      : 'text-slate-700 font-semibold'
                  }`}>
                    {item.revenue.toLocaleString('vi-VN')} đ
                  </td>
                  <td className="py-3 px-3 text-center">
                    <span
                      className={`px-2 py-0.5 rounded text-[10px] font-mono font-bold ${
                        item.currentStock < 20
                          ? 'bg-rose-50 text-rose-700 border border-rose-200'
                          : 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                      }`}
                    >
                      {item.currentStock} pcs
                    </span>
                  </td>
                  <td className="py-3 px-3 text-center" onClick={(e) => e.stopPropagation()}>
                    <button
                      onClick={() => setSelectedAuditItem(item)}
                      title="Kiểm tra chi tiết danh sách đơn hàng đã mua sản phẩm này"
                      className="px-2 py-1 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 flex items-center gap-1 mx-auto font-medium text-[10px] cursor-pointer transition-colors"
                    >
                      <Eye className="w-3 h-3" />
                      <span>Xem đơn</span>
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      )}

      {/* Modal Audit & Kiểm tra đối chiếu số lượng và tiền thực tế */}
      {selectedAuditItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-xs animate-in fade-in duration-200">
          <div className="w-full max-w-3xl bg-white border border-slate-200 rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
            {/* Modal Header */}
            <div className="p-5 border-b border-slate-200 flex items-center justify-between bg-slate-50">
              <div className="flex items-center gap-3">
                {selectedAuditItem.thumbnailUrl && (
                  <img
                    src={selectedAuditItem.thumbnailUrl}
                    alt={selectedAuditItem.name}
                    className="w-12 h-14 object-cover rounded-xl border border-slate-200 bg-white shrink-0"
                  />
                )}
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-emerald-50 text-emerald-700 border border-emerald-200 font-bold">
                      ĐỐI CHIẾU NGUỒN ĐƠN
                    </span>
                    <span className="text-xs text-slate-500 font-semibold">
                      {selectedAuditItem.categoryName}
                    </span>
                  </div>
                  <h3 className="text-base font-bold text-slate-900 mt-1 line-clamp-1">
                    {selectedAuditItem.name}
                  </h3>
                </div>
              </div>
              <button
                onClick={() => setSelectedAuditItem(null)}
                className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-200 transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Summary KPI Cards */}
            <div className="grid grid-cols-3 gap-3 p-5 bg-white border-b border-slate-200">
              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                <div className="text-[11px] text-slate-500 font-medium">Tổng sản lượng bán</div>
                <div className="text-xl font-black text-amber-700 mt-1 font-mono">
                  {selectedAuditItem.soldQuantity.toLocaleString('vi-VN')} pcs
                </div>
              </div>
              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                <div className="text-[11px] text-slate-500 font-medium">Tổng doanh thu thực tế</div>
                <div className="text-xl font-black text-emerald-700 mt-1 font-mono">
                  {selectedAuditItem.revenue.toLocaleString('vi-VN')} ₫
                </div>
              </div>
              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                <div className="text-[11px] text-slate-500 font-medium">Số đơn phát sinh</div>
                <div className="text-xl font-black text-sky-700 mt-1 font-mono">
                  {selectedAuditItem.orders.length} đơn hàng
                </div>
              </div>
            </div>

            {/* Order List Breakdown Table */}
            <div className="p-5 overflow-y-auto flex-1 bg-white">
              <div className="text-xs text-slate-700 font-bold mb-3 flex items-center justify-between">
                <span>Danh sách đơn hàng thực tế đóng góp (Khớp 100% doanh thu):</span>
                <span className="text-[11px] text-slate-500 font-normal">
                  Lọc theo: {statusFilter === 'realized' ? 'Hoàn thành / Đã thanh toán' : statusFilter === 'completed' ? 'Đã hoàn tất' : 'Tất cả đơn hợp lệ'}
                </span>
              </div>

              {selectedAuditItem.orders.length === 0 ? (
                <div className="py-8 text-center text-slate-500 text-xs">
                  Chưa có thông tin đơn hàng chi tiết.
                </div>
              ) : (
                <div className="overflow-x-auto rounded-xl border border-slate-200">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-50 text-slate-600 font-bold border-b border-slate-200">
                      <tr>
                        <th className="py-2.5 px-3">Mã đơn</th>
                        <th className="py-2.5 px-3">Khách hàng</th>
                        <th className="py-2.5 px-3">Phân loại</th>
                        <th className="py-2.5 px-3 text-center">Trạng thái</th>
                        <th className="py-2.5 px-3 text-right">Đơn giá</th>
                        <th className="py-2.5 px-3 text-right">SL</th>
                        <th className="py-2.5 px-3 text-right">Thành tiền</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 text-slate-700">
                      {selectedAuditItem.orders.map((ord, i) => (
                        <tr key={`${ord.orderId}-${i}`} className="hover:bg-slate-50">
                          <td className="py-2.5 px-3 font-mono font-bold text-sky-700">
                            #{ord.orderCode}
                          </td>
                          <td className="py-2.5 px-3">
                            <div className="font-semibold text-slate-900">{ord.customerName}</div>
                            {ord.phone && <div className="text-[10px] text-slate-400">{ord.phone}</div>}
                          </td>
                          <td className="py-2.5 px-3 text-slate-600">
                            {ord.size} / {ord.color}
                          </td>
                          <td className="py-2.5 px-3 text-center">
                            <span className="px-2 py-0.5 rounded text-[10px] font-mono font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                              {ord.status}
                            </span>
                          </td>
                          <td className="py-2.5 px-3 text-right font-mono">
                            {ord.unitPrice.toLocaleString('vi-VN')} ₫
                          </td>
                          <td className="py-2.5 px-3 text-right font-mono font-bold text-amber-700">
                            x{ord.quantity}
                          </td>
                          <td className="py-2.5 px-3 text-right font-mono font-bold text-emerald-700">
                            {ord.lineTotal.toLocaleString('vi-VN')} ₫
                          </td>
                        </tr>
                      ))}
                    </tbody>
                    <tfoot className="bg-slate-50 font-bold text-slate-900 border-t border-slate-200">
                      <tr>
                        <td colSpan={5} className="py-3 px-3 text-right text-slate-600">
                          TỔNG CỘNG ĐỐI CHIẾU:
                        </td>
                        <td className="py-3 px-3 text-right font-mono text-amber-700">
                          {selectedAuditItem.soldQuantity.toLocaleString('vi-VN')} pcs
                        </td>
                        <td className="py-3 px-3 text-right font-mono text-emerald-700 text-sm">
                          {selectedAuditItem.revenue.toLocaleString('vi-VN')} ₫
                        </td>
                      </tr>
                    </tfoot>
                  </table>
                </div>
              )}
            </div>

            {/* Modal Footer */}
            <div className="p-4 border-t border-slate-200 bg-slate-50 flex items-center justify-between">
              <span className="text-[11px] text-slate-500 flex items-center gap-1.5 font-medium">
                <span className="w-2 h-2 rounded-full bg-emerald-500 inline-block"></span>
                Số liệu đối chiếu khớp 100% với đơn hàng thực tế
              </span>
              <button
                onClick={() => setSelectedAuditItem(null)}
                className="px-4 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold cursor-pointer transition-colors shadow-2xs"
              >
                Đóng cửa sổ
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
