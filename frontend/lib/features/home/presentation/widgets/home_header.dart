import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/display_settings.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.fullName ?? 'Khách';

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 10,
        20,
        4,
      ),
      color: c.background,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: c.primarySoft,
                child: Icon(Icons.person_rounded, color: c.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.isLoggedIn ? 'Xin chào' : 'Chào mừng đến',
                      style: TextStyle(color: c.textSecondary, fontSize: 12.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auth.isLoggedIn ? name : 'Menly Boutique',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Consumer<NotificationProvider>(
                builder: (context, notif, _) => _HeaderIcon(
                  icon: Icons.notifications_none_rounded,
                  badgeCount: notif.unreadCount,
                  onTap: () => context.push('/notifications'),
                ),
              ),
              const SizedBox(width: 10),
              const DisplaySettingsButton(),
            ],
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => context.go('/products'),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: c.textMuted),
                  const SizedBox(width: 10),
                  Text(
                    'Tìm kiếm sản phẩm...',
                    style: TextStyle(color: c.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: c.surfaceVariant,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, size: 21, color: c.textPrimary),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: c.secondary,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(color: c.surface, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
