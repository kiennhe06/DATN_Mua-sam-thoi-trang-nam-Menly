'use client';

import { useState, useEffect } from 'react';
import { Header } from '../../components/Header';
import { fetchAuditLogs } from '../../lib/api';
import { AuditLog } from '../../lib/types';
import { ScrollText, ShieldAlert, KeyRound } from 'lucide-react';

export default function AuditPage() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);

  async function loadLogs() {
    setLoading(true);
    try {
      const data = await fetchAuditLogs();
      setLogs(data);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadLogs();
  }, []);

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Nhật ký Hoạt động (Audit Logs)"
        subtitle="Theo dõi và lưu vết toàn bộ các hành động nhạy cảm của ban quản trị hệ thống"
        onRefresh={loadLogs}
      />

      <div className="p-8 space-y-6 flex-1">
        {/* Security Alert Header */}
        <div className="p-4 rounded-2xl bg-amber-50 border border-amber-200 flex items-center justify-between text-xs text-amber-800 shadow-2xs">
          <div className="flex items-center gap-2.5">
            <ShieldAlert className="w-5 h-5 text-amber-600 shrink-0" />
            <div>
              <p className="font-bold text-slate-900 text-sm">Hệ thống Bảo mật Toàn vẹn MenShop</p>
              <p className="text-slate-600 mt-0.5">
                Các thao tác sửa giá, cập nhật trạng thái đơn hàng, hiệu chỉnh tồn kho và phân quyền người dùng đều được ghi nhận bất biến trong bảng `audit_logs`.
              </p>
            </div>
          </div>
          <span className="font-mono bg-amber-100 px-2.5 py-1 rounded text-amber-800 font-bold border border-amber-300 shrink-0">
            RLS Enabled
          </span>
        </div>

        {/* Audit Log Table */}
        <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-2xs">
          <div className="p-4 border-b border-slate-200 flex items-center justify-between text-xs text-slate-500 font-medium bg-white">
            <span className="flex items-center gap-1.5 font-bold text-slate-900 text-sm">
              <ScrollText className="w-4 h-4 text-amber-500" />
              Lịch sử thao tác ({logs.length} bản ghi)
            </span>
            <span>Tự động sắp xếp theo thời gian mới nhất</span>
          </div>

          {loading ? (
            <div className="py-20 text-center text-slate-500 text-sm">Đang tải nhật ký audit...</div>
          ) : logs.length === 0 ? (
            <div className="py-20 text-center text-slate-500 text-sm">Chưa có nhật ký nào được ghi nhận</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-slate-200 text-xs text-slate-600 uppercase tracking-wider font-semibold bg-slate-50">
                    <th className="py-3 px-4">Thời gian</th>
                    <th className="py-3 px-4">Tài khoản Admin</th>
                    <th className="py-3 px-4">Hành động</th>
                    <th className="py-3 px-4">Đối tượng</th>
                    <th className="py-3 px-4">Chi tiết Metadata</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {logs.map((log) => (
                    <tr key={log.id} className="hover:bg-slate-50 transition-colors text-xs">
                      <td className="py-3 px-4 font-mono text-slate-500 whitespace-nowrap">
                        {new Date(log.createdAt).toLocaleString('vi-VN')}
                      </td>
                      <td className="py-3 px-4 font-mono font-semibold text-slate-900">
                        <span className="flex items-center gap-1">
                          <KeyRound className="w-3 h-3 text-slate-400" />
                          {log.actorId}
                        </span>
                      </td>
                      <td className="py-3 px-4">
                        <span className="font-mono font-bold text-xs bg-slate-100 text-slate-800 px-2.5 py-1 rounded-md border border-slate-200">
                          {log.action}
                        </span>
                      </td>
                      <td className="py-3 px-4 font-mono text-slate-800">
                        <span className="text-slate-500">{log.entity}:</span> {log.entityId}
                      </td>
                      <td className="py-3 px-4 font-mono text-[11px] text-slate-600 max-w-sm">
                        <pre className="bg-slate-50 p-2 rounded-lg border border-slate-200 overflow-x-auto text-slate-700">
                          {JSON.stringify(log.metadata || {}, null, 2)}
                        </pre>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
