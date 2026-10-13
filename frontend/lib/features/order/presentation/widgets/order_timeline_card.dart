import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/order_model.dart';

class OrderTimelineCard extends StatelessWidget {
  final Order order;

  const OrderTimelineCard({super.key, required this.order});

  static int getTimelineStep(String status) {
    switch (status) {
      case 'pending_payment':
      case 'pending':
        return 0;
      case 'paid':
      case 'processing':
        return 1;
      case 'shipping':
        return 2;
      case 'completed':
      case 'delivered':
        return 3;
      case 'cancelled':
        return -1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final currentStep = getTimelineStep(order.status);
    final isCancelled = order.status == 'cancelled';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isCancelled
              ? c.danger.withValues(alpha: 0.3)
              : c.border.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCancelled ? Icons.cancel_outlined : Icons.timeline_rounded,
                color: isCancelled ? c.danger : c.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tiến trình đơn hàng',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                order.formattedDate,
                style: TextStyle(color: c.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (isCancelled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: c.danger.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: c.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn hàng đã huỷ',
                          style: TextStyle(
                            color: c.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (order.note != null && order.note!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Lý do: ${order.note}',
                            style: TextStyle(color: c.textSecondary, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildTimelineStep(
              title: 'Đã đặt hàng',
              desc: 'Đơn hàng đã được tạo thành công trên hệ thống',
              isCompleted: currentStep >= 0,
              isActive: currentStep == 0,
              isLast: false,
              c: c,
            ),
            _buildTimelineStep(
              title: 'Đã xác nhận & Đóng gói',
              desc: 'Cửa hàng đã duyệt đơn và chuẩn bị hàng',
              isCompleted: currentStep >= 1,
              isActive: currentStep == 1,
              isLast: false,
              c: c,
            ),
            _buildTimelineStep(
              title: 'Đang giao hàng',
              desc: 'Đơn hàng đang trên đường giao đến bạn',
              isCompleted: currentStep >= 2,
              isActive: currentStep == 2,
              isLast: false,
              c: c,
            ),
            _buildTimelineStep(
              title: 'Hoàn tất đơn hàng',
              desc: 'Giao hàng thành công đến khách hàng',
              isCompleted: currentStep >= 3,
              isActive: currentStep == 3,
              isLast: true,
              c: c,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String desc,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
    required AppColors c,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted ? c.secondary : c.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? c.secondary : c.border,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isCompleted && !isActive ? c.secondary : c.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isCompleted ? c.textPrimary : c.textMuted,
                    fontSize: 13,
                    fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
