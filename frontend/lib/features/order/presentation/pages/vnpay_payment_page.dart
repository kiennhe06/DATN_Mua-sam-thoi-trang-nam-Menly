import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/order_model.dart';
import '../../data/vnpay_bank_model.dart';
import '../controllers/vnpay_payment_controller.dart';
import '../widgets/vnpay_bank_grid.dart';
import '../widgets/vnpay_bottom_bar.dart';
import '../widgets/vnpay_browser_dialog.dart';
import '../widgets/vnpay_countdown_header.dart';
import 'vnpay_webview_page.dart';

class VNPayPaymentPage extends StatefulWidget {
  final Order order;
  final String? initialBankCode;

  const VNPayPaymentPage({
    super.key,
    required this.order,
    this.initialBankCode,
  });

  @override
  State<VNPayPaymentPage> createState() => _VNPayPaymentPageState();
}

class _VNPayPaymentPageState extends State<VNPayPaymentPage> {
  late final VNPayPaymentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VNPayPaymentController();
    if (widget.initialBankCode != null && widget.initialBankCode!.isNotEmpty) {
      final bank = kVNPayBankList.firstWhere(
        (b) => b.code.toUpperCase() == widget.initialBankCode!.toUpperCase(),
        orElse: () => _controller.selectedBank,
      );
      _controller.setSelectedBank(bank);
    }
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

  /// 1. Dạng 1: Thanh toán Demo (Mô phỏng Sandbox hoàn tất ngay lập tức)
  Future<void> _handleDemoPayment() async {
    await _controller.completeDemoPayment(
      context,
      widget.order,
      true,
      onMessage: _showSnack,
      onNavigate: (path) => context.go(path),
    );
  }

  /// 2. Dạng 2: Thanh toán qua Cổng VNPay chính thức (WebView trong App)
  Future<void> _handleWebViewPayment() async {
    final url = await _controller.createPaymentUrl(
      widget.order,
      onMessage: _showSnack,
    );
    if (url != null && mounted) {
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
  }

  void _openExternalBrowser() {
    _controller.openVNPaySandboxUrl(
      context,
      widget.order,
      onMessage: _showSnack,
      onPostBrowser: () => VNPayBrowserDialog.show(
        context: context,
        onConfirmed: () => _controller.completeDemoPayment(
          context,
          widget.order,
          true,
          onMessage: _showSnack,
          onNavigate: (path) => context.go(path),
        ),
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
                      // Header đếm ngược thời gian và thông tin đơn
                      VNPayCountdownHeader(
                        order: widget.order,
                        controller: _controller,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Danh sách chọn ngân hàng (chỉ giữ chọn ngân hàng)
                      VNPayBankGrid(
                        controller: _controller,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),

              // Bottom Bar với 2 nút hành động chính: Thanh toán Demo và Cổng VNPay (WebView)
              VNPayBottomBar(
                order: widget.order,
                controller: _controller,
                onConfirmDemoPayment: _handleDemoPayment,
                onOpenWebView: _handleWebViewPayment,
                onOpenExternalBrowser: _openExternalBrowser,
              ),
            ],
          ),
        );
      },
    );
  }
}
