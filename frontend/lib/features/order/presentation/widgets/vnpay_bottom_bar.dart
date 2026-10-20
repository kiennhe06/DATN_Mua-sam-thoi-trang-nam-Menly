import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../data/order_model.dart';
import '../controllers/vnpay_payment_controller.dart';

class VNPayBottomBar extends StatelessWidget {
  final Order order;
  final VNPayPaymentController controller;
  final VoidCallback onConfirmDemoPayment;
  final VoidCallback onOpenWebView;
  final VoidCallback onOpenExternalBrowser;

  const VNPayBottomBar({
    super.key,
    required this.order,
    required this.controller,
    required this.onConfirmDemoPayment,
    required this.onOpenWebView,
    required this.onOpenExternalBrowser,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isBusy = controller.isSettling || controller.isCreatingUrl;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: c.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, -3),
            blurRadius: 12,
          ),
        ],
        border: Border(top: BorderSide(color: c.border.withValues(alpha: 0.8))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_rounded, size: 16, color: const Color(0xFF005BAA)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ngân hàng: ${controller.selectedBank.name} (${controller.selectedBank.code}) • Đơn: ${order.code}',
                    style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 2 Dạng thanh toán chính: Demo và WebView
            PrimaryButton(
              label: 'Thanh toán Demo (${formatPrice(order.total)})',
              icon: Icons.flash_on_rounded,
              loading: controller.isSettling,
              onPressed: isBusy ? null : onConfirmDemoPayment,
            ),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: isBusy ? null : onOpenWebView,
              icon: controller.isCreatingUrl
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF005BAA)),
                    )
                  : const Icon(Icons.language_rounded, size: 18),
              label: Text(
                controller.isCreatingUrl ? 'Đang tạo liên kết...' : 'Thanh toán VNPay (WebView)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF005BAA),
                side: const BorderSide(color: Color(0xFF005BAA), width: 1.5),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 4),

            TextButton.icon(
              onPressed: isBusy ? null : onOpenExternalBrowser,
              icon: const Icon(Icons.open_in_browser_rounded, size: 14, color: Colors.grey),
              label: const Text(
                'Mở cổng thanh toán bằng trình duyệt ngoài',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
