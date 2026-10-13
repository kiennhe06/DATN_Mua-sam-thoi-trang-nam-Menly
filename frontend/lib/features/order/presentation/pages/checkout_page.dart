import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_buttons.dart';
import '../../../cart/data/cart_model.dart';
import '../controllers/checkout_controller.dart';
import '../widgets/checkout_address_section.dart';
import '../widgets/checkout_order_summary.dart';
import '../widgets/checkout_payment_section.dart';
import '../widgets/checkout_voucher_section.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final CheckoutController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CheckoutController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.init(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {Color? bg, Duration duration = const Duration(milliseconds: 1500)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Thanh toán'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckoutAddressSection(controller: _controller),
                const SizedBox(height: 16),
                CheckoutPaymentSection(controller: _controller),
                const SizedBox(height: 16),
                CheckoutVoucherSection(
                  controller: _controller,
                  cart: cart,
                  onMessage: _showSnack,
                ),
                const SizedBox(height: 16),
                CheckoutOrderSummary(
                  controller: _controller,
                  cart: cart,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _controller.paymentMethod == 'vnpay'
                      ? 'Tiếp tục thanh toán VNPay'
                      : 'Đặt hàng ngay',
                  icon: _controller.paymentMethod == 'vnpay'
                      ? Icons.payment_rounded
                      : Icons.shopping_bag_outlined,
                  loading: _controller.loading,
                  onPressed: _controller.loading
                      ? null
                      : () => _controller.placeOrder(
                            context,
                            cart,
                            onMessage: _showSnack,
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
