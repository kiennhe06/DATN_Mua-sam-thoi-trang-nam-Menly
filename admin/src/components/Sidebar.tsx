'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  LayoutDashboard,
  Shirt,
  ShoppingBag,
  Boxes,
  Ticket,
  Star,
  LogOut,
  ChevronRight,
  X,
} from 'lucide-react';
import { fetchAdminProducts, PRODUCT_EVENTS } from '../lib/api';
import { INITIAL_PRODUCTS } from '../lib/mock-admin-data';

interface NavItem {
  href: string;
  label: string;
  icon: typeof LayoutDashboard;
  hasProductCount?: boolean;
}

interface NavSection {
  title: string;
  items: NavItem[];
}

const NAV_SECTIONS: NavSection[] = [
  {
    title: 'Tổng quan & Phân tích',
    items: [
      { href: '/', label: 'Bảng điều khiển', icon: LayoutDashboard },
    ],
  },
  {
    title: 'Quản lý kinh doanh',
    items: [
      { href: '/products', label: 'Sản phẩm', icon: Shirt, hasProductCount: true },
      { href: '/orders', label: 'Đơn hàng', icon: ShoppingBag },
      { href: '/inventory', label: 'Kho hàng & Tồn', icon: Boxes },
      { href: '/vouchers', label: 'Mã giảm giá', icon: Ticket },
      { href: '/reviews', label: 'Đánh giá', icon: Star },
    ],
  },
];

interface SidebarProps {
  mobileOpen?: boolean;
  onCloseMobile?: () => void;
}

export function Sidebar({ mobileOpen = false, onCloseMobile }: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const [productCount, setProductCount] = useState<number>(INITIAL_PRODUCTS.length);
  const [adminUser, setAdminUser] = useState<{ email?: string; fullName?: string } | null>(null);

  useEffect(() => {
    let isMounted = true;

    // Load logged in user info
    if (typeof window !== 'undefined') {
      const uStr = localStorage.getItem('menshop_admin_user');
      if (uStr) {
        try {
          setAdminUser(JSON.parse(uStr));
        } catch {
          // ignore
        }
      }
    }

    const refreshCount = async () => {
      try {
        const res = await fetchAdminProducts({ limit: 400 });
        if (isMounted) {
          const count = res?.total ?? res?.items?.length ?? INITIAL_PRODUCTS.length;
          setProductCount(count);
        }
      } catch {
        // Giữ số lượng khởi tạo mặc định nếu lỗi mạng
      }
    };

    refreshCount();

    const handleCreated = () => {
      setProductCount((prev) => (prev ?? 0) + 1);
    };

    const handleDeleted = () => {
      setProductCount((prev) => Math.max(0, (prev ?? 1) - 1));
    };

    const handleSync = (e: Event) => {
      const ce = e as CustomEvent<number>;
      if (typeof ce.detail === 'number') {
        setProductCount(ce.detail);
      }
    };

    window.addEventListener(PRODUCT_EVENTS.CREATED, handleCreated);
    window.addEventListener(PRODUCT_EVENTS.DELETED, handleDeleted);
    window.addEventListener(PRODUCT_EVENTS.COUNT_SYNC, handleSync);

    return () => {
      isMounted = false;
      window.removeEventListener(PRODUCT_EVENTS.CREATED, handleCreated);
      window.removeEventListener(PRODUCT_EVENTS.DELETED, handleDeleted);
      window.removeEventListener(PRODUCT_EVENTS.COUNT_SYNC, handleSync);
    };
  }, []);

  const handleLogout = () => {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('menshop_admin_token');
      localStorage.removeItem('menshop_admin_user');
      router.push('/login');
    }
  };

  const sidebarContent = (
    <aside className="w-64 bg-white text-slate-700 border-r border-slate-200 flex flex-col shrink-0 h-screen sticky top-0 shadow-xs z-30">
      {/* Brand Header */}
      <div className="p-5 border-b border-slate-200 flex items-center justify-between bg-white">
        <Link href="/" className="flex items-center gap-2.5 group">
          <div className="w-9 h-9 rounded-xl bg-blue-600 text-white flex items-center justify-center font-black text-base shadow-xs group-hover:bg-blue-700 transition-colors">
            M
          </div>
          <div>
            <div className="font-extrabold text-base tracking-wider text-slate-900 flex items-center gap-1.5">
              MENSHOP
              <span className="text-[9px] bg-blue-50 text-blue-700 border border-blue-200 font-bold px-1.5 py-0.2 rounded font-mono">
                ADMIN
              </span>
            </div>
            <p className="text-[11px] text-slate-400 font-medium">
              Hệ thống quản trị
            </p>
          </div>
        </Link>
        {onCloseMobile && (
          <button
            onClick={onCloseMobile}
            className="md:hidden p-1.5 text-slate-400 hover:text-slate-700 hover:bg-slate-100 rounded-lg"
          >
            <X className="w-5 h-5" />
          </button>
        )}
      </div>

      {/* Navigation Sections */}
      <nav className="flex-1 p-3.5 space-y-5 overflow-y-auto">
        {NAV_SECTIONS.map((section) => (
          <div key={section.title} className="space-y-1">
            <h3 className="text-[10px] font-bold text-slate-400 uppercase tracking-wider px-3 mb-1.5">
              {section.title}
            </h3>
            <div className="space-y-0.5">
              {section.items.map((item) => {
                const Icon = item.icon;
                const isActive = pathname === item.href;

                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => {
                      if (onCloseMobile) onCloseMobile();
                    }}
                    className={`flex items-center justify-between px-3 py-2 rounded-xl text-xs font-semibold transition-all duration-150 ${
                      isActive
                        ? 'bg-blue-50 text-blue-700 border border-blue-200/90 shadow-2xs font-bold'
                        : 'text-slate-600 hover:text-blue-700 hover:bg-blue-50/50'
                    }`}
                  >
                    <div className="flex items-center gap-2.5">
                      <Icon
                        className={`w-4 h-4 shrink-0 transition-colors ${
                          isActive ? 'text-blue-600' : 'text-slate-400 group-hover:text-blue-600'
                        }`}
                      />
                      <span>{item.label}</span>
                    </div>

                    {item.hasProductCount ? (
                      <span
                        className={`text-[10px] font-mono font-bold px-1.5 py-0.2 rounded-full ${
                          isActive
                            ? 'bg-blue-100 text-blue-800'
                            : 'bg-slate-100 text-slate-500'
                        }`}
                      >
                        {productCount}
                      </span>
                    ) : isActive ? (
                      <ChevronRight className="w-3.5 h-3.5 text-blue-600" />
                    ) : null}
                  </Link>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      {/* Admin User Footer Card */}
      <div className="p-3 border-t border-slate-200 bg-slate-50/70">
        <div className="p-2.5 rounded-xl bg-white border border-slate-200/90 flex items-center justify-between shadow-2xs">
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="w-8 h-8 rounded-full bg-slate-100 border border-slate-200 text-slate-700 flex items-center justify-center font-bold text-xs shrink-0">
              {adminUser?.fullName ? adminUser.fullName.charAt(0).toUpperCase() : 'A'}
            </div>
            <div className="min-w-0">
              <p className="text-xs font-bold text-slate-900 truncate">
                {adminUser?.fullName || 'Quản trị viên'}
              </p>
              <p className="text-[10px] text-slate-400 truncate font-mono">
                {adminUser?.email || 'admin@menshop.vn'}
              </p>
            </div>
          </div>

          <button
            onClick={handleLogout}
            title="Đăng xuất"
            className="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 transition-colors cursor-pointer shrink-0"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </div>
    </aside>
  );

  return (
    <>
      {/* Desktop Sticky Sidebar */}
      <div className="hidden md:block shrink-0">
        {sidebarContent}
      </div>

      {/* Mobile Sidebar Overlay Drawer */}
      {mobileOpen && (
        <div className="fixed inset-0 z-50 md:hidden flex animate-in fade-in duration-150">
          <div
            className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs"
            onClick={onCloseMobile}
          />
          <div className="relative z-10 animate-in slide-in-from-left duration-200">
            {sidebarContent}
          </div>
        </div>
      )}
    </>
  );
}
