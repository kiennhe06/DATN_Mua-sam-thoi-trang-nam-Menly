'use client';

import React, { useState, useEffect } from 'react';
import { Category, CreateProductInput, Product } from '../lib/types';
import { createAdminProduct } from '../lib/api';
import {
  X,
  Plus,
  Trash2,
  Upload,
  Image as ImageIcon,
  Boxes,
  Sparkles,
  Layers,
  CheckCircle2,
  AlertCircle,
  Tag,
  DollarSign,
  FileText,
} from 'lucide-react';

interface CreateProductModalProps {
  isOpen: boolean;
  onClose: () => void;
  categories: Category[];
  onProductCreated: (product: Product) => void;
}

const COMMON_SIZES = ['S', 'M', 'L', 'XL', '2XL'];
const COMMON_COLORS = ['Trắng', 'Đen', 'Xanh Navy', 'Ghi Xám', 'Be'];

function generateSlug(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}

export function CreateProductModal({
  isOpen,
  onClose,
  categories,
  onProductCreated,
}: CreateProductModalProps) {
  const [name, setName] = useState('');
  const [slug, setSlug] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [price, setPrice] = useState<number | ''>(250000);
  const [description, setDescription] = useState('');
  const [thumbnailUrl, setThumbnailUrl] = useState('');
  const [images, setImages] = useState<string[]>([]);
  const [newImageUrl, setNewImageUrl] = useState('');

  // Variants state
  const [variants, setVariants] = useState<
    { size: string; color: string; sku: string; stock: number }[]
  >([
    { size: 'M', color: 'Trắng', sku: '', stock: 50 },
    { size: 'L', color: 'Trắng', sku: '', stock: 50 },
    { size: 'M', color: 'Đen', sku: '', stock: 50 },
    { size: 'L', color: 'Đen', sku: '', stock: 50 },
  ]);

  // Quick generator selections
  const [selectedSizes, setSelectedSizes] = useState<string[]>(['M', 'L']);
  const [selectedColors, setSelectedColors] = useState<string[]>(['Trắng', 'Đen']);
  const [defaultStock, setDefaultStock] = useState<number>(50);

  // Custom single variant inputs
  const [customSize, setCustomSize] = useState('XL');
  const [customColor, setCustomColor] = useState('Xanh Navy');
  const [customStock, setCustomStock] = useState(50);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Initialize category
  useEffect(() => {
    if (categories.length > 0 && !categoryId) {
      setCategoryId(categories[0].id);
    }
  }, [categories, categoryId]);

  // Auto-generate slug when name changes (unless user edited slug separately)
  const handleNameChange = (val: string) => {
    setName(val);
    setSlug(generateSlug(val));
  };

  // Add single variant
  const handleAddCustomVariant = () => {
    if (!customSize.trim() || !customColor.trim()) return;
    const exists = variants.some(
      (v) =>
        v.size.toLowerCase() === customSize.trim().toLowerCase() &&
        v.color.toLowerCase() === customColor.trim().toLowerCase()
    );
    if (exists) {
      setError(`Biến thể Size ${customSize} - Màu ${customColor} đã tồn tại trong danh sách`);
      setTimeout(() => setError(null), 3000);
      return;
    }
    const currentSlug = slug || generateSlug(name) || 'prod';
    setVariants((prev) => [
      ...prev,
      {
        size: customSize.trim(),
        color: customColor.trim(),
        sku: `${currentSlug}-${customSize.trim()}-${customColor.trim()}`.toLowerCase(),
        stock: customStock > 0 ? customStock : 0,
      },
    ]);
  };

  // Quick generate matrix
  const handleBulkGenerateVariants = () => {
    if (selectedSizes.length === 0 || selectedColors.length === 0) {
      setError('Vui lòng chọn ít nhất 1 size và 1 màu để tạo hàng loạt');
      setTimeout(() => setError(null), 3000);
      return;
    }

    const currentSlug = slug || generateSlug(name) || 'prod';
    const newItems: { size: string; color: string; sku: string; stock: number }[] = [];

    selectedColors.forEach((c) => {
      selectedSizes.forEach((s) => {
        newItems.push({
          size: s,
          color: c,
          sku: `${currentSlug}-${s}-${c}`.toLowerCase(),
          stock: defaultStock > 0 ? defaultStock : 50,
        });
      });
    });

    setVariants(newItems);
  };

  const handleRemoveVariant = (index: number) => {
    setVariants((prev) => prev.filter((_, i) => i !== index));
  };

  const handleUpdateVariantStock = (index: number, stock: number) => {
    setVariants((prev) =>
      prev.map((v, i) => (i === index ? { ...v, stock: Math.max(0, stock) } : v))
    );
  };

  // Image handling
  const handleAddImageUrl = () => {
    if (!newImageUrl.trim()) return;
    if (!thumbnailUrl) {
      setThumbnailUrl(newImageUrl.trim());
    }
    setImages((prev) => [...prev, newImageUrl.trim()]);
    setNewImageUrl('');
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length === 0) return;

    Array.from(files).forEach((file) => {
      const reader = new FileReader();
      reader.onload = (event) => {
        const url = event.target?.result as string;
        if (url) {
          if (!thumbnailUrl) {
            setThumbnailUrl(url);
          }
          setImages((prev) => [...prev, url]);
        }
      };
      reader.readAsDataURL(file);
    });
  };

  const handleRemoveImage = (index: number) => {
    setImages((prev) => {
      const next = prev.filter((_, i) => i !== index);
      if (thumbnailUrl === prev[index]) {
        setThumbnailUrl(next[0] || '');
      }
      return next;
    });
  };

  // Form submit
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);

    if (!name.trim()) {
      setError('Vui lòng nhập tên sản phẩm');
      return;
    }
    if (!categoryId) {
      setError('Vui lòng chọn danh mục cho sản phẩm');
      return;
    }
    if (!price || Number(price) <= 0) {
      setError('Vui lòng nhập giá bán hợp lệ (> 0 VNĐ)');
      return;
    }
    if (variants.length === 0) {
      setError('Vui lòng thêm ít nhất 1 biến thể (size, màu, tồn kho)');
      return;
    }

    setLoading(true);
    try {
      const finalThumb = thumbnailUrl || images[0] || 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=800';
      const payload: CreateProductInput = {
        name: name.trim(),
        slug: slug.trim() || generateSlug(name),
        categoryId,
        price: Number(price),
        description: description.trim() || undefined,
        thumbnailUrl: finalThumb,
        isActive: true,
        variants: variants.map((v) => ({
          size: v.size,
          color: v.color,
          sku: v.sku || `${slug}-${v.size}-${v.color}`.toLowerCase(),
          stock: v.stock,
        })),
        images: images.map((url, idx) => ({
          url,
          sortOrder: idx,
        })),
      };

      const created = await createAdminProduct(payload);
      setSuccess(`Đã tạo thành công sản phẩm "${created.name}"!`);
      onProductCreated(created);

      setTimeout(() => {
        onClose();
        // Reset form
        setName('');
        setSlug('');
        setDescription('');
        setThumbnailUrl('');
        setImages([]);
        setSuccess(null);
      }, 1200);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Lỗi khi tạo sản phẩm';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  const totalStockCount = variants.reduce((sum, v) => sum + (v.stock || 0), 0);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-xs animate-fade-in overflow-y-auto">
      <div className="bg-white border border-slate-200 rounded-3xl w-full max-w-4xl max-h-[92vh] flex flex-col overflow-hidden shadow-2xl my-auto text-slate-800">
        {/* Modal Header */}
        <div className="px-6 py-4 bg-slate-50 border-b border-slate-200 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-amber-50 border border-amber-200 flex items-center justify-center text-amber-600">
              <Boxes className="w-5 h-5" />
            </div>
            <div>
              <h3 className="font-bold text-slate-900 text-base flex items-center gap-2">
                Thêm Sản Phẩm Mới Vào Hệ Thống
                <span className="text-xs bg-amber-50 text-amber-800 border border-amber-200 px-2 py-0.5 rounded-full font-semibold">
                  Thời trang Nam Menly
                </span>
              </h3>
              <p className="text-xs text-slate-500 mt-0.5">
                Thiết lập thông tin, hình ảnh đa phương tiện và biến thể (size/màu/tồn kho)
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-xl text-slate-400 hover:text-slate-700 hover:bg-slate-200 transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-6 text-xs">
          {/* Feedback Alerts */}
          {error && (
            <div className="bg-rose-50 border border-rose-200 text-rose-800 p-3 rounded-2xl flex items-center gap-2">
              <AlertCircle className="w-4 h-4 shrink-0 text-rose-600" />
              <span className="font-semibold">{error}</span>
            </div>
          )}
          {success && (
            <div className="bg-emerald-50 border border-emerald-200 text-emerald-800 p-3 rounded-2xl flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 shrink-0 text-emerald-600" />
              <span className="font-semibold">{success}</span>
            </div>
          )}

          {/* 1. THÔNG TIN CƠ BẢN */}
          <div className="bg-slate-50 border border-slate-200 rounded-2xl p-5 space-y-4">
            <div className="flex items-center gap-2 text-amber-800 font-bold border-b border-slate-200 pb-2">
              <Tag className="w-4 h-4 text-amber-600" />
              <span>1. Thông tin chung của sản phẩm</span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Product Name */}
              <div className="space-y-1.5 md:col-span-2">
                <label className="text-slate-700 font-semibold flex items-center gap-1">
                  Tên sản phẩm <span className="text-rose-500">*</span>
                </label>
                <input
                  type="text"
                  required
                  placeholder="Ví dụ: Áo Sơ Mi Nam Oxford Dài Tay Form Rộng Menly..."
                  value={name}
                  onChange={(e) => handleNameChange(e.target.value)}
                  className="w-full bg-white border border-slate-300 rounded-xl px-3.5 py-2.5 text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-amber-500 text-xs"
                />
              </div>

              {/* Slug */}
              <div className="space-y-1.5">
                <label className="text-slate-700 font-semibold">Đường dẫn thân thiện (Slug)</label>
                <input
                  type="text"
                  placeholder="ao-so-mi-nam-oxford..."
                  value={slug}
                  onChange={(e) => setSlug(e.target.value)}
                  className="w-full bg-white border border-slate-300 rounded-xl px-3.5 py-2.5 text-slate-800 font-mono text-[11px] focus:outline-none focus:border-amber-500"
                />
              </div>

              {/* Category */}
              <div className="space-y-1.5">
                <label className="text-slate-700 font-semibold flex items-center gap-1">
                  Danh mục phân loại <span className="text-rose-500">*</span>
                </label>
                <select
                  required
                  value={categoryId}
                  onChange={(e) => setCategoryId(e.target.value)}
                  className="w-full bg-white border border-slate-300 rounded-xl px-3.5 py-2.5 text-slate-900 font-medium focus:outline-none focus:border-amber-500 cursor-pointer text-xs"
                >
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Price */}
              <div className="space-y-1.5">
                <label className="text-slate-700 font-semibold flex items-center gap-1">
                  Giá bán niêm yết (VNĐ) <span className="text-rose-500">*</span>
                </label>
                <div className="relative">
                  <input
                    type="number"
                    required
                    min={1000}
                    step={1000}
                    placeholder="350000"
                    value={price}
                    onChange={(e) => setPrice(e.target.value ? Number(e.target.value) : '')}
                    className="w-full bg-white border border-slate-300 rounded-xl px-3.5 py-2.5 text-slate-900 font-bold font-mono text-xs focus:outline-none focus:border-amber-500 pl-8"
                  />
                  <DollarSign className="w-4 h-4 text-slate-400 absolute left-2.5 top-3" />
                  <span className="absolute right-3 top-3 text-[11px] text-slate-400 font-mono">
                    đ
                  </span>
                </div>
              </div>

              {/* Description */}
              <div className="space-y-1.5 md:col-span-2">
                <label className="text-slate-700 font-semibold">Mô tả chi tiết sản phẩm</label>
                <textarea
                  rows={3}
                  placeholder="Chất liệu cotton thoáng mát, thấm hút mồ hôi tốt, đường may tỉ mỉ, form dáng chuẩn công sở..."
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="w-full bg-white border border-slate-300 rounded-xl p-3 text-slate-800 placeholder:text-slate-400 focus:outline-none focus:border-amber-500 text-xs"
                />
              </div>
            </div>
          </div>

          {/* 2. HÌNH ẢNH SẢN PHẨM & UPLOAD NHIỀU ẢNH */}
          <div className="bg-slate-50 border border-slate-200 rounded-2xl p-5 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-200 pb-2">
              <div className="flex items-center gap-2 text-sky-800 font-bold">
                <ImageIcon className="w-4 h-4 text-sky-600" />
                <span>2. Thư viện hình ảnh sản phẩm ({images.length} ảnh)</span>
              </div>
              <span className="text-[11px] text-slate-500">
                Hỗ trợ tải lên nhiều file ảnh hoặc dán đường dẫn URL trực tiếp
              </span>
            </div>

            {/* Input URL & Upload button */}
            <div className="flex flex-col sm:flex-row gap-3">
              <div className="flex-1 flex gap-2">
                <input
                  type="url"
                  placeholder="Nhập đường dẫn URL ảnh (https://...)"
                  value={newImageUrl}
                  onChange={(e) => setNewImageUrl(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      handleAddImageUrl();
                    }
                  }}
                  className="flex-1 bg-white border border-slate-300 rounded-xl px-3.5 py-2 text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-amber-500 text-xs font-mono"
                />
                <button
                  type="button"
                  onClick={handleAddImageUrl}
                  className="px-3.5 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 rounded-xl font-semibold flex items-center gap-1.5 transition-all cursor-pointer"
                >
                  <Plus className="w-3.5 h-3.5" /> Thêm link
                </button>
              </div>

              {/* Upload file button */}
              <label className="px-4 py-2 bg-sky-50 hover:bg-sky-100 text-sky-800 border border-sky-200 rounded-xl font-semibold flex items-center justify-center gap-2 cursor-pointer transition-all">
                <Upload className="w-4 h-4 text-sky-600" />
                <span>Chọn ảnh từ máy tính</span>
                <input
                  type="file"
                  multiple
                  accept="image/*"
                  onChange={handleFileUpload}
                  className="hidden"
                />
              </label>
            </div>

            {/* Gallery Grid Preview */}
            {images.length > 0 ? (
              <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-6 gap-3 pt-2">
                {images.map((imgUrl, idx) => {
                  const isThumb = thumbnailUrl === imgUrl;
                  return (
                    <div
                      key={idx}
                      className={`relative group rounded-xl overflow-hidden border transition-all ${
                        isThumb
                          ? 'border-amber-500 ring-2 ring-amber-400/40'
                          : 'border-slate-200 hover:border-slate-300'
                      }`}
                    >
                      <img
                        src={imgUrl}
                        alt={`Ảnh ${idx + 1}`}
                        className="w-full h-24 object-cover bg-white"
                      />
                      {isThumb && (
                        <span className="absolute top-1 left-1 bg-amber-500 text-slate-950 text-[9px] font-bold px-1.5 py-0.5 rounded shadow-2xs">
                          Ảnh bìa
                        </span>
                      )}
                      <div className="absolute inset-0 bg-slate-900/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2 p-1">
                        {!isThumb && (
                          <button
                            type="button"
                            title="Đặt làm ảnh bìa"
                            onClick={() => setThumbnailUrl(imgUrl)}
                            className="p-1.5 bg-white text-amber-700 rounded-lg hover:bg-amber-50 shadow-2xs text-xs font-bold"
                          >
                            ⭐
                          </button>
                        )}
                        <button
                          type="button"
                          title="Xóa ảnh này"
                          onClick={() => handleRemoveImage(idx)}
                          className="p-1.5 bg-white text-rose-600 rounded-lg hover:bg-rose-50 shadow-2xs"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="border border-dashed border-slate-300 rounded-xl p-6 text-center text-slate-400 flex flex-col items-center justify-center gap-2 bg-white">
                <ImageIcon className="w-8 h-8 text-slate-400" />
                <p>Chưa có hình ảnh nào. Bạn có thể chọn tải ảnh từ máy tính hoặc dán URL.</p>
              </div>
            )}
          </div>

          {/* 3. BIẾN THỂ (SIZE, MÀU, TỒN KHO) */}
          <div className="bg-slate-50 border border-slate-200 rounded-2xl p-5 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-200 pb-2">
              <div className="flex items-center gap-2 text-emerald-800 font-bold">
                <Layers className="w-4 h-4 text-emerald-600" />
                <span>
                  3. Danh sách biến thể & Tồn kho ({variants.length} phân loại • Tổng {totalStockCount} cái)
                </span>
              </div>
            </div>

            {/* Quick Generator Box */}
            <div className="bg-white border border-slate-200 p-4 rounded-xl space-y-3">
              <div className="flex items-center justify-between">
                <span className="font-bold text-slate-800 flex items-center gap-1.5">
                  <Sparkles className="w-3.5 h-3.5 text-amber-600" />
                  Công cụ tạo hàng loạt biến thể (Size x Màu x Số lượng)
                </span>
                <button
                  type="button"
                  onClick={handleBulkGenerateVariants}
                  className="px-3 py-1.5 bg-amber-500 hover:bg-amber-400 text-slate-950 rounded-lg font-bold transition-all cursor-pointer flex items-center gap-1 shadow-2xs"
                >
                  <Sparkles className="w-3.5 h-3.5" />
                  Tạo ma trận phân loại
                </button>
              </div>

              {/* Sizes checkboxes */}
              <div className="flex flex-wrap items-center gap-2">
                <span className="text-slate-500 font-medium mr-2">Chọn Sizes:</span>
                {COMMON_SIZES.map((s) => {
                  const active = selectedSizes.includes(s);
                  return (
                    <button
                      key={s}
                      type="button"
                      onClick={() =>
                        setSelectedSizes((prev) =>
                          active ? prev.filter((x) => x !== s) : [...prev, s]
                        )
                      }
                      className={`px-2.5 py-1 rounded-lg font-mono font-bold text-xs transition-all cursor-pointer ${
                        active
                          ? 'bg-amber-500 text-slate-950 shadow-2xs'
                          : 'bg-slate-100 text-slate-600 hover:bg-slate-200 border border-slate-200'
                      }`}
                    >
                      {s}
                    </button>
                  );
                })}
              </div>

              {/* Colors checkboxes */}
              <div className="flex flex-wrap items-center gap-2">
                <span className="text-slate-500 font-medium mr-2">Chọn Màu:</span>
                {COMMON_COLORS.map((c) => {
                  const active = selectedColors.includes(c);
                  return (
                    <button
                      key={c}
                      type="button"
                      onClick={() =>
                        setSelectedColors((prev) =>
                          active ? prev.filter((x) => x !== c) : [...prev, c]
                        )
                      }
                      className={`px-2.5 py-1 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                        active
                          ? 'bg-sky-600 text-white shadow-2xs'
                          : 'bg-slate-100 text-slate-600 hover:bg-slate-200 border border-slate-200'
                      }`}
                    >
                      {c}
                    </button>
                  );
                })}
              </div>

              {/* Default Stock Input */}
              <div className="flex items-center gap-2 text-slate-600">
                <span>Số lượng mỗi biến thể:</span>
                <input
                  type="number"
                  min={1}
                  value={defaultStock}
                  onChange={(e) => setDefaultStock(Number(e.target.value) || 0)}
                  className="w-20 bg-white border border-slate-300 rounded-lg px-2 py-1 text-slate-900 font-mono text-xs focus:outline-none focus:border-amber-500"
                />
                <span>cái</span>
              </div>
            </div>

            {/* Manual Variant Add Row */}
            <div className="flex flex-wrap items-center gap-2 pt-1">
              <span className="text-slate-600 font-semibold mr-1">+ Thêm lẻ 1 biến thể:</span>
              <input
                type="text"
                placeholder="Size (vd: 3XL)"
                value={customSize}
                onChange={(e) => setCustomSize(e.target.value)}
                className="w-24 bg-white border border-slate-300 rounded-lg px-2.5 py-1.5 text-slate-900 text-xs focus:outline-none focus:border-amber-500"
              />
              <input
                type="text"
                placeholder="Màu sắc (vd: Rêu)"
                value={customColor}
                onChange={(e) => setCustomColor(e.target.value)}
                className="w-28 bg-white border border-slate-300 rounded-lg px-2.5 py-1.5 text-slate-900 text-xs focus:outline-none focus:border-amber-500"
              />
              <input
                type="number"
                min={0}
                placeholder="Tồn kho"
                value={customStock}
                onChange={(e) => setCustomStock(Number(e.target.value) || 0)}
                className="w-20 bg-white border border-slate-300 rounded-lg px-2.5 py-1.5 text-slate-900 font-mono text-xs focus:outline-none focus:border-amber-500"
              />
              <button
                type="button"
                onClick={handleAddCustomVariant}
                className="px-3 py-1.5 bg-emerald-50 hover:bg-emerald-100 text-emerald-800 border border-emerald-200 rounded-lg font-semibold flex items-center gap-1 transition-all cursor-pointer"
              >
                <Plus className="w-3.5 h-3.5" /> Thêm biến thể
              </button>
            </div>

            {/* Variants Table */}
            <div className="overflow-x-auto border border-slate-200 rounded-xl mt-2 max-h-60 overflow-y-auto bg-white">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="bg-slate-50 text-slate-600 font-bold border-b border-slate-200 sticky top-0">
                    <th className="py-2 px-3">STT</th>
                    <th className="py-2 px-3">Kích cỡ (Size)</th>
                    <th className="py-2 px-3">Màu sắc</th>
                    <th className="py-2 px-3">Mã SKU</th>
                    <th className="py-2 px-3">Tồn kho ban đầu</th>
                    <th className="py-2 px-3 text-center">Xóa</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {variants.map((v, i) => (
                    <tr key={i} className="hover:bg-slate-50 transition-colors">
                      <td className="py-2 px-3 font-mono text-slate-400">{i + 1}</td>
                      <td className="py-2 px-3 font-mono font-bold text-slate-900">{v.size}</td>
                      <td className="py-2 px-3">{v.color}</td>
                      <td className="py-2 px-3 font-mono text-slate-500 text-[11px]">
                        {v.sku || `${slug}-${v.size}-${v.color}`}
                      </td>
                      <td className="py-2 px-3">
                        <div className="flex items-center gap-1">
                          <input
                            type="number"
                            min={0}
                            value={v.stock}
                            onChange={(e) =>
                              handleUpdateVariantStock(i, Number(e.target.value) || 0)
                            }
                            className="w-20 bg-white border border-slate-300 rounded px-2 py-1 text-slate-900 font-mono font-bold text-xs focus:outline-none focus:border-amber-500"
                          />
                          <span className="text-[11px] text-slate-500">cái</span>
                        </div>
                      </td>
                      <td className="py-2 px-3 text-center">
                        <button
                          type="button"
                          onClick={() => handleRemoveVariant(i)}
                          className="p-1 text-slate-400 hover:text-rose-600 transition-colors cursor-pointer"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Modal Footer */}
          <div className="pt-4 border-t border-slate-200 flex items-center justify-between">
            <span className="text-slate-500 text-[11px]">
              * Sản phẩm sẽ tự động hiển thị trên ứng dụng Menly và trang quản trị sau khi tạo
            </span>
            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={onClose}
                disabled={loading}
                className="px-5 py-2.5 rounded-xl border border-slate-300 text-slate-600 hover:text-slate-900 hover:bg-slate-100 font-semibold transition-all cursor-pointer"
              >
                Hủy bỏ
              </button>
              <button
                type="submit"
                disabled={loading}
                className="px-6 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold transition-all shadow-2xs flex items-center gap-2 cursor-pointer disabled:opacity-50"
              >
                {loading ? (
                  <>
                    <span className="w-4 h-4 border-2 border-slate-950 border-t-transparent rounded-full animate-spin" />
                    Đang lưu sản phẩm...
                  </>
                ) : (
                  <>
                    <Boxes className="w-4 h-4" />
                    Tạo & Công Bố Sản Phẩm
                  </>
                )}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}
