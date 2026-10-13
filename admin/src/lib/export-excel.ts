import { Order, OrderStatus } from './types';

const STATUS_TEXT_MAP: Record<OrderStatus, string> = {
  pending_payment: 'Chờ thanh toán',
  paid: 'Đã thanh toán',
  processing: 'Đang xử lý',
  shipping: 'Đang giao hàng',
  completed: 'Đã hoàn tất',
  cancelled: 'Đã hủy',
};

function escapeCsvField(field: unknown): string {
  if (field == null) return '""';
  const str = String(field).replace(/"/g, '""');
  return `"${str}"`;
}

export function exportOrdersToCSV(orders: Order[], filenamePrefix = 'Bao_cao_don_hang_Menly') {
  if (!orders || orders.length === 0) {
    alert('Không có dữ liệu đơn hàng để xuất báo cáo.');
    return;
  }

  const headers = [
    'STT',
    'Mã đơn hàng',
    'Thời gian tạo',
    'Trạng thái đơn hàng',
    'Khách hàng',
    'Số điện thoại',
    'Địa chỉ nhận hàng',
    'Ghi chú',
    'Phương thức thanh toán',
    'Danh sách mặt hàng',
    'Tổng số lượng mặt hàng',
    'Tạm tính (VNĐ)',
    'Phí giao hàng (VNĐ)',
    'Mã Voucher',
    'Tiền giảm giá (VNĐ)',
    'Tổng tiền thanh toán (VNĐ)',
  ];

  const rows = orders.map((o, idx) => {
    const statusText = STATUS_TEXT_MAP[o.status] || o.status;
    const dateFormatted = new Date(o.createdAt).toLocaleString('vi-VN');
    const paymentText = o.paymentMethod === 'vnpay' ? 'VNPay (Trực tuyến)' : 'COD (Tiền mặt)';
    const recipientName = o.shippingAddress?.name || o.shipName || '';
    const recipientPhone = o.shippingAddress?.phone || o.shipPhone || '';
    const recipientAddress = o.shippingAddress?.address || o.shipAddress || '';
    const note = o.shippingAddress?.note || '';

    const itemsSummary = (o.items || [])
      .map(
        (it) =>
          `${it.productName} (Size: ${it.size}, Màu: ${it.color}) x${it.quantity} [${it.unitPrice.toLocaleString('vi-VN')} đ]`
      )
      .join('; ');

    const totalItemsCount = (o.items || []).reduce((sum, it) => sum + (it.quantity || 1), 0);

    return [
      escapeCsvField(idx + 1),
      escapeCsvField(`#${o.code}`),
      escapeCsvField(dateFormatted),
      escapeCsvField(statusText),
      escapeCsvField(recipientName),
      escapeCsvField(recipientPhone),
      escapeCsvField(recipientAddress),
      escapeCsvField(note),
      escapeCsvField(paymentText),
      escapeCsvField(itemsSummary),
      escapeCsvField(totalItemsCount),
      escapeCsvField(o.subtotal || o.total),
      escapeCsvField(o.shippingFee || 0),
      escapeCsvField(o.voucherCode || ''),
      escapeCsvField(o.discountAmount || 0),
      escapeCsvField(o.total),
    ].join(',');
  });

  // Calculate summary row
  const totalRevenue = orders
    .filter((o) => o.status !== 'cancelled')
    .reduce((sum, o) => sum + (o.total || 0), 0);
  const totalOrders = orders.length;
  const completedOrders = orders.filter((o) => o.status === 'completed').length;
  const cancelledOrders = orders.filter((o) => o.status === 'cancelled').length;

  const emptySummaryCols = Array(14).fill('""').join(',');
  const summaryRow = [
    escapeCsvField('TỔNG KẾT'),
    escapeCsvField(`Tổng: ${totalOrders} đơn (${completedOrders} hoàn tất, ${cancelledOrders} hủy)`),
    emptySummaryCols,
    escapeCsvField(totalRevenue),
  ].join(',');

  // UTF-8 BOM prefix (\uFEFF) ensures Excel opens Vietnamese accents without mojibake
  const csvContent = '\uFEFF' + [headers.join(','), ...rows, '', summaryRow].join('\r\n');

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');

  const now = new Date();
  const timestamp = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(
    now.getDate()
  ).padStart(2, '0')}_${String(now.getHours()).padStart(2, '0')}${String(
    now.getMinutes()
  ).padStart(2, '0')}`;

  link.setAttribute('href', url);
  link.setAttribute('download', `${filenamePrefix}_${timestamp}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
