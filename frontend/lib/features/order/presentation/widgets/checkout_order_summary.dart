import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../../cart/data/cart_model.dart';
import '../controllers/checkout_controller.dart';
import 'checkout_section_card.dart';

class CheckoutOrderSummary extends StatelessWidget {
  final CheckoutController controller;
  final CartProvider cart;

  const CheckoutOrderSummary({
    super.key,
    required this.controller,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final finalTotal = (cart.selectedTotalPrice - controller.discountAmount) > 0
        ? (cart.selectedTotalPrice - controller.discountAmount)
        : 0;

    return CheckoutSectionCard(
      title: 'Đơn hàng',
      children: [
        ...cart.selectedItems.map((i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${i.product.name} (${i.variant.size}) x${i.quantity}',
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
              ),
              Text(
                formatPrice(i.subtotal),
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        )),
        Divider(height: 28, thickness: 1, color: c.border),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tạm tính', style: TextStyle(color: c.textSecondary, fontSize: 13)),
            Text(
              formatPrice(cart.selectedTotalPrice),
              style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        if (controller.discountAmount > 0) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 14, color: c.secondary),
                  const SizedBox(width: 4),
                  Text(
                    'Mã giảm giá (${controller.appliedVoucher?.code ?? ""})',
                    style: TextStyle(color: c.secondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                '-${formatPrice(controller.discountAmount)}',
                style: TextStyle(color: c.secondary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Phí vận chuyển', style: TextStyle(color: c.textSecondary, fontSize: 13)),
            Text('Miễn phí', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
        Divider(height: 28, thickness: 1, color: c.border),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tổng thanh toán', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
            Text(
              formatPrice(finalTotal),
              style: TextStyle(color: c.secondary, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }
}
