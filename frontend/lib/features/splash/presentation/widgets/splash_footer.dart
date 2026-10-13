import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SplashFooter extends StatelessWidget {
  final Animation<double> fadeAnimation;

  const SplashFooter({super.key, required this.fadeAnimation});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 48,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primary.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'MENLY APPAREL • PREMIUM EDITION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
