import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class AuthBrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 60),
        // Logo
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: c.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.shopping_bag_rounded,
              color: c.onPrimary,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'MENLY',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: c.textPrimary,
              letterSpacing: 3,
            ),
          ),
        ),
        Center(
          child: Text(
            'Thời trang nam cao cấp',
            style: TextStyle(fontSize: 13, color: c.textMuted),
          ),
        ),
        const SizedBox(height: 48),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: c.textMuted),
        ),
      ],
    );
  }
}
