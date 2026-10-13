import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../data/order_model.dart';
import '../controllers/vnpay_payment_controller.dart';
import '../widgets/vnpay_bank_grid.dart';
import '../widgets/vnpay_countdown_header.dart';
import '../widgets/vnpay_simulator_modal.dart';
import 'vnpay_webview_page.dart';

class VNPayPaymentPage extends StatefulWidget {
  final Order order;

  const VNPayPaymentPage({super.key, required this.order});

  @override
  State<VNPayPaymentPage> createState() => _VNPayPaymentPageState();
}

class _VNPayPaymentPageState extends State<VNPayPaymentPage> {
  late final VNPayPaymentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VNPayPaymentController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {Color? bg}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }

  void _showPostBrowserDialog() {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF005BAA).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.language_rounded, color: Color(0xFF005BAA), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đã mở cổng VNPay',
                style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cổng thanh toán VNPay Sandbox đã được mở trên trình duyệt của thiết bị.',
              style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin thẻ Sandbox NCB thử nghiệm:',
                    style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('• Số thẻ: 9704 1985 2619 1432 198', style: TextStyle(color: c.textSecondary, fontSize: 11)),
                  Text('• Tên chủ thẻ: NGUYEN VAN A', style: TextStyle(color: c.textSecondary, fontSize: 11)),
                  Text('• Ngày phát hành: 07/15', style: TextStyle(color: c.textSecondary, fontSize: 11)),
                  Text('• Mã OTP: 123456', style: TextStyle(color: c.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sau khi bạn thanh toán xong trên VNPay, bấm nút bên dưới để xác nhận đơn hàng.',
              style: TextStyle(color: c.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Để tôi quay lại sau', style: TextStyle(color: c.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _controller.completeDemoPayment(
                context,
                widget.order,
                true,
                onMessage: _showSnack,
                onNavigate: (path) => context.go(path),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005BAA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Tôi đã thanh toán thành công'),
          ),
        ],
      ),
    );
  }

  void _openVNPaySimulatorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VNPaySimulatorModal(
        order: widget.order,
        bank: _controller.selectedBank,
        onConfirmSuccess: () async {
          Navigator.pop(ctx);
          await _controller.completeDemoPayment(
            context,
            widget.order,
            true,
            onMessage: _showSnack,
            onNavigate: (path) => context.go(path),
          );
        },
        onCancelOrFailed: () async {
          Navigator.pop(ctx);
          await _controller.completeDemoPayment(
            context,
            widget.order,
            false,
            onMessage: _showSnack,
            onNavigate: (path) => context.go(path),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: c.background,
          appBar: AppBar(
            title: const Text('Cổng thanh toán VNPay'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VNPayCountdownHeader(
                        order: widget.order,
                        controller: _controller,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      VNPayBankGrid(
                        controller: _controller,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: BoxDecoration(
                  color: c.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -3),
                      blurRadius: 10,
                    ),
                  ],
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 16, color: c.textMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Đang chọn: ${_controller.selectedBank.name} - ${_controller.selectedBank.fullName}',
                              style: TextStyle(color: c.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      PrimaryButton(
                        label: 'Thanh toán VNPay (In-App WebView)',
                        icon: Icons.language_rounded,
                        loading: _controller.isCreatingUrl,
                        onPressed: (_controller.isSettling || _controller.isCreatingUrl)
                            ? null
                            : () async {
                                final url = await _controller.createPaymentUrl(
                                  widget.order,
                                  onMessage: _showSnack,
                                );
                                if (url != null && context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VNPayWebViewPage(
                                        order: widget.order,
                                        paymentUrl: url,
                                        bankCode: _controller.selectedBank.code,
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                      const SizedBox(height: 8),

                      OutlinedButton.icon(
                        onPressed: (_controller.isSettling || _controller.isCreatingUrl)
                            ? null
                            : _openVNPaySimulatorModal,
                        icon: const Icon(Icons.flash_on_rounded, size: 18),
                        label: const Text('Mô phỏng thanh toán Demo (Test nhanh)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF005BAA),
                          side: const BorderSide(color: Color(0xFF005BAA)),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 4),

                      TextButton.icon(
                        onPressed: (_controller.isSettling || _controller.isCreatingUrl)
                            ? null
                            : () => _controller.openVNPaySandboxUrl(
                                  context,
                                  widget.order,
                                  onMessage: _showSnack,
                                  onPostBrowser: _showPostBrowserDialog,
                                ),
                        icon: const Icon(Icons.open_in_browser_rounded, size: 14, color: Colors.grey),
                        label: const Text(
                          'Mở trên trình duyệt ngoài (Browser ngoài)',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
