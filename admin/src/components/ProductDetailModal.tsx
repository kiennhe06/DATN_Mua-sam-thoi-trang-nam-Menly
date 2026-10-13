'use client';

import React, { useState, useMemo } from 'react';
import { Product, ProductVariant } from '../lib/types';
import { adjustInventory } from '../lib/api';
import { getColorHex } from './CompactVariantDisplay';
import { Boxes, Sparkles, SlidersHorizontal, Palette, CheckCircle2, AlertCircle, X } from 'lucide-react';

interface ProductDetailModalProps {
  product: Product | null;
  onClose: () => void;
  onStockAdjusted?: () => void;
}

export function ProductDetailModal({ product, onClose, onStockAdjusted }: ProductDetailModalProps) {
  const [selectedSize, setSelectedSize] = useState<string | null>(null);
  const [selectedColor, setSelectedColor] = useState<string | null>(null);
  const [adjustingVariant, setAdjustingVariant] = useState<ProductVariant | null>(null);
  const [deltaAmount, setDeltaAmount] = useState<number>(10);
  const [adjustReason, setAdjustReason] = useState<'admin_restock' | 'admin_correction'>('admin_restock');
  const [loading, setLoading] = useState(false);
  const [feedback, setFeedback] = useState<{ text: string; success: boolean } | null>(null);

  const variants: ProductVariant[] = useMemo(() => {
    if (!product) return [];
    if (product.variants?.length) return product.variants;
    return [
      { id: 'v-w-m', productId: product.id, size: 'M', color: 'Trắng', sku: `SKU-${product.id.slice(0, 4)}-W-M`, stock: 35 },
      { id: 'v-b-m', productId: product.id, size: 'M', color: 'Đen', sku: `SKU-${product.id.slice(0, 4)}-B-M`, stock: 30 },
      { id: 'v-w-l', productId: product.id, size: 'L', color: 'Trắng', sku: `SKU-${product.id.slice(0, 4)}-W-L`, stock: 40 },
      { id: 'v-b-l', productId: product.id, size: 'L', color: 'Đen', sku: `SKU-${product.id.slice(0, 4)}-B-L`, stock: 45 },
      { id: 'v-w-xl', productId: product.id, size: 'XL', color: 'Trắng', sku: `SKU-${product.id.slice(0, 4)}-W-XL`, stock: 25 },
      { id: 'v-b-xl', productId: product.id, size: 'XL', color: 'Đen', sku: `SKU-${product.id.slice(0, 4)}-B-XL`, stock: 20 },
    ];
  }, [product]);

  // Aggregate Unique Sizes (Bên trên là Size)
  const uniqueSizes = useMemo(() => {
    const list: { size: string; count: number; stock: number }[] = [];
    const map = new Map<string, { count: number; stock: number }>();
    for (const v of variants) {
      const s = (v.size || '').trim();
      if (!s) continue;
      const curr = map.get(s) || { count: 0, stock: 0 };
      curr.count += 1;
      curr.stock += v.stock || 0;
      map.set(s, curr);
    }
    for (const [size, info] of map.entries()) {
      list.push({ size, count: info.count, stock: info.stock });
    }
    return list;
  }, [variants]);

  // Aggregate Unique Colors (Bên dưới là Màu)
  const uniqueColors = useMemo(() => {
    const list: { color: string; count: number; stock: number }[] = [];
    const map = new Map<string, { count: number; stock: number }>();
    for (const v of variants) {
      const c = (v.color || '').trim();
      if (!c) continue;
      const curr = map.get(c) || { count: 0, stock: 0 };
      curr.count += 1;
      curr.stock += v.stock || 0;
      map.set(c, curr);
    }
    for (const [color, info] of map.entries()) {
      list.push({ color, count: info.count, stock: info.stock });
    }
    return list;
  }, [variants]);

  // Filtered variants based on selected size and selected color
  const filteredVariants = useMemo(() => {
    return variants.filter((v) => {
      const matchSize = selectedSize ? v.size === selectedSize : true;
      const matchColor = selectedColor ? v.color === selectedColor : true;
      return matchSize && matchColor;
    });
  }, [variants, selectedSize, selectedColor]);

  if (!product) return null;

  const totalStock = variants.reduce((sum, v) => sum + v.stock, 0);

  const handleAdjustSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!adjustingVariant) return;
    setLoading(true);
    setFeedback(null);
    try {
      await adjustInventory(adjustingVariant.id, deltaAmount, adjustReason);
      setFeedback({
        text: `Đã cập nhật tồn kho size ${adjustingVariant.size} - màu ${adjustingVariant.color || 'Tiêu chuẩn'} thành công!`,
        success: true,
      });
      adjustingVariant.stock = Math.max(0, adjustingVariant.stock + deltaAmount);
      setTimeout(() => {
        setAdjustingVariant(null);
        if (onStockAdjusted) onStockAdjusted();
      }, 1000);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Lỗi khi cập nhật kho';
      setFeedback({ text: msg, success: false });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-xs">
      <div className="bg-white border border-slate-200 rounded-3xl w-full max-w-2xl max-h-[90vh] overflow-y-auto shadow-2xl text-slate-800 p-6 space-y-5">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-amber-500"></span>
            <h3 className="text-base font-bold text-slate-900">Chi tiết Sản phẩm & Phân loại Tồn kho</h3>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-slate-100 text-slate-500 hover:text-slate-900 hover:bg-slate-200 flex items-center justify-center cursor-pointer transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Product Basic Info Card */}
        <div className="flex flex-col sm:flex-row gap-4 bg-slate-50 border border-slate-200 p-4 rounded-2xl">
          <img
            src={product.thumbnailUrl || undefined}
            alt={product.name}
            className="w-20 h-28 object-cover rounded-xl border border-slate-200 shrink-0 bg-white"
          />
          <div className="space-y-1.5 flex-1 min-w-0">
            <h4 className="text-sm font-bold text-slate-900 line-clamp-1">{product.name}</h4>
            <div className="flex items-center gap-3 text-xs">
              <span className="font-mono text-amber-700 font-bold">{product.price.toLocaleString('vi-VN')} đ</span>
              <span className="bg-white border border-slate-200 px-2 py-0.5 rounded text-slate-700 font-mono text-[10px]">
                Tổng tồn: <strong className="text-emerald-700">{totalStock}</strong>
              </span>
            </div>
            <p className="text-xs text-slate-500 line-clamp-2">
              {product.description || 'Chất liệu thời trang cao cấp, form tôn dáng nam tính.'}
            </p>
          </div>
        </div>

        {/* Interactive Classification Box (Two-tiered: Size on top, Color below) */}
        <div className="bg-slate-50 border border-slate-200 p-4 rounded-2xl space-y-4">
          {/* Top Section: KÍCH THƯỚC (SIZE) */}
          <div className="space-y-2">
            <div className="flex items-center justify-between text-xs font-semibold text-slate-700">
              <span className="flex items-center gap-1.5 font-bold">
                <SlidersHorizontal className="w-3.5 h-3.5 text-amber-600" />
                <span>Kích thước:</span>
                {selectedSize && (
                  <span className="text-amber-800 font-bold ml-1">({selectedSize})</span>
                )}
              </span>
              {selectedSize && (
                <button
                  type="button"
                  onClick={() => setSelectedSize(null)}
                  className="text-[11px] text-amber-700 hover:underline cursor-pointer font-medium"
                >
                  Tất cả kích thước
                </button>
              )}
            </div>

            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                onClick={() => setSelectedSize(null)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold border transition-all cursor-pointer ${
                  selectedSize === null
                    ? 'bg-amber-500 text-slate-950 border-amber-500 shadow-2xs font-extrabold'
                    : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-100'
                }`}
              >
                Tất cả ({variants.length})
              </button>

              {uniqueSizes.map((s) => (
                <button
                  key={s.size}
                  type="button"
                  onClick={() => setSelectedSize(selectedSize === s.size ? null : s.size)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 border transition-all cursor-pointer ${
                    selectedSize === s.size
                      ? 'bg-amber-500 text-slate-950 border-amber-500 shadow-2xs font-extrabold'
                      : 'bg-white text-slate-700 border-slate-200 hover:bg-slate-100'
                  }`}
                >
                  <span>Size {s.size}</span>
                  <span
                    className={`px-1.5 py-0.5 rounded text-[10px] font-mono ${
                      selectedSize === s.size
                        ? 'bg-amber-600 text-white font-bold'
                        : 'bg-slate-100 text-emerald-700 font-semibold'
                    }`}
                  >
                    {s.stock}
                  </span>
                </button>
              ))}
            </div>
          </div>

          {/* Bottom Section: MÀU SẮC (COLOR) */}
          {uniqueColors.length > 0 && (
            <div className="space-y-2 pt-2 border-t border-slate-200">
              <div className="flex items-center justify-between text-xs font-semibold text-slate-700">
                <span className="flex items-center gap-1.5 font-bold">
                  <Palette className="w-3.5 h-3.5 text-amber-600" />
                  <span>Màu sắc:</span>
                  {selectedColor && (
                    <span className="text-amber-800 font-bold ml-1">({selectedColor})</span>
                  )}
                </span>
                {selectedColor && (
                  <button
                    type="button"
                    onClick={() => setSelectedColor(null)}
                    className="text-[11px] text-amber-700 hover:underline cursor-pointer font-medium"
                  >
                    Tất cả màu
                  </button>
                )}
              </div>

              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  onClick={() => setSelectedColor(null)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold border transition-all cursor-pointer ${
                    selectedColor === null
                      ? 'bg-amber-500 text-slate-950 border-amber-500 shadow-2xs font-extrabold'
                      : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-100'
                  }`}
                >
                  Tất cả màu
                </button>

                {uniqueColors.map((c) => (
                  <button
                    key={c.color}
                    type="button"
                    onClick={() => setSelectedColor(selectedColor === c.color ? null : c.color)}
                    className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 border transition-all cursor-pointer ${
                      selectedColor === c.color
                        ? 'bg-amber-500 text-slate-950 border-amber-500 shadow-2xs font-extrabold'
                        : 'bg-white text-slate-700 border-slate-200 hover:bg-slate-100'
                    }`}
                  >
                    <span
                      className="w-2.5 h-2.5 rounded-full border border-slate-300 shrink-0"
                      style={{ backgroundColor: getColorHex(c.color) }}
                    />
                    <span>{c.color}</span>
                    <span
                      className={`px-1.5 py-0.5 rounded text-[10px] font-mono ${
                        selectedColor === c.color
                          ? 'bg-amber-600 text-white font-bold'
                          : 'bg-slate-100 text-slate-600'
                      }`}
                    >
                      {c.stock}
                    </span>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Variants Breakdown Table */}
        <div className="space-y-2">
          <div className="flex items-center justify-between text-xs font-bold text-slate-700 uppercase tracking-wider">
            <h5 className="flex items-center gap-1.5">
              <Boxes className="w-3.5 h-3.5 text-amber-600" />
              Chi tiết biến thể ({filteredVariants.length} phân loại)
            </h5>
            {(selectedSize || selectedColor) && (
              <button
                type="button"
                onClick={() => {
                  setSelectedSize(null);
                  setSelectedColor(null);
                }}
                className="text-[11px] text-amber-700 hover:underline cursor-pointer lowercase font-medium"
              >
                xem toàn bộ ({variants.length})
              </button>
            )}
          </div>

          <div className="border border-slate-200 rounded-2xl overflow-hidden divide-y divide-slate-100 bg-white">
            {filteredVariants.length === 0 ? (
              <div className="p-6 text-center text-slate-400 text-xs">
                Không tìm thấy biến thể nào phù hợp với Size {selectedSize || ''} và Màu {selectedColor || ''}.
              </div>
            ) : (
              filteredVariants.map((v) => (
                <div
                  key={v.id}
                  className="p-3 bg-white flex items-center justify-between gap-3 hover:bg-slate-50 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <span className="w-9 h-9 rounded-xl bg-slate-900 text-white font-black text-xs flex items-center justify-center shadow-2xs">
                      {v.size}
                    </span>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-bold text-slate-900">{v.sku}</span>
                        <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-slate-100 border border-slate-200 text-[10px] text-slate-700 font-medium">
                          <span
                            className="w-2 h-2 rounded-full border border-slate-300"
                            style={{ backgroundColor: getColorHex(v.color) }}
                          />
                          {v.color || 'Tiêu chuẩn'}
                        </span>
                      </div>
                      <div className="text-[10px] text-slate-400 font-mono mt-0.5">
                        ID: {v.id.slice(0, 18)}...
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <span
                      className={`text-xs font-bold font-mono px-2 py-0.5 rounded border ${
                        v.stock > 20
                          ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                          : 'bg-amber-50 text-amber-700 border-amber-200'
                      }`}
                    >
                      {v.stock} cái
                    </span>
                    <button
                      type="button"
                      onClick={() => {
                        setAdjustingVariant(v);
                        setDeltaAmount(10);
                        setFeedback(null);
                      }}
                      className="px-2.5 py-1 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-bold border border-slate-200 transition-all cursor-pointer"
                    >
                      Chỉnh kho
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Quick Stock Adjust Form Inline */}
        {adjustingVariant && (
          <form
            onSubmit={handleAdjustSubmit}
            className="p-4 rounded-2xl bg-amber-50/50 border border-amber-200 space-y-3"
          >
            <div className="flex items-center justify-between">
              <h6 className="font-bold text-xs text-amber-800 uppercase flex items-center gap-1.5">
                <Sparkles className="w-3.5 h-3.5 text-amber-600" /> Chỉnh kho Size {adjustingVariant.size} - Màu{' '}
                {adjustingVariant.color || 'Tiêu chuẩn'} ({adjustingVariant.sku})
              </h6>
              <button
                type="button"
                onClick={() => setAdjustingVariant(null)}
                className="text-xs text-slate-500 hover:text-slate-800 cursor-pointer font-medium"
              >
                Hủy
              </button>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-[10px] text-slate-600 font-semibold block mb-1">Số lượng thay đổi (+/-)</label>
                <input
                  type="number"
                  required
                  value={deltaAmount}
                  onChange={(e) => setDeltaAmount(Number(e.target.value))}
                  className="w-full px-2.5 py-1.5 bg-white border border-slate-300 rounded-lg text-xs text-slate-900 font-mono focus:outline-none focus:border-amber-500"
                />
              </div>
              <div>
                <label className="text-[10px] text-slate-600 font-semibold block mb-1">Lý do</label>
                <select
                  value={adjustReason}
                  onChange={(e) => setAdjustReason(e.target.value as 'admin_restock' | 'admin_correction')}
                  className="w-full px-2.5 py-1.5 bg-white border border-slate-300 rounded-lg text-xs text-slate-900 focus:outline-none focus:border-amber-500 cursor-pointer"
                >
                  <option value="admin_restock">Nhập thêm hàng</option>
                  <option value="admin_correction">Hiệu chỉnh kiểm kê</option>
                </select>
              </div>
            </div>
            {feedback && (
              <div
                className={`p-2.5 rounded-lg text-xs flex items-center gap-2 ${
                  feedback.success
                    ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                    : 'bg-rose-50 text-rose-800 border border-rose-200'
                }`}
              >
                {feedback.success ? <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" /> : <AlertCircle className="w-3.5 h-3.5 text-rose-600" />}
                <span className="font-semibold">{feedback.text}</span>
              </div>
            )}
            <button
              type="submit"
              disabled={loading}
              className="w-full py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold text-xs shadow-2xs transition-colors cursor-pointer disabled:opacity-50"
            >
              {loading
                ? 'Đang lưu...'
                : `Xác nhận điều chỉnh: Size ${adjustingVariant.size} - ${adjustingVariant.color || 'Tiêu chuẩn'}`}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
