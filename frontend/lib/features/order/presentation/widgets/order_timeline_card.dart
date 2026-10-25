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
        return 0; // Đã đặt hàng
      case 'paid':
      case 'confirmed':
      case 'pending_confirmation':
        return 1; // Đã duyệt
      case 'processing':
        return 2; // Đang đóng gói
      case 'shipping':
        return 3; // Đang vận chuyển
      case 'completed':
      case 'delivered':
        return 4; // Đã giao hàng
      case 'cancelled':
        return -1;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final currentStep = getTimelineStep(order.status);
    final isCancelled = order.status == 'cancelled';
    final trackingCode = 'MENLY-${order.code.isNotEmpty ? order.code.replaceAll('#', '') : 'VN8921'}';

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
                'Tiến trình 5 bước đơn hàng',
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
              stepNumber: 1,
              title: '1. Đã đặt hàng',
              desc: 'Đơn hàng đã được tiếp nhận trên hệ thống',
              isCompleted: currentStep >= 0,
              isActive: currentStep == 0,
              isLast: false,
              c: c,
            ),
            _buildTimelineStep(
              stepNumber: 2,
              title: '2. Đã duyệt',
              desc: 'Cửa hàng đã xác nhận thông tin đơn hàng',
              isCompleted: currentStep >= 1,
              isActive: currentStep == 1,
              isLast: false,
              c: c,
            ),
            _buildTimelineStep(
              stepNumber: 3,
              title: '3. Đang đóng gói',
              desc: 'Đang kiểm tra chất lượng và đóng gói chuẩn Menly',
              isCompleted: currentStep >= 2,
              isActive: currentStep == 2,
              isLast: false,
              c: c,
            ),
            _buildTimelineStep(
              stepNumber: 4,
              title: '4. Đang vận chuyển',
              desc: 'Mã vận đơn: $trackingCode (Giao hàng hỏa tốc)',
              isCompleted: currentStep >= 3,
              isActive: currentStep == 3,
              isLast: false,
              c: c,
              highlightBadge: currentStep >= 3 ? 'Đang trên đường giao' : null,
            ),
            _buildTimelineStep(
              stepNumber: 5,
              title: '5. Đã giao hàng',
              desc: 'Kiện hàng đã bàn giao thành công đến bạn',
              isCompleted: currentStep >= 4,
              isActive: currentStep == 4,
              isLast: true,
              c: c,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required int stepNumber,
    required String title,
    required String desc,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
    required AppColors c,
    String? highlightBadge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
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
                  : Center(
                      child: Text(
                        '$stepNumber',
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
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
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isCompleted ? c.textPrimary : c.textMuted,
                        fontSize: 13,
                        fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (highlightBadge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          highlightBadge,
                          style: TextStyle(
                            color: c.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
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
