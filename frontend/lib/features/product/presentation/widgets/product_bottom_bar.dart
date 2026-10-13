import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';

class ProductBottomBar extends StatelessWidget {
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final bool disabled;

  const ProductBottomBar({
    super.key,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: 'Mua ngay',
              icon: Icons.bolt_rounded,
              onPressed: disabled ? null : onBuyNow,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SecondaryButton(
              label: 'Thêm giỏ',
              icon: Icons.shopping_bag_outlined,
              onPressed: disabled ? null : onAddToCart,
            ),
          ),
        ],
      ),
    );
  }
}
