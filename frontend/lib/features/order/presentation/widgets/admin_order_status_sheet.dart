import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/order_model.dart';
import '../providers/order_provider.dart';

class AdminOrderStatusSheet {
  static void show(BuildContext context, Order order) {
    final c = AppColors.of(context);
    if (order.status == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '⚠️ Đơn hàng đã ở trạng thái ĐÃ HUỶ, không thể chuyển sang trạng thái khác.',
          ),
          backgroundColor: c.danger,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (ctx) {
        final options = [
          {
            'id': 'pending_payment',
            'label': 'Chờ xác nhận',
            'color': const Color(0xFFF59E0B),
          },
          {
            'id': 'processing',
            'label': 'Đang xử lý đóng gói',
            'color': const Color(0xFF8B5CF6),
          },
          {
            'id': 'shipping',
            'label': 'Đang giao hàng',
            'color': const Color(0xFF06B6D4),
          },
          {
            'id': 'completed',
            'label': 'Giao hàng thành công',
            'color': const Color(0xFF10B981),
          },
          {
            'id': 'cancelled',
            'label': 'Huỷ đơn hàng',
            'color': const Color(0xFFEF4444),
          },
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cập nhật trạng thái: ${order.code}',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                ...options.map((opt) {
                  final isCurrent = order.status == opt['id'];
                  final optColor = opt['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      onTap: isCurrent
                          ? null
                          : () async {
                              Navigator.of(ctx).pop();
                              final success = await context
                                  .read<OrderProvider>()
                                  .updateOrderStatus(
                                    order.id,
                                    opt['id'] as String,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? '✅ Đã cập nhật trạng thái đơn ${order.code}'
                                          : '❌ Cập nhật thất bại. Đơn hàng có thể đã huỷ hoặc không hợp lệ.',
                                    ),
                                    backgroundColor:
                                        success ? c.success : c.danger,
                                  ),
                                );
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? optColor.withValues(alpha: 0.15)
                              : c.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: isCurrent ? optColor : c.border,
                            width: isCurrent ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: optColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  opt['label'] as String,
                                  style: TextStyle(
                                    color: c.textPrimary,
                                    fontSize: 14,
                                    fontWeight: isCurrent
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (isCurrent)
                              Icon(
                                Icons.check_circle_rounded,
                                color: c.secondary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
