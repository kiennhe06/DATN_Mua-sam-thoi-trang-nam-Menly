import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class WishlistEmptyView extends StatelessWidget {
  const WishlistEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.surfaceVariant,
                border: Border.all(color: c.border),
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Danh sách yêu thích trống',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thả tim những sản phẩm bạn thích để lưu lại và mua sắm tiện lợi hơn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/products'),
              child: const Text('Khám phá sản phẩm ngay'),
            ),
          ],
        ),
      ),
    );
  }
}
