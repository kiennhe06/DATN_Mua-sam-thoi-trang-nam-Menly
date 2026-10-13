import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class ProfileShortcutsCard extends StatelessWidget {
  const ProfileShortcutsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _shortcutItem(
            c: c,
            icon: Icons.key_rounded,
            title: 'Đổi mật khẩu',
            subtitle: 'Cập nhật mật khẩu bảo vệ tài khoản',
            onTap: () => context.push('/change-password'),
          ),
          Divider(color: c.border.withValues(alpha: 0.6), height: 1),
          _shortcutItem(
            c: c,
            icon: Icons.local_shipping_outlined,
            title: 'Sổ địa chỉ nhận hàng',
            subtitle: 'Quản lý nhiều địa chỉ giao hàng',
            onTap: () => context.push('/shipping-address'),
          ),
        ],
      ),
    );
  }

  Widget _shortcutItem({
    required AppColors c,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: c.secondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: c.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
