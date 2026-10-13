import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/checkout_controller.dart';
import 'checkout_section_card.dart';

class CheckoutPaymentSection extends StatelessWidget {
  final CheckoutController controller;

  const CheckoutPaymentSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return CheckoutSectionCard(
      title: 'Phương thức thanh toán',
      children: [
        _PayOption(
          label: 'Thanh toán khi nhận hàng (COD)',
          subtitle: 'Thanh toán tiền mặt khi shipper giao hàng tận nơi',
          icon: Icons.local_shipping_rounded,
          value: 'cod',
          groupValue: controller.paymentMethod,
          onChanged: (v) => controller.setPaymentMethod(v!),
        ),
        _PayOption(
          label: 'Thanh toán trực tuyến VNPay',
          subtitle: 'Hỗ trợ thẻ ATM nội địa, QR Code, thẻ Quốc tế',
          trailingBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF005BAA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Sandbox',
              style: TextStyle(
                color: Color(0xFF005BAA),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          icon: Icons.payment_rounded,
          value: 'vnpay',
          groupValue: controller.paymentMethod,
          onChanged: (v) => controller.setPaymentMethod(v!),
        ),
      ],
    );
  }
}

class _PayOption extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget? trailingBadge;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PayOption({
    required this.label,
    this.subtitle,
    this.trailingBadge,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? c.primarySoft : c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? c.secondary : c.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? c.secondary : c.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? c.textPrimary : c.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      ?trailingBadge,
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(color: c.textMuted, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: c.secondary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
