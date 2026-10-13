import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/pressable.dart';

class AddressCardItem extends StatelessWidget {
  final Map<String, dynamic> address;
  final bool isDefault;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AddressCardItem({
    super.key,
    required this.address,
    required this.isDefault,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDefault
              ? c.secondary.withValues(alpha: 0.5)
              : c.border.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: isDefault ? c.secondary : c.textMuted,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  address['name'] ?? '',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    'Mặc định',
                    style: TextStyle(
                      color: c.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            address['phone'] ?? '',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            address['address'] ?? '',
            style: TextStyle(color: c.textMuted, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (!isDefault)
                Pressable(
                  onTap: onSetDefault,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: c.secondary),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      'Đặt mặc định',
                      style: TextStyle(
                        color: c.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              CircleIconButton(
                icon: Icons.edit_rounded,
                onTap: onEdit,
                size: 38,
                bordered: false,
                background: c.surfaceVariant,
                foreground: c.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleIconButton(
                icon: Icons.delete_outline_rounded,
                onTap: onDelete,
                size: 38,
                bordered: false,
                background: c.danger.withValues(alpha: 0.12),
                foreground: c.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
