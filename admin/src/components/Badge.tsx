import { OrderStatus } from '../lib/types';

export function OrderStatusBadge({ status }: { status: OrderStatus }) {
  const configs: Record<OrderStatus, { label: string; bg: string; text: string; dot: string; border: string }> = {
    pending_payment: {
      label: 'Chờ thanh toán',
      bg: 'bg-amber-50',
      text: 'text-amber-800',
      border: 'border-amber-200',
      dot: 'bg-amber-500',
    },
    paid: {
      label: 'Đã thanh toán',
      bg: 'bg-sky-50',
      text: 'text-sky-800',
      border: 'border-sky-200',
      dot: 'bg-sky-500',
    },
    processing: {
      label: 'Đang xử lý',
      bg: 'bg-indigo-50',
      text: 'text-indigo-800',
      border: 'border-indigo-200',
      dot: 'bg-indigo-500',
    },
    shipping: {
      label: 'Đang giao hàng',
      bg: 'bg-blue-50',
      text: 'text-blue-800',
      border: 'border-blue-200',
      dot: 'bg-blue-500',
    },
    completed: {
      label: 'Hoàn tất',
      bg: 'bg-emerald-50',
      text: 'text-emerald-800',
      border: 'border-emerald-200',
      dot: 'bg-emerald-500',
    },
    cancelled: {
      label: 'Đã hủy',
      bg: 'bg-rose-50',
      text: 'text-rose-800',
      border: 'border-rose-200',
      dot: 'bg-rose-500',
    },
  };

  const c = configs[status] || configs.pending_payment;

  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold border whitespace-nowrap shrink-0 ${c.bg} ${c.text} ${c.border}`}
    >
      <span className={`w-1.5 h-1.5 rounded-full shrink-0 ${c.dot}`} />
      <span className="whitespace-nowrap">{c.label}</span>
    </span>
  );
}

export function ReasonBadge({ reason }: { reason: string }) {
  const mapping: Record<string, { label: string; color: string }> = {
    admin_restock: { label: 'Nhập kho', color: 'text-emerald-800 bg-emerald-50 border-emerald-200' },
    admin_correction: { label: 'Hiệu chỉnh kho', color: 'text-amber-800 bg-amber-50 border-amber-200' },
    order_created: { label: 'Khách đặt hàng', color: 'text-blue-800 bg-blue-50 border-blue-200' },
    order_cancelled: { label: 'Hủy đơn hoàn kho', color: 'text-purple-800 bg-purple-50 border-purple-200' },
  };

  const item = mapping[reason] || { label: reason, color: 'text-slate-700 bg-slate-100 border-slate-200' };

  return (
    <span className={`px-2 py-0.5 rounded text-[11px] font-semibold border whitespace-nowrap shrink-0 ${item.color}`}>
      {item.label}
    </span>
  );
}
