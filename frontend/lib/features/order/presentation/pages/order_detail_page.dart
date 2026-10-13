import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../cart/data/cart_model.dart';
import '../../data/order_model.dart';
import '../providers/order_provider.dart';
import '../widgets/order_cancel_dialog.dart';
import '../widgets/order_items_card.dart';
import '../widgets/order_payment_summary_card.dart';
import '../widgets/order_recipient_card.dart';
import '../widgets/order_timeline_card.dart';

class OrderDetailPage extends StatefulWidget {
  final Order? order;
  final String orderId;

  const OrderDetailPage({super.key, this.order, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (_order == null) {
      _loadOrder();
    }
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderProvider = context.read<OrderProvider>();
      final myOrders = orderProvider.myOrdersState.data ?? [];
      final found = myOrders.where((o) => o.id == widget.orderId).firstOrNull;

      if (found != null) {
        setState(() {
          _order = found;
          _isLoading = false;
        });
        return;
      }

      final dio = DioClient().dio;
      final res = await dio.get('/orders/${widget.orderId}');
      if (res.statusCode == 200 && res.data != null) {
        final orderData = res.data['order'] ?? res.data['data'] ?? res.data;
        setState(() {
          _order = Order.fromJson(orderData as Map<String, dynamic>);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không tìm thấy thông tin đơn hàng';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải đơn hàng: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleReorder(Order order) async {
    final c = AppColors.of(context);
    try {
      final cart = context.read<CartProvider>();
      await cart.reorderItems(order.items);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm ${order.items.length} món vào giỏ hàng thành công!',
          ),
          backgroundColor: c.secondary,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Xem giỏ',
            textColor: Colors.white,
            onPressed: () => context.go('/cart'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi mua lại đơn hàng: $e'),
          backgroundColor: c.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: c.textPrimary,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Chi tiết đơn hàng',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Center(child: CircularProgressIndicator(color: c.secondary)),
      );
    }

    if (_errorMessage != null || _order == null) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: c.textPrimary,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Chi tiết đơn hàng',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, color: c.danger, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Không tìm thấy đơn hàng',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                PrimaryButton(label: 'Tải lại', onPressed: _loadOrder),
              ],
            ),
          ),
        ),
      );
    }

    final order = _order!;
    final canCancel =
        order.status == 'pending_payment' ||
        order.status == 'pending' ||
        order.status == 'processing';

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: c.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Đơn hàng #${order.code}',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: order.statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: order.statusColor.withValues(alpha: 0.4),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              order.statusLabel,
              style: TextStyle(
                color: order.statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OrderTimelineCard(order: order),
              const SizedBox(height: 14),
              OrderRecipientCard(order: order),
              const SizedBox(height: 14),
              OrderItemsCard(order: order),
              const SizedBox(height: 14),
              OrderPaymentSummaryCard(order: order),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(
            top: BorderSide(color: c.border.withValues(alpha: 0.6)),
          ),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (canCancel) ...[
              Expanded(
                child: SecondaryButton(
                  label: 'Huỷ đơn',
                  icon: Icons.cancel_outlined,
                  foreground: c.danger,
                  onPressed: () async {
                    final cancelled = await OrderCancelDialog.show(
                      context,
                      order,
                    );
                    if (cancelled == true) {
                      _loadOrder();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
            ],
            if (order.paymentMethod == 'vnpay' &&
                (order.status == 'pending_payment' ||
                    order.status == 'pending'))
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Thanh toán VNPay',
                  icon: Icons.payment_rounded,
                  onPressed: () => context.push('/payment/vnpay', extra: order),
                ),
              )
            else
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Mua lại đơn hàng',
                  icon: Icons.replay_rounded,
                  onPressed: () => _handleReorder(order),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
