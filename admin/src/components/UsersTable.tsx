'use client';

import React from 'react';
import { UserAccount } from '../lib/types';
import { Shield, User as UserIcon, Lock, Unlock, Edit2, Trash2 } from 'lucide-react';

interface UsersTableProps {
  users: UserAccount[];
  loading: boolean;
  onToggleLock: (u: UserAccount) => void;
  onEdit: (u: UserAccount) => void;
  onDelete: (u: UserAccount) => void;
}

export function UsersTable({
  users,
  loading,
  onToggleLock,
  onEdit,
  onDelete,
}: UsersTableProps) {
  return (
    <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-2xs">
      {loading ? (
        <div className="py-20 text-center text-slate-500 text-sm">Đang tải danh sách người dùng...</div>
      ) : users.length === 0 ? (
        <div className="py-20 text-center text-slate-500 text-sm">Không tìm thấy người dùng nào</div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-slate-200 text-xs text-slate-600 uppercase tracking-wider font-semibold bg-slate-50">
                <th className="py-3 px-4">Tài khoản & Email</th>
                <th className="py-3 px-4">Vai trò</th>
                <th className="py-3 px-4">Trạng thái đăng nhập</th>
                <th className="py-3 px-4">Ngày tạo</th>
                <th className="py-3 px-4 text-right">Thao tác quản trị</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700 text-xs">
              {users.map((u) => (
                <tr key={u.id} className="hover:bg-slate-50 transition-colors">
                  <td className="py-3 px-4">
                    <div className="flex items-center gap-3">
                      <div
                        className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-xs ${
                          u.role === 'admin'
                            ? 'bg-amber-100 text-amber-700 border border-amber-200'
                            : u.role === 'staff'
                            ? 'bg-purple-100 text-purple-700 border border-purple-200'
                            : 'bg-slate-100 text-slate-700 border border-slate-200'
                        }`}
                      >
                        {u.name ? u.name.charAt(0).toUpperCase() : 'U'}
                      </div>
                      <div>
                        <p className="font-semibold text-slate-900">{u.name}</p>
                        <p className="text-slate-500 font-mono text-[11px]">{u.email}</p>
                      </div>
                    </div>
                  </td>

                  <td className="py-3 px-4">
                    <span
                      className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full font-bold text-[10px] border ${
                        u.role === 'admin'
                          ? 'bg-amber-50 text-amber-700 border-amber-200'
                          : u.role === 'staff'
                          ? 'bg-purple-50 text-purple-700 border-purple-200'
                          : 'bg-sky-50 text-sky-700 border-sky-200'
                      }`}
                    >
                      {u.role === 'admin' ? <Shield className="w-3 h-3" /> : <UserIcon className="w-3 h-3" />}
                      {u.role === 'admin' ? 'Quản trị viên (Admin)' : u.role === 'staff' ? 'Nhân viên (Staff)' : 'Khách hàng (User)'}
                    </span>
                  </td>

                  <td className="py-3 px-4">
                    <span
                      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full font-bold text-[10px] border ${
                        u.isLocked
                          ? 'bg-rose-50 text-rose-700 border-rose-200'
                          : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                      }`}
                    >
                      <span
                        className={`w-1.5 h-1.5 rounded-full ${
                          u.isLocked ? 'bg-rose-500' : 'bg-emerald-500'
                        }`}
                      />
                      {u.isLocked ? 'Đã bị khóa đăng nhập' : 'Đang hoạt động'}
                    </span>
                  </td>

                  <td className="py-3 px-4 font-mono text-slate-500">
                    {new Date(u.createdAt).toLocaleDateString('vi-VN')}
                  </td>

                  <td className="py-3 px-4 text-right">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        onClick={() => onToggleLock(u)}
                        disabled={u.email === 'admin@gmail.com'}
                        className={`p-1.5 rounded-lg border text-xs font-semibold flex items-center gap-1 transition-colors cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed ${
                          u.isLocked
                            ? 'bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100'
                            : 'bg-rose-50 text-rose-700 border-rose-200 hover:bg-rose-100'
                        }`}
                        title={u.isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản'}
                      >
                        {u.isLocked ? <Unlock className="w-3.5 h-3.5" /> : <Lock className="w-3.5 h-3.5" />}
                        {u.isLocked ? 'Mở khóa' : 'Khóa TK'}
                      </button>

                      <button
                        onClick={() => onEdit(u)}
                        className="p-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 hover:text-slate-900 border border-slate-200 transition-colors cursor-pointer"
                        title="Chỉnh sửa thông tin"
                      >
                        <Edit2 className="w-3.5 h-3.5" />
                      </button>

                      <button
                        onClick={() => onDelete(u)}
                        disabled={u.email === 'admin@gmail.com'}
                        className="p-1.5 rounded-lg bg-slate-100 hover:bg-rose-50 text-slate-500 hover:text-rose-600 border border-slate-200 transition-colors cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed"
                        title="Xóa tài khoản"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
