import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../../cart/data/cart_model.dart';
import '../controllers/checkout_controller.dart';
import 'checkout_section_card.dart';

class CheckoutVoucherSection extends StatelessWidget {
  final CheckoutController controller;
  final CartProvider cart;
  final void Function(String msg, {Color? bg}) onMessage;

  const CheckoutVoucherSection({
    super.key,
    required this.controller,
    required this.cart,
    required this.onMessage,
  });

  void _showVoucherPicker(BuildContext context) {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mã giảm giá MenShop',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close, color: c.textMuted, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (controller.loadingVouchers)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(color: c.secondary)),
                  )
                else if (controller.availableVouchers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Hiện chưa có mã giảm giá nào',
                        style: TextStyle(color: c.textMuted, fontSize: 13),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: controller.availableVouchers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final v = controller.availableVouchers[i];
                        final isEligible = cart.selectedTotalPrice >= v.minOrderValue;
                        final isSelected = controller.appliedVoucher?.code == v.code;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? c.primarySoft : c.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? c.secondary
                                  : isEligible
                                      ? c.border
                                      : c.border.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isEligible ? c.primarySoft : c.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.local_offer_rounded,
                                  color: isEligible ? c.secondary : c.textMuted,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          v.code,
                                          style: TextStyle(
                                            color: isEligible ? c.textPrimary : c.textMuted,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isEligible ? c.primarySoft : c.surface,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              v.discountDescription,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isEligible ? c.secondary : c.textMuted,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      v.title,
                                      style: TextStyle(
                                        color: c.textSecondary,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      v.minOrderValue > 0
                                          ? 'Đơn tối thiểu ${formatPrice(v.minOrderValue)}'
                                          : 'Áp dụng cho mọi đơn hàng',
                                      style: TextStyle(
                                        color: isEligible ? c.textMuted : Colors.red.shade400,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isSelected)
                                TextButton(
                                  onPressed: () {
                                    controller.removeVoucher(onMessage: onMessage);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Bỏ chọn', style: TextStyle(color: Colors.red, fontSize: 12)),
                                )
                              else if (isEligible)
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    controller.applyVoucher(
                                      v.code,
                                      cart.selectedTotalPrice,
                                      onMessage: onMessage,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: c.primary,
                                    foregroundColor: c.onPrimary,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Dùng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: c.surface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Thiếu ${formatPrice(v.minOrderValue - cart.selectedTotalPrice)}',
                                    style: TextStyle(color: c.textMuted, fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return CheckoutSectionCard(
      title: 'Mã khuyến mãi / Voucher',
      children: [
        if (controller.appliedVoucher != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.secondary.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.secondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.confirmation_number_rounded, color: c.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            controller.appliedVoucher!.code,
                            style: TextStyle(
                              color: c.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${formatPrice(controller.discountAmount)}',
                              style: TextStyle(
                                color: c.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.appliedVoucher!.title,
                        style: TextStyle(color: c.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => controller.removeVoucher(onMessage: onMessage),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: Colors.red.shade400,
                  tooltip: 'Gỡ mã',
                ),
              ],
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.voucherCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Nhập mã giảm giá...',
                    prefixIcon: Icon(Icons.local_offer_outlined, size: 18, color: c.textMuted),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: controller.applyingVoucher
                    ? null
                    : () => controller.applyVoucher(
                          controller.voucherCtrl.text,
                          cart.selectedTotalPrice,
                          onMessage: onMessage,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: controller.applyingVoucher
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Áp dụng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _showVoucherPicker(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.discount_outlined, size: 16, color: c.secondary),
                      const SizedBox(width: 8),
                      Text(
                        controller.availableVouchers.isNotEmpty
                            ? 'Xem danh sách (${controller.availableVouchers.length} mã khả dụng)'
                            : 'Xem tất cả mã giảm giá',
                        style: TextStyle(
                          color: c.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.chevron_right, size: 16, color: c.secondary),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
