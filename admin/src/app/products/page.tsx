'use client';

import React from 'react';
import { Header } from '../../components/Header';
import { ProductDetailModal } from '../../components/ProductDetailModal';
import { CreateProductModal } from '../../components/CreateProductModal';
import { ConfirmDeleteProductModal } from '../../components/products/ConfirmDeleteProductModal';
import { ProductToolbar } from '../../components/products/ProductToolbar';
import { ProductTableView } from '../../components/products/ProductTableView';
import { ProductGroupedView } from '../../components/products/ProductGroupedView';
import { useProducts } from '../../hooks/useProducts';
import { fetchProductDetail } from '../../lib/api';
import { Product } from '../../lib/types';
import { CheckCircle2 } from 'lucide-react';

export default function ProductsPage() {
  const {
    categories,
    products,
    loading,
    selectedCategory,
    setSelectedCategory,
    searchQuery,
    setSearchQuery,
    sortBy,
    setSortBy,
    viewMode,
    setViewMode,
    selectedProduct,
    setSelectedProduct,
    notification,
    isCreateModalOpen,
    setIsCreateModalOpen,
    loadData,
    getProductCategory,
    handleUpdateProductCategory,
    handleDeleteProduct,
    sortedProducts,
    groupedProducts,
  } = useProducts();

  const [productToDelete, setProductToDelete] = React.useState<Product | null>(null);

  const handleViewDetail = async (p: (typeof products)[0]) => {
    const detail = await fetchProductDetail(p.id);
    setSelectedProduct(detail || p);
  };

  const handleConfirmDelete = async () => {
    if (!productToDelete) return;
    const targetId = productToDelete.id;
    setProductToDelete(null);
    if (selectedProduct?.id === targetId) {
      setSelectedProduct(null);
    }
    await handleDeleteProduct(targetId);
  };

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Sản phẩm & Danh mục Phân loại"
        subtitle={`Hiển thị và sắp xếp ${products.length} sản phẩm vào từng danh mục phân loại chuẩn mực`}
        onRefresh={loadData}
      />

      <div className="p-8 space-y-6 flex-1">
        {/* Toast Notification */}
        {notification && (
          <div className="bg-emerald-50 border border-emerald-200 text-emerald-800 px-4 py-2.5 rounded-xl text-xs flex items-center gap-2 shadow-sm animate-fade-in">
            <CheckCircle2 className="w-4 h-4 text-emerald-600" />
            <span className="font-semibold">{notification}</span>
          </div>
        )}

        {/* Toolbar & Filters Component */}
        <ProductToolbar
          categories={categories}
          products={products}
          selectedCategory={selectedCategory}
          setSelectedCategory={setSelectedCategory}
          searchQuery={searchQuery}
          setSearchQuery={setSearchQuery}
          sortBy={sortBy}
          setSortBy={setSortBy}
          viewMode={viewMode}
          setViewMode={setViewMode}
          getProductCategory={getProductCategory}
          onOpenCreateModal={() => setIsCreateModalOpen(true)}
        />

        {/* Product Presentation Component */}
        {loading ? (
          <div className="py-20 text-center text-slate-400 text-sm bg-white border border-slate-200 rounded-2xl shadow-2xs">
            Đang tải danh mục sản phẩm...
          </div>
        ) : sortedProducts.length === 0 ? (
          <div className="py-20 text-center text-slate-400 text-sm bg-white border border-slate-200 rounded-2xl shadow-2xs">
            Không tìm thấy sản phẩm phù hợp với bộ lọc
          </div>
        ) : viewMode === 'grouped' ? (
          <ProductGroupedView
            groups={groupedProducts}
            categories={categories}
            onSelectCategory={setSelectedCategory}
            onUpdateCategory={handleUpdateProductCategory}
            onViewDetail={handleViewDetail}
            onDeleteProduct={(p) => setProductToDelete(p)}
          />
        ) : (
          <ProductTableView
            products={sortedProducts}
            categories={categories}
            sortBy={sortBy}
            getProductCategory={getProductCategory}
            onUpdateCategory={handleUpdateProductCategory}
            onViewDetail={handleViewDetail}
            onDeleteProduct={(p) => setProductToDelete(p)}
          />
        )}
      </div>

      {/* Product Detail Modal */}
      <ProductDetailModal
        product={selectedProduct}
        onClose={() => setSelectedProduct(null)}
        onStockAdjusted={loadData}
        onDeleteProduct={(p) => setProductToDelete(p)}
      />

      {/* Create Product Modal */}
      <CreateProductModal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
        categories={categories}
        onProductCreated={() => {
          loadData();
        }}
      />

      {/* Confirm Delete Product Modal */}
      <ConfirmDeleteProductModal
        isOpen={Boolean(productToDelete)}
        product={productToDelete}
        onClose={() => setProductToDelete(null)}
        onConfirm={handleConfirmDelete}
      />
    </div>
  );
}
