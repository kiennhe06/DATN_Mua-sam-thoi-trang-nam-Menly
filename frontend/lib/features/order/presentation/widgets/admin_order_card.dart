import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../data/order_model.dart';

class AdminOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onUpdateStatus;

  const AdminOrderCard({
    super.key,
    required this.order,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
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
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.code,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: order.statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: order.statusColor.withValues(alpha: 0.4),
                  ),
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
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: c.surfaceVariant, height: 1),
          ),

          // Shipping Info
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: c.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${order.shipName} (${order.shipPhone})',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: c.textMuted,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.shipAddress,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Items preview
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...order.items.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${i.productName} (${i.size}, ${i.color}) x${i.quantity}',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: c.surfaceVariant, height: 1),
          ),

          // Actions & Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng thu:',
                    style: TextStyle(color: c.textMuted, fontSize: 11),
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
              if (order.status == 'cancelled') ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: c.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: c.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.block_rounded,
                        size: 14,
                        color: c.danger,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Đã huỷ (Cố định)',
                        style: TextStyle(
                          color: c.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SecondaryButton(
                  label: 'Đổi trạng thái',
                  icon: Icons.edit_note_rounded,
                  expanded: false,
                  height: 44,
                  onPressed: onUpdateStatus,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
