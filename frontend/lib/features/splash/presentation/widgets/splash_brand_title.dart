import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SplashBrandTitle extends StatelessWidget {
  final Animation<Offset> slideAnimation;

  const SplashBrandTitle({super.key, required this.slideAnimation});

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'MEN',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: 'LY',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Slogan cao cấp
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 1,
                color: AppTheme.primary.withValues(alpha: 0.5),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'ĐẲNG CẤP THỜI TRANG PHÁI MẠNH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 1,
                color: AppTheme.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
