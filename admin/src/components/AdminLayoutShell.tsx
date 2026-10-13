'use client';

import React, { useState, useEffect } from 'react';
import { usePathname } from 'next/navigation';
import { Sidebar } from './Sidebar';
import { AdminAuthGuard } from './AdminAuthGuard';

export function AdminLayoutShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    const handleToggle = () => {
      setMobileOpen((prev) => !prev);
    };

    window.addEventListener('menshop_toggle_mobile_sidebar', handleToggle);
    return () => {
      window.removeEventListener('menshop_toggle_mobile_sidebar', handleToggle);
    };
  }, []);

  // Close mobile sidebar on route change
  useEffect(() => {
    setMobileOpen(false);
  }, [pathname]);

  if (pathname === '/login') {
    return <AdminAuthGuard>{children}</AdminAuthGuard>;
  }

  return (
    <AdminAuthGuard>
      <div className="flex min-h-screen w-full bg-slate-50 text-slate-800">
        <Sidebar
          mobileOpen={mobileOpen}
          onCloseMobile={() => setMobileOpen(false)}
        />
        <div className="flex-1 flex flex-col min-w-0 min-h-screen overflow-x-hidden">
          {children}
        </div>
      </div>
    </AdminAuthGuard>
  );
}
