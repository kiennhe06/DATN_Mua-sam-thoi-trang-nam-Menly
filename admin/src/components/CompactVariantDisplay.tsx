'use client';

import React from 'react';
import { ProductVariant } from '../lib/types';

export function getColorHex(colorName?: string): string {
  if (!colorName) return '#94a3b8';
  const c = colorName.toLowerCase().trim();
  if (c.includes('đen') || c.includes('black')) return '#1e293b';
  if (c.includes('trắng') || c.includes('white')) return '#f8fafc';
  if (c.includes('xám') || c.includes('ghi') || c.includes('grey') || c.includes('gray')) return '#64748b';
  if (c.includes('đỏ') || c.includes('red')) return '#ef4444';
  if (c.includes('navy') || c.includes('xanh than')) return '#1e3a8a';
  if (c.includes('xanh lam') || c.includes('xanh dương') || c.includes('blue')) return '#2563eb';
  if (c.includes('xanh lá') || c.includes('rêu') || c.includes('green')) return '#16a34a';
  if (c.includes('vàng') || c.includes('yellow')) return '#d97706';
  if (c.includes('cam') || c.includes('orange')) return '#ea580c';
  if (c.includes('hồng') || c.includes('pink')) return '#db2777';
  if (c.includes('tím') || c.includes('purple')) return '#7c3aed';
  if (c.includes('nâu') || c.includes('brown')) return '#78350f';
  if (c.includes('be') || c.includes('beige') || c.includes('kem')) return '#d4d4d8';
  return '#0284c7';
}

export interface CompactVariantDisplayProps {
  variants?: ProductVariant[];
  showStockCount?: boolean;
  sizePrefix?: string;
  colorPrefix?: string;
  className?: string;
}

export function CompactVariantDisplay({
  variants = [],
  showStockCount = false,
  sizePrefix = 'Size:',
  colorPrefix = 'Màu:',
  className = '',
}: CompactVariantDisplayProps) {
  // If no variants provided, show default size pills
  if (!variants || variants.length === 0) {
    const defaultSizes = ['S', 'M', 'L', 'XL', '2XL'];
    return (
      <div className={`flex flex-col gap-1.5 ${className}`}>
        <div className="flex items-center gap-1.5 flex-wrap">
          <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider shrink-0">
            {sizePrefix}
          </span>
          <div className="flex items-center gap-1 flex-wrap">
            {defaultSizes.map((s) => (
              <span
                key={s}
                className="px-1.5 py-0.5 rounded-md bg-slate-100 border border-slate-200 text-[11px] font-mono font-bold text-slate-800 shadow-2xs"
              >
                {s}
              </span>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // Aggregate unique sizes and their total stock
  const uniqueSizes: { size: string; stock: number }[] = [];
  const seenSizes = new Set<string>();
  for (const v of variants) {
    const s = (v.size || '').trim();
    if (!s) continue;
    if (!seenSizes.has(s)) {
      seenSizes.add(s);
      uniqueSizes.push({ size: s, stock: v.stock || 0 });
    } else {
      const existing = uniqueSizes.find((item) => item.size === s);
      if (existing) existing.stock += v.stock || 0;
    }
  }

  // Aggregate unique colors and their total stock
  const uniqueColors: { color: string; stock: number }[] = [];
  const seenColors = new Set<string>();
  for (const v of variants) {
    const c = (v.color || '').trim();
    if (!c) continue;
    if (!seenColors.has(c)) {
      seenColors.add(c);
      uniqueColors.push({ color: c, stock: v.stock || 0 });
    } else {
      const existing = uniqueColors.find((item) => item.color === c);
      if (existing) existing.stock += v.stock || 0;
    }
  }

  return (
    <div className={`flex flex-col gap-1.5 ${className}`}>
      {/* Size row on top (Bên trên là Size) */}
      <div className="flex items-center gap-1.5 flex-wrap">
        <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider shrink-0">
          {sizePrefix}
        </span>
        <div className="flex items-center gap-1 flex-wrap">
          {uniqueSizes.map((item) => (
            <span
              key={item.size}
              className="px-1.5 py-0.5 rounded-md bg-slate-100 border border-slate-200 text-[11px] font-mono font-bold text-slate-800 shadow-2xs flex items-center gap-1"
            >
              <span>{item.size}</span>
              {showStockCount && (
                <span className="text-[9px] text-emerald-700 font-normal">({item.stock})</span>
              )}
            </span>
          ))}
        </div>
      </div>

      {/* Color row below (Bên dưới là Màu) */}
      <div className="flex items-center gap-1.5 flex-wrap">
        <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider shrink-0">
          {colorPrefix}
        </span>
        <div className="flex items-center gap-1 flex-wrap">
          {uniqueColors.map((item) => {
            const hex = getColorHex(item.color);
            const isWhite = item.color.toLowerCase().includes('trắng') || item.color.toLowerCase().includes('white');

            return (
              <span
                key={item.color}
                className="px-1.5 py-0.5 rounded-md bg-white border border-slate-200 text-[11px] font-medium text-slate-700 shadow-2xs flex items-center gap-1"
              >
                <span
                  style={{ backgroundColor: hex }}
                  className={`w-2.5 h-2.5 rounded-full inline-block shrink-0 ${
                    isWhite ? 'border border-slate-300' : ''
                  }`}
                />
                <span className="text-[11px] font-semibold">{item.color}</span>
                {showStockCount && (
                  <span className="text-[9px] text-slate-500 font-mono">({item.stock})</span>
                )}
              </span>
            );
          })}
        </div>
      </div>
    </div>
  );
}
