'use client';

import React from 'react';
import {
  FolderOpen,
  Layers,
  Search,
  ArrowUpDown,
  LayoutGrid,
  List,
  Plus,
} from 'lucide-react';
import { Category, Product } from '../../lib/types';
import { SortOption } from '../../hooks/useProducts';

interface ProductToolbarProps {
  categories: Category[];
  products: Product[];
  selectedCategory: string;
  setSelectedCategory: (catId: string) => void;
  searchQuery: string;
  setSearchQuery: (q: string) => void;
  sortBy: SortOption;
  setSortBy: (sort: SortOption) => void;
  viewMode: 'grouped' | 'table';
  setViewMode: (mode: 'grouped' | 'table') => void;
  getProductCategory: (p: Product) => Category;
  onOpenCreateModal: () => void;
}

export function ProductToolbar({
  categories,
  products,
  selectedCategory,
  setSelectedCategory,
  searchQuery,
  setSearchQuery,
  sortBy,
  setSortBy,
  viewMode,
  setViewMode,
  getProductCategory,
  onOpenCreateModal,
}: ProductToolbarProps) {
  return (
    <div className="space-y-4">
      {/* 1. Category Filter Tabs */}
      <div className="bg-white border border-slate-200 p-4 rounded-2xl space-y-3 shadow-2xs">
        <div className="flex items-center justify-between text-xs text-slate-500 font-semibold">
          <span className="flex items-center gap-1.5 text-slate-800 font-bold">
            <FolderOpen className="w-4 h-4 text-amber-600" />
            DANH MỤC THỜI TRANG NAM ({categories.length} danh mục)
          </span>
          <span className="text-[11px] text-slate-400 font-normal">
            Bấm vào danh mục để lọc hoặc chọn &quot;Tất cả&quot; để xem phân nhóm
          </span>
        </div>

        <div className="flex items-center gap-2 overflow-x-auto pb-1">
          <button
            onClick={() => setSelectedCategory('all')}
            className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all shrink-0 cursor-pointer flex items-center gap-2 ${
              selectedCategory === 'all'
                ? 'bg-amber-500 text-slate-950 shadow-2xs'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200 border border-slate-200'
            }`}
          >
            <Layers className="w-3.5 h-3.5" />
            <span>Tất cả</span>
            <span
              className={`px-1.5 py-0.2 rounded-full text-[10px] font-mono ${
                selectedCategory === 'all'
                  ? 'bg-amber-600 text-white font-bold'
                  : 'bg-white text-slate-600 border border-slate-200'
              }`}
            >
              {products.length}
            </span>
          </button>

          {categories.map((c) => {
            const count = products.filter((p) => {
              const cat = getProductCategory(p);
              return p.categoryId === c.id || cat.id === c.id;
            }).length;

            return (
              <button
                key={c.id}
                onClick={() => setSelectedCategory(c.id)}
                className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all shrink-0 cursor-pointer flex items-center gap-2 ${
                  selectedCategory === c.id
                    ? 'bg-amber-500 text-slate-950 shadow-2xs'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200 border border-slate-200'
                }`}
              >
                <span>{c.name}</span>
                <span
                  className={`px-1.5 py-0.2 rounded-full text-[10px] font-mono ${
                    selectedCategory === c.id
                      ? 'bg-amber-600 text-white font-bold'
                      : 'bg-white text-slate-600 border border-slate-200'
                  }`}
                >
                  {count}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* 2. Control Toolbar: Search, Sort & View Mode */}
      <div className="flex flex-col md:flex-row gap-3 items-stretch md:items-center justify-between bg-white p-4 rounded-2xl border border-slate-200 shadow-2xs">
        {/* Search Box */}
        <div className="flex items-center gap-2.5 flex-1 max-w-md bg-white px-3.5 py-2 rounded-xl border border-slate-300">
          <Search className="w-4 h-4 text-slate-400 shrink-0" />
          <input
            type="text"
            placeholder="Tìm kiếm sản phẩm theo tên, slug hoặc ID..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="bg-transparent text-xs text-slate-900 placeholder:text-slate-400 focus:outline-none w-full"
          />
        </div>

        <div className="flex items-center gap-3">
          {/* Sort Dropdown */}
          <div className="flex items-center gap-2 bg-white px-3 py-1.5 rounded-xl border border-slate-300">
            <ArrowUpDown className="w-3.5 h-3.5 text-amber-600 shrink-0" />
            <span className="text-[11px] text-slate-500 font-semibold">Sắp xếp:</span>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as SortOption)}
              className="bg-transparent text-xs text-slate-800 font-medium focus:outline-none cursor-pointer pr-1"
            >
              <option value="category">Theo Danh mục (Chuẩn phân loại)</option>
              <option value="price_asc">Giá: Thấp đến Cao</option>
              <option value="price_desc">Giá: Cao đến Thấp</option>
              <option value="name_asc">Tên: A → Z</option>
              <option value="stock_desc">Tồn kho: Nhiều nhất</option>
              <option value="stock_asc">Tồn kho: Ít nhất</option>
            </select>
          </div>

          {/* View Mode Toggle */}
          <div className="flex items-center bg-slate-100 p-1 rounded-xl border border-slate-200">
            <button
              onClick={() => setViewMode('grouped')}
              title="Gom nhóm theo Danh mục"
              className={`p-1.5 rounded-lg text-xs font-semibold flex items-center gap-1 transition-all ${
                viewMode === 'grouped'
                  ? 'bg-amber-500 text-slate-950 font-bold shadow-2xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <LayoutGrid className="w-3.5 h-3.5" />
              <span className="hidden sm:inline text-[11px]">Theo Danh mục</span>
            </button>
            <button
              onClick={() => setViewMode('table')}
              title="Danh sách Bảng tổng hợp"
              className={`p-1.5 rounded-lg text-xs font-semibold flex items-center gap-1 transition-all ${
                viewMode === 'table'
                  ? 'bg-amber-500 text-slate-950 font-bold shadow-2xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <List className="w-3.5 h-3.5" />
              <span className="hidden sm:inline text-[11px]">Bảng đơn</span>
            </button>
          </div>

          {/* Add New Product Button */}
          <button
            onClick={onOpenCreateModal}
            className="px-3.5 py-2 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold text-xs flex items-center gap-1.5 transition-all shadow-2xs cursor-pointer shrink-0"
          >
            <Plus className="w-4 h-4 stroke-[2.5]" />
            <span>Thêm sản phẩm mới</span>
          </button>
        </div>
      </div>
    </div>
  );
}
