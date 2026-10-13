import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../data/cart_model.dart';

class CartBottomBar extends StatelessWidget {
  final CartProvider cart;
  final VoidCallback onCheckout;

  const CartBottomBar({
    super.key,
    required this.cart,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasSelection = cart.selectedCount > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng cộng:',
                style: TextStyle(color: c.textSecondary, fontSize: 15),
              ),
              Text(
                formatVnd(cart.selectedTotalPrice),
                style: TextStyle(
                  color: c.secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: hasSelection
                ? 'Thanh toán (${cart.selectedCount})'
                : 'Chọn sản phẩm để mua',
            icon: Icons.payment_rounded,
            onPressed: hasSelection ? onCheckout : null,
          ),
        ],
      ),
    );
  }
}
