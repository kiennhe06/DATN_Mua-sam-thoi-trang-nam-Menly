import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../cart/data/cart_model.dart';
import '../../data/order_model.dart';
import 'order_cancel_dialog.dart';
import 'order_review_sheet.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onCancelled;

  const OrderCard({
    super.key,
    required this.order,
    this.onCancelled,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final canCancel = order.status == 'pending_payment' ||
        order.status == 'pending' ||
        order.status == 'processing';
    final canReview = order.status == 'completed' || order.status == 'delivered';

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      onTap: () => context.push('/orders/${order.id}', extra: order),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: order.status == 'cancelled'
                ? c.danger.withValues(alpha: 0.3)
                : c.border.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Code & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_rounded, color: c.secondary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      order.code,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: order.statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(
                      color: order.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order.formattedDate,
              style: TextStyle(color: c.textMuted, fontSize: 12),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: c.surfaceVariant, height: 1),
            ),

            // Items Preview
            if (order.items.isNotEmpty) ...[
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      onTap: () async {
                        final pid = await OrderReviewSheet.resolveProductId(item);
                        if (pid != null && pid.isNotEmpty && context.mounted) {
                          context.push('/products/$pid');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: c.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${item.productName}${item.size.isNotEmpty ? ' (${item.size}, ${item.color})' : ''}',
                                style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'x${item.quantity}',
                              style: TextStyle(
                                color: c.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            if (canReview) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => OrderReviewSheet.showProductReviewForm(context, item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: c.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                    border: Border.all(color: c.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Đánh giá',
                                        style: TextStyle(
                                          color: c.textPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )),
            ],

            // Lý do huỷ nếu có
            if (order.status == 'cancelled' && order.note != null && order.note!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: c.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: c.danger.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: c.danger, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Lý do: ${order.note}',
                        style: TextStyle(color: c.danger, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: c.surfaceVariant, height: 1),
            ),

            // Footer: Phương thức & Tổng tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      order.paymentMethod == 'vnpay'
                          ? Icons.credit_card_rounded
                          : Icons.local_shipping_outlined,
                      color: c.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.paymentMethod == 'vnpay' ? 'VNPay' : 'Thanh toán COD',
                      style: TextStyle(color: c.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Tổng tiền: ',
                      style: TextStyle(color: c.textSecondary, fontSize: 13),
                    ),
                    Text(
                      order.formattedTotal,
                      style: TextStyle(
                        color: c.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Action buttons
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Xem chi tiết',
                    icon: Icons.visibility_outlined,
                    height: 42,
                    onPressed: () => context.push('/orders/${order.id}', extra: order),
                  ),
                ),
                const SizedBox(width: 8),
                if (order.paymentMethod == 'vnpay' &&
                    (order.status == 'pending_payment' || order.status == 'pending'))
                  Expanded(
                    child: PrimaryButton(
                      label: 'Thanh toán VNPay',
                      icon: Icons.payment_rounded,
                      height: 42,
                      onPressed: () => context.push('/payment/vnpay', extra: order),
                    ),
                  )
                else
                  Expanded(
                    child: PrimaryButton(
                      label: 'Mua lại',
                      icon: Icons.replay_rounded,
                      height: 42,
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final cart = context.read<CartProvider>();
                        await cart.reorderItems(order.items);
                        messenger.hideCurrentSnackBar();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Đã thêm ${order.items.length} món vào giỏ hàng!'),
                            backgroundColor: c.secondary,
                            action: SnackBarAction(
                              label: 'Giỏ hàng',
                              textColor: Colors.white,
                              onPressed: () => context.go('/cart'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),

            if (canCancel) ...[
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Huỷ đơn hàng',
                icon: Icons.cancel_outlined,
                height: 42,
                foreground: AppColors.of(context).danger,
                onPressed: () async {
                  final cancelled = await OrderCancelDialog.show(context, order);
                  if (cancelled == true) {
                    onCancelled?.call();
                  }
                },
              ),
            ],

            if (canReview) ...[
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: 'Đánh giá sản phẩm',
                icon: Icons.rate_review_outlined,
                height: 42,
                onPressed: () => OrderReviewSheet.show(context, order),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
