import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../data/order_model.dart';

class OrderPaymentSummaryCard extends StatelessWidget {
  final Order order;

  const OrderPaymentSummaryCard({super.key, required this.order});

  Widget _summaryRow(String label, String value, AppColors c, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? c.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: c.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Chi tiết thanh toán',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _summaryRow('Tổng tiền hàng', formatPrice(order.subtotal), c),
          const SizedBox(height: 8),
          _summaryRow(
            'Phí vận chuyển',
            order.shippingFee > 0 ? formatPrice(order.shippingFee) : 'Miễn phí',
            c,
          ),
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow(
              'Giảm giá voucher ${order.voucherCode != null ? "(${order.voucherCode})" : ""}',
              '-${formatPrice(order.discountAmount)}',
              c,
              valueColor: c.secondary,
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: c.surfaceVariant, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng thanh toán',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                order.formattedTotal,
                style: TextStyle(
                  color: c.secondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Phương thức thanh toán
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  order.paymentMethod == 'vnpay'
                      ? Icons.credit_card_rounded
                      : Icons.local_shipping_outlined,
                  color: c.secondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.paymentMethod == 'vnpay'
                            ? 'Thanh toán online VNPay'
                            : 'Thanh toán khi nhận hàng (COD)',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        order.paymentMethod == 'vnpay'
                            ? 'Đã xác nhận thanh toán an toàn'
                            : 'Khách hàng thanh toán tiền mặt khi shipper giao hàng',
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
