import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingCollage extends StatelessWidget {
  final List<String> images;

  const OnboardingCollage({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: colors.primarySoft,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: _tile(images[0], 190, 150, 'Chất lượng', colors),
        ),
        Align(
          alignment: Alignment.topRight,
          child: _tile(images[1], 130, 150, 'Phong cách', colors),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _tile(images[2], 200, 170, 'Giao nhanh', colors),
        ),
      ],
    );
  }

  Widget _tile(
    String url,
    double w,
    double h,
    String tag,
    AppColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: CachedNetworkImage(
              imageUrl: url,
              width: w,
              height: h,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(width: w, height: h, color: colors.surfaceVariant),
              errorWidget: (_, __, ___) =>
                  Container(width: w, height: h, color: colors.surfaceVariant),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.inkCard.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: colors.onInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
