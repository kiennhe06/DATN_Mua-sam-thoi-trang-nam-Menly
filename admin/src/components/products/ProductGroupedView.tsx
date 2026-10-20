'use client';

import React from 'react';
import { Eye } from 'lucide-react';
import { Product, Category } from '../../lib/types';
import { CompactVariantDisplay } from '../CompactVariantDisplay';
import { getProductStock } from '../../hooks/useProducts';

interface ProductGroupedViewProps {
  groups: { category: Category; items: Product[] }[];
  categories: Category[];
  onSelectCategory: (categoryId: string) => void;
  onUpdateCategory: (productId: string, categoryId: string) => void;
  onViewDetail: (product: Product) => void;
}

export function ProductGroupedView({
  groups,
  categories,
  onSelectCategory,
  onUpdateCategory,
  onViewDetail,
}: ProductGroupedViewProps) {
  return (
    <div className="space-y-6">
      {groups.map((group) => (
        <div
          key={group.category.id}
          className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-2xs"
        >
          {/* Category Group Header */}
          <div className="p-4 bg-slate-50 border-b border-slate-200 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <span className="w-2.5 h-2.5 rounded-full bg-amber-500 shadow-2xs"></span>
              <h3 className="font-bold text-slate-900 text-sm tracking-wide">
                {group.category.name}
              </h3>
              <span className="bg-amber-50 text-amber-800 border border-amber-200 px-2 py-0.5 rounded-full text-[11px] font-mono font-bold">
                {group.items.length} sản phẩm
              </span>
            </div>
            <button
              onClick={() => onSelectCategory(group.category.id)}
              className="text-xs text-slate-500 hover:text-amber-700 transition-colors font-medium flex items-center gap-1 cursor-pointer"
            >
              Xem riêng danh mục này →
            </button>
          </div>

          {/* Table for this Category */}
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="bg-slate-50/70 text-slate-500 font-bold border-b border-slate-200">
                  <th className="py-2.5 px-4">Hình ảnh</th>
                  <th className="py-2.5 px-4">Tên sản phẩm</th>
                  <th className="py-2.5 px-4">Chuyển Danh mục</th>
                  <th className="py-2.5 px-4">Đơn giá</th>
                  <th className="py-2.5 px-4">Biến thể & Tồn kho</th>
                  <th className="py-2.5 px-4 text-center">Hành động</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-slate-700">
                {group.items.map((p) => {
                  const totalStock = getProductStock(p);
                  return (
                    <tr key={p.id} className="hover:bg-slate-50 transition-colors">
                      <td className="py-2.5 px-4">
                        <img
                          src={p.thumbnailUrl || undefined}
                          alt={p.name}
                          className="w-12 h-14 object-cover rounded-lg border border-slate-200 bg-slate-100"
                        />
                      </td>
                      <td className="py-2.5 px-4 max-w-xs">
                        <p className="font-bold text-slate-900 line-clamp-1">{p.name}</p>
                        <p className="text-[11px] font-mono text-slate-400 line-clamp-1">
                          {p.slug}
                        </p>
                      </td>
                      <td className="py-2.5 px-4">
                        <select
                          value={group.category.id}
                          onChange={(e) => onUpdateCategory(p.id, e.target.value)}
                          className="bg-white border border-slate-300 rounded-lg px-2 py-1 text-[11px] text-slate-800 font-medium focus:outline-none focus:border-amber-500 cursor-pointer"
                        >
                          {categories.map((c) => (
                            <option key={c.id} value={c.id}>
                              {c.name}
                            </option>
                          ))}
                        </select>
                      </td>
                      <td className="py-2.5 px-4 font-bold text-slate-900 font-mono text-xs">
                        {p.price.toLocaleString('vi-VN')} đ
                      </td>
                      <td className="py-2.5 px-4 min-w-[200px]">
                        <div className="flex items-start justify-between gap-2">
                          <CompactVariantDisplay variants={p.variants} />
                          <span className="text-[10px] bg-emerald-50 text-emerald-700 px-1.5 py-0.5 rounded font-mono font-bold border border-emerald-200 shrink-0 mt-0.5">
                            {totalStock} pcs
                          </span>
                        </div>
                      </td>
                      <td className="py-2.5 px-4 text-center">
                        <button
                          onClick={() => onViewDetail(p)}
                          className="px-2.5 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 transition-all font-semibold text-xs flex items-center gap-1 mx-auto cursor-pointer"
                        >
                          <Eye className="w-3.5 h-3.5" /> Chi tiết
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      ))}
    </div>
  );
}
