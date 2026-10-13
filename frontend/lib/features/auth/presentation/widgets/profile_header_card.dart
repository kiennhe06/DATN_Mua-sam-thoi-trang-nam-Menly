import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'user_avatar_view.dart';

class ProfileHeaderCard extends StatelessWidget {
  final AuthUser user;

  const ProfileHeaderCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    String roleLabel = 'Khách hàng';
    Color roleColor = c.secondary;
    if (user.isAdmin) {
      roleLabel = 'Quản trị viên (Admin)';
      roleColor = const Color(0xFFEF4444);
    } else if (user.isStaff) {
      roleLabel = 'Nhân viên vận hành';
      roleColor = const Color(0xFF3B82F6);
    }

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => context.push('/edit-profile'),
            child: UserAvatarView(
              avatarUrl: user.avatarUrl,
              fullName: user.fullName,
              size: 84,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            user.fullName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            user.email,
            style: TextStyle(fontSize: 13, color: c.textMuted),
          ),
          if (user.phone != null && user.phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_outlined, size: 13, color: c.textMuted),
                const SizedBox(width: 4),
                Text(
                  user.phone!,
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              border: Border.all(color: roleColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isAdmin
                      ? Icons.shield_rounded
                      : (user.isStaff
                          ? Icons.badge_rounded
                          : Icons.person_rounded),
                  size: 14,
                  color: roleColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  roleLabel,
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/edit-profile'),
            icon: Icon(Icons.edit_outlined, size: 14, color: c.textPrimary),
            label: Text(
              'Chỉnh sửa hồ sơ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: c.surface,
              foregroundColor: c.textPrimary,
              side: BorderSide(color: c.border),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
