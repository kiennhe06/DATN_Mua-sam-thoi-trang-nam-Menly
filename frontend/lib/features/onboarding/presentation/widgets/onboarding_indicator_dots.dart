import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingIndicatorDots extends StatelessWidget {
  final int count;
  final int active;

  const OnboardingIndicatorDots({
    super.key,
    required this.count,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 6),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active ? c.primary : c.border,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
          ),
      ],
    );
  }
}
