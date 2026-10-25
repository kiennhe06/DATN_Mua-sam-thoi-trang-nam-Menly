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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        12,
        14,
        bottomInset > 0 ? bottomInset + 8 : 14,
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
              label: 'MUA NGAY',
              onPressed: disabled ? null : onBuyNow,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SecondaryButton(
              label: 'THÊM VÀO GIỎ',
              onPressed: disabled ? null : onAddToCart,
            ),
          ),
        ],
      ),
    );
  }
}
