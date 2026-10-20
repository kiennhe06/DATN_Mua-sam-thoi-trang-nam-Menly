'use client';

import React from 'react';
import { Eye } from 'lucide-react';
import { Product, Category } from '../../lib/types';
import { CompactVariantDisplay } from '../CompactVariantDisplay';
import { getProductStock } from '../../hooks/useProducts';

interface ProductTableViewProps {
  products: Product[];
  categories: Category[];
  sortBy: string;
  getProductCategory: (p: Product) => Category;
  onUpdateCategory: (productId: string, categoryId: string) => void;
  onViewDetail: (product: Product) => void;
}

export function ProductTableView({
  products,
  categories,
  sortBy,
  getProductCategory,
  onUpdateCategory,
  onViewDetail,
}: ProductTableViewProps) {
  return (
    <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-2xs">
      <div className="p-4 border-b border-slate-200 flex items-center justify-between text-xs text-slate-500 font-medium bg-slate-50">
        <span className="font-bold text-slate-800">Hiển thị {products.length} sản phẩm</span>
        <span>Sắp xếp theo: {sortBy}</span>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs">
          <thead>
            <tr className="bg-slate-50/70 text-slate-500 font-bold border-b border-slate-200">
              <th className="py-3 px-4">Hình ảnh</th>
              <th className="py-3 px-4">Tên sản phẩm</th>
              <th className="py-3 px-4">Danh mục phân loại</th>
              <th className="py-3 px-4">Đơn giá</th>
              <th className="py-3 px-4">Biến thể & Tồn kho</th>
              <th className="py-3 px-4 text-center">Hành động</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-slate-700">
            {products.map((p) => {
              const cat = getProductCategory(p);
              const totalStock = getProductStock(p);
              return (
                <tr key={p.id} className="hover:bg-slate-50 transition-colors">
                  <td className="py-3 px-4">
                    <img
                      src={p.thumbnailUrl || undefined}
                      alt={p.name}
                      className="w-12 h-14 object-cover rounded-lg border border-slate-200 bg-slate-100"
                    />
                  </td>
                  <td className="py-3 px-4 max-w-xs">
                    <p className="font-bold text-slate-900 line-clamp-1">{p.name}</p>
                    <p className="text-xs font-mono text-slate-400 line-clamp-1">{p.slug}</p>
                  </td>
                  <td className="py-3 px-4">
                    <select
                      value={cat.id}
                      onChange={(e) => onUpdateCategory(p.id, e.target.value)}
                      className="bg-white border border-slate-300 rounded-lg px-2 py-1 text-xs text-slate-800 font-medium focus:outline-none focus:border-amber-500 cursor-pointer"
                    >
                      {categories.map((c) => (
                        <option key={c.id} value={c.id}>
                          {c.name}
                        </option>
                      ))}
                    </select>
                  </td>
                  <td className="py-3 px-4 font-bold text-slate-900 font-mono text-xs">
                    {p.price.toLocaleString('vi-VN')} đ
                  </td>
                  <td className="py-3 px-4 min-w-[200px]">
                    <div className="flex items-start justify-between gap-2">
                      <CompactVariantDisplay variants={p.variants} />
                      <span className="text-[10px] bg-emerald-50 text-emerald-700 px-1.5 py-0.5 rounded font-mono font-bold border border-emerald-200 shrink-0 mt-0.5">
                        {totalStock} pcs
                      </span>
                    </div>
                  </td>
                  <td className="py-3 px-4 text-center">
                    <button
                      onClick={() => onViewDetail(p)}
                      className="px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 transition-all font-semibold text-xs flex items-center gap-1 mx-auto cursor-pointer"
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
  );
}
