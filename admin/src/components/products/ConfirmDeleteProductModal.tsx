'use client';

import React from 'react';
import { Product } from '../../lib/types';
import { AlertTriangle, Trash2, X } from 'lucide-react';
import { getProductStock } from '../../hooks/useProducts';

interface ConfirmDeleteProductModalProps {
  product: Product | null;
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
}

export function ConfirmDeleteProductModal({
  product,
  isOpen,
  onClose,
  onConfirm,
}: ConfirmDeleteProductModalProps) {
  if (!isOpen || !product) return null;

  const totalStock = getProductStock(product);
  const variantCount = product.variants?.length || 0;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-150">
      <div className="bg-white border border-slate-200 rounded-3xl w-full max-w-md overflow-hidden shadow-2xl animate-in zoom-in-95 duration-150 text-slate-800">
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-rose-50/50">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-rose-100 border border-rose-200 flex items-center justify-center text-rose-600 shrink-0">
              <AlertTriangle className="w-5 h-5 stroke-[2.5]" />
            </div>
            <div>
              <h3 className="font-bold text-slate-900 text-sm">Xác nhận xóa sản phẩm</h3>
              <p className="text-[11px] text-slate-500">Hành động này không thể hoàn tác</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-xl text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Body */}
        <div className="p-6 space-y-4">
          <p className="text-xs text-slate-600 leading-relaxed">
            Bạn có chắc chắn muốn xóa vĩnh viễn sản phẩm sau khỏi hệ thống không? Toàn bộ biến thể phân loại và thư viện hình ảnh đi kèm sẽ bị loại bỏ hoàn toàn:
          </p>

          {/* Product Mini Card */}
          <div className="p-3.5 bg-slate-50 border border-slate-200 rounded-2xl flex items-center gap-3">
            <img
              src={product.thumbnailUrl || product.images?.[0]?.url || undefined}
              alt={product.name}
              referrerPolicy="no-referrer"
              className="w-14 h-16 object-cover rounded-xl border border-slate-200 bg-white shrink-0"
            />
            <div className="flex-1 min-w-0 space-y-1">
              <h4 className="font-bold text-slate-900 text-xs truncate">{product.name}</h4>
              <p className="text-[11px] font-mono text-slate-400 truncate">{product.slug}</p>
              <div className="flex items-center gap-2 text-[10px]">
                <span className="font-bold text-amber-700 font-mono">
                  {product.price.toLocaleString('vi-VN')} đ
                </span>
                <span className="text-slate-400">•</span>
                <span className="text-slate-600 font-medium">
                  {variantCount} biến thể ({totalStock} cái)
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="px-6 py-4 bg-slate-50 border-t border-slate-100 flex items-center justify-end gap-2.5">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-xl bg-white hover:bg-slate-100 text-slate-700 border border-slate-200 text-xs font-semibold transition-colors cursor-pointer"
          >
            Hủy bỏ
          </button>
          <button
            type="button"
            onClick={onConfirm}
            className="px-4 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold transition-all shadow-sm flex items-center gap-1.5 cursor-pointer"
          >
            <Trash2 className="w-3.5 h-3.5" />
            <span>Xác nhận xóa</span>
          </button>
        </div>
      </div>
    </div>
  );
}
