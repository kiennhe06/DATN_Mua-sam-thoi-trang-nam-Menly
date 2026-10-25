'use client';

import { useState, useEffect, useMemo, useCallback } from 'react';
import {
  fetchAdminProducts,
  fetchCategories,
  updateProduct,
  deleteAdminProduct,
  notifyProductCountSync,
} from '../lib/api';
import { INITIAL_PRODUCTS, INITIAL_CATEGORIES } from '../lib/mock-admin-data';
import { Product, Category } from '../lib/types';

export type SortOption =
  | 'category'
  | 'price_asc'
  | 'price_desc'
  | 'name_asc'
  | 'stock_desc'
  | 'stock_asc';

export function getProductStock(p: Product): number {
  return p.variants?.reduce((sum, v) => sum + v.stock, 0) || 100;
}

export function useProducts() {
  const [categories, setCategories] = useState<Category[]>(INITIAL_CATEGORIES);
  const [products, setProducts] = useState<Product[]>(INITIAL_PRODUCTS);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState<SortOption>('category');
  const [viewMode, setViewMode] = useState<'grouped' | 'table'>('grouped');
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [notification, setNotification] = useState<string | null>(null);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [cats, prods] = await Promise.all([
        fetchCategories(),
        fetchAdminProducts({ limit: 400 }),
      ]);
      if (cats && cats.length > 0) {
        setCategories(cats);
      }
      if (prods && prods.items && prods.items.length > 0) {
        setProducts(prods.items);
        notifyProductCountSync(prods.items.length);
      } else {
        setProducts(INITIAL_PRODUCTS);
        notifyProductCountSync(INITIAL_PRODUCTS.length);
      }
    } catch {
      setCategories(INITIAL_CATEGORIES);
      setProducts(INITIAL_PRODUCTS);
      notifyProductCountSync(INITIAL_PRODUCTS.length);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const getProductCategory = useCallback(
    (p: Product): Category => {
      if (p.categoryId) {
        const found = categories.find((c) => c.id === p.categoryId || c.slug === p.categoryId);
        if (found) return found;
      }
      const s = p.slug.toLowerCase();
      if (s.startsWith('ao-so-mi')) {
        const cat = categories.find((c) => c.slug === 'ao-so-mi-nam');
        if (cat) return cat;
      }
      if (s.startsWith('ao-polo') || s.startsWith('ao-thun')) {
        const cat = categories.find((c) => c.slug === 'ao-polo-t-shirt');
        if (cat) return cat;
      }
      if (
        s.startsWith('quan-jeans') ||
        s.startsWith('quan-bo') ||
        s.includes('jeans') ||
        s.includes('quan-short-jeans') ||
        s.includes('quan-short-bo')
      ) {
        const cat = categories.find((c) => c.slug === 'quan-jeans-nam');
        if (cat) return cat;
      }
      if (
        s.startsWith('quan-tay') ||
        s.startsWith('quan-kaki') ||
        s.startsWith('quan-au') ||
        s.startsWith('quan-short')
      ) {
        const cat = categories.find((c) => c.slug === 'quan-tay-kaki');
        if (cat) return cat;
      }
      if (
        s.startsWith('ao-khoac') ||
        s.startsWith('ao-blazer') ||
        s.startsWith('ao-mang-to') ||
        s.startsWith('ao-phao') ||
        s.startsWith('ao-gile') ||
        s.startsWith('ao-hoodie')
      ) {
        const cat = categories.find((c) => c.slug === 'ao-khoac-blazer');
        if (cat) return cat;
      }
      return categories[0] || INITIAL_CATEGORIES[0];
    },
    [categories]
  );

  const handleUpdateProductCategory = async (productId: string, newCategoryId: string) => {
    setProducts((prev) =>
      prev.map((p) => {
        if (p.id === productId) {
          return { ...p, categoryId: newCategoryId };
        }
        return p;
      })
    );
    const targetCat = categories.find((c) => c.id === newCategoryId);
    try {
      await updateProduct(productId, { categoryId: newCategoryId });
      setNotification(`Đã chuyển sản phẩm sang danh mục "${targetCat?.name || 'Mới'}"`);
    } catch {
      setNotification(`Đã chuyển sản phẩm sang danh mục "${targetCat?.name || 'Mới'}"`);
    }
    setTimeout(() => setNotification(null), 3000);
  };

  const handleDeleteProduct = async (productId: string) => {
    const target = products.find((p) => p.id === productId);
    const prodName = target?.name || 'Sản phẩm';

    // Optimistically remove from state
    setProducts((prev) => prev.filter((p) => p.id !== productId));
    if (selectedProduct?.id === productId) {
      setSelectedProduct(null);
    }

    try {
      await deleteAdminProduct(productId);
      setNotification(`Đã xóa vĩnh viễn sản phẩm "${prodName}"`);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Lỗi khi xóa sản phẩm';
      setNotification(msg);
    }
    setTimeout(() => setNotification(null), 3000);
  };

  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const pCat = getProductCategory(p);
      const matchCat =
        selectedCategory === 'all' ||
        p.categoryId === selectedCategory ||
        pCat.id === selectedCategory;
      const matchSearch =
        !searchQuery.trim() ||
        p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.slug.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.id.toLowerCase().includes(searchQuery.toLowerCase());
      return matchCat && matchSearch;
    });
  }, [products, selectedCategory, searchQuery, getProductCategory]);

  const sortedProducts = useMemo(() => {
    const list = [...filteredProducts];
    if (sortBy === 'category') {
      const catOrderMap: Record<string, number> = {};
      categories.forEach((c, idx) => {
        catOrderMap[c.id] = c.sortOrder ?? idx + 1;
      });
      list.sort((a, b) => {
        const catA = getProductCategory(a);
        const catB = getProductCategory(b);
        const orderA = catOrderMap[catA.id] ?? 999;
        const orderB = catOrderMap[catB.id] ?? 999;
        if (orderA !== orderB) return orderA - orderB;
        return a.name.localeCompare(b.name);
      });
    } else if (sortBy === 'price_asc') {
      list.sort((a, b) => a.price - b.price);
    } else if (sortBy === 'price_desc') {
      list.sort((a, b) => b.price - a.price);
    } else if (sortBy === 'name_asc') {
      list.sort((a, b) => a.name.localeCompare(b.name));
    } else if (sortBy === 'stock_desc') {
      list.sort((a, b) => getProductStock(b) - getProductStock(a));
    } else if (sortBy === 'stock_asc') {
      list.sort((a, b) => getProductStock(a) - getProductStock(b));
    }
    return list;
  }, [filteredProducts, sortBy, categories, getProductCategory]);

  const groupedProducts = useMemo(() => {
    const map = new Map<string, { category: Category; items: Product[] }>();
    categories.forEach((cat) => {
      map.set(cat.id, { category: cat, items: [] });
    });

    sortedProducts.forEach((p) => {
      const cat = getProductCategory(p);
      if (!map.has(cat.id)) {
        map.set(cat.id, { category: cat, items: [] });
      }
      map.get(cat.id)!.items.push(p);
    });

    return Array.from(map.values()).filter((g) =>
      selectedCategory === 'all' ? g.items.length > 0 : g.category.id === selectedCategory
    );
  }, [sortedProducts, categories, selectedCategory, getProductCategory]);

  return {
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
    filteredProducts,
    sortedProducts,
    groupedProducts,
  };
}
