'use client';

import React from 'react';
import { Order, Product, Category } from '../lib/types';
import { BiTopMetrics } from './BiTopMetrics';
import { BiTopSellingProducts } from './BiTopSellingProducts';

interface BiDashboardProps {
  orders: Order[];
  products: Product[];
  categories: Category[];
}

export function BiAnalyticsDashboard({ orders, products, categories }: BiDashboardProps) {
  return (
    <div className="space-y-6 bg-white p-6 rounded-2xl border border-slate-200 shadow-2xs text-slate-800">
      {/* 1. TOP SECTION: Quick Stats */}
      <BiTopMetrics orders={orders} products={products} categories={categories} />

      {/* 2. BEST SELLERS LEADERBOARD SECTION */}
      <BiTopSellingProducts orders={orders} products={products} categories={categories} />
    </div>
  );
}
