import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../cart/data/cart_model.dart';
import '../../data/order_model.dart';
import '../providers/order_provider.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  bool _loading = true;
  String? _error;
  bool _reordering = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<OrderProvider>();
    _order = provider.findCachedById(widget.orderId);
    _loading = _order == null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      if (_order == null) _loading = true;
      _error = null;
    });
    final order = await context.read<OrderProvider>().fetchOrderDetail(widget.orderId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (order != null) {
        _order = order;
      } else if (_order == null) {
        _error = 'Không tìm thấy đơn hàng';
      }
    });
  }

  static String _money(int v) {
    final s = v.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return '${b.toString()}đ';
  }

  bool get _canCancel {
    final s = _order?.status;
    return s == 'pending_payment' ||
        s == 'pending' ||
        s == 'pending_confirmation' ||
        s == 'paid' ||
        s == 'processing';
  }

  Future<void> _reorder() async {
    final order = _order;
    if (order == null || order.items.isEmpty) return;
    setState(() => _reordering = true);

    final cart = context.read<CartProvider>();
    int added = 0;
    for (final item in order.items) {
      if (item.variantId.isEmpty) continue;
      final ok = await cart.addVariantById(item.variantId, item.quantity);
      if (ok) added++;
    }
    if (!mounted) return;
    setState(() => _reordering = false);

    if (added > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm $added sản phẩm vào giỏ hàng'),
          backgroundColor: AppColors.of(context).success,
        ),
      );
      context.push('/cart');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không thể thêm sản phẩm vào giỏ. Vui lòng thử lại'),
          backgroundColor: AppColors.of(context).danger,
        ),
      );
    }
  }

  Future<void> _cancelOrder() async {
    final order = _order;
    if (order == null) return;
    final c = AppColors.of(context);
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        title: Text('Huỷ đơn hàng',
            style: TextStyle(
                color: c.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn huỷ đơn #${order.code}?',
                style: TextStyle(color: c.textSecondary, fontSize: 14)),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Lý do huỷ (tùy chọn)...',
                hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                filled: true,
                fillColor: c.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Đóng', style: TextStyle(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Xác nhận huỷ', style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _cancelling = true);
    final reason = noteCtrl.text.trim().isNotEmpty
        ? noteCtrl.text.trim()
        : 'Khách hàng huỷ đơn';
    final ok = await context.read<OrderProvider>().cancelOrder(order.id, reason: reason);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (ok) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã huỷ đơn hàng'),
            backgroundColor: AppColors.of(context).success,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không thể huỷ đơn hàng'),
          backgroundColor: AppColors.of(context).danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: c.textPrimary, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/orders');
            }
          },
        ),
        title: Text('Chi tiết đơn hàng',
            style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _order == null
                ? _buildError(c)
                : RefreshIndicator(
                    onRefresh: _load,
                    color: c.secondary,
                    backgroundColor: c.surfaceVariant,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _buildStatusCard(c, _order!),
                        const SizedBox(height: AppSpacing.lg),
                        _buildTimelineCard(c, _order!),
                        const SizedBox(height: AppSpacing.lg),
                        _buildItemsCard(c, _order!),
                        const SizedBox(height: AppSpacing.lg),
                        _buildShippingCard(c, _order!),
                        const SizedBox(height: AppSpacing.lg),
                        _buildPaymentCard(c, _order!),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: _order == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: Row(
                  children: [
                    if (_canCancel)
                      Expanded(
                        child: SecondaryButton(
                          label: 'Huỷ đơn',
                          icon: Icons.cancel_outlined,
                          foreground: c.danger,
                          onPressed: _cancelling ? null : _cancelOrder,
                        ),
                      ),
                    if (_canCancel) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        label: 'Mua lại',
                        icon: Icons.refresh_rounded,
                        loading: _reordering,
                        onPressed: _order!.items.isEmpty ? null : _reorder,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _card({required Color color, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }

  Widget _sectionTitle(AppColors c, String text, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: c.secondary),
          const SizedBox(width: 8),
        ],
        Text(text,
            style: TextStyle(
                color: c.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildStatusCard(AppColors c, Order order) {
    return _card(
      color: c.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mã đơn hàng',
                        style: TextStyle(color: c.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(order.code,
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: order.statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                      color: order.statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(order.statusLabel,
                    style: TextStyle(
                        color: order.statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 15, color: c.textMuted),
              const SizedBox(width: 6),
              Text('Đặt lúc: ${order.formattedDate}',
                  style: TextStyle(color: c.textSecondary, fontSize: 13)),
            ],
          ),
          if (order.status == 'cancelled' &&
              order.note != null &&
              order.note!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: c.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: c.danger.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: c.danger, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Lý do huỷ: ${order.note}',
                        style: TextStyle(color: c.danger, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static int _stageOf(String status) {
    switch (status) {
      case 'pending_payment':
      case 'pending':
      case 'pending_confirmation':
        return 0;
      case 'paid':
      case 'processing':
        return 1;
      case 'shipping':
        return 2;
      case 'completed':
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildTimelineCard(AppColors c, Order order) {
    final isCancelled = order.status == 'cancelled';

    // Yêu cầu: Đã đặt → Xác nhận → Đang giao → Hoàn tất
    final labels = ['Đã đặt', 'Xác nhận', 'Đang giao', 'Hoàn tất'];
    final icons = [
      Icons.receipt_long_rounded,
      Icons.verified_rounded,
      Icons.local_shipping_rounded,
      Icons.check_circle_rounded,
    ];
    final times = <String?>[
      order.createdAt,
      order.historyTimestampFor('processing') ??
          order.historyTimestampFor('paid') ??
          order.historyTimestampFor('pending_confirmation'),
      order.historyTimestampFor('shipping'),
      order.historyTimestampFor('completed'),
    ];

    // Mốc hiện tại: suy ra từ trạng thái, nếu đã huỷ thì lấy mốc xa nhất đạt được
    int stage = _stageOf(order.status);
    if (isCancelled) {
      var reached = 0;
      for (final h in order.statusHistory) {
        final s = _stageOf(h.status);
        if (s > reached) reached = s;
      }
      stage = reached;
    }

    final rows = <Widget>[];
    for (int i = 0; i < labels.length; i++) {
      final done = i <= stage;
      final current = !isCancelled && i == stage && stage < labels.length - 1;
      final isLast = i == labels.length - 1 && !isCancelled;
      rows.add(_timelineRow(
        c,
        label: labels[i],
        icon: icons[i],
        done: done,
        current: current,
        time: done ? times[i] : null,
        showConnector: !isLast,
      ));
    }

    if (isCancelled) {
      rows.add(_timelineRow(
        c,
        label: 'Đã huỷ',
        icon: Icons.cancel_rounded,
        done: true,
        danger: true,
        time: order.historyTimestampFor('cancelled'),
        showConnector: false,
      ));
    }

    return _card(
      color: c.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(c, 'Tiến trình đơn hàng', icon: Icons.timeline_rounded),
          const SizedBox(height: AppSpacing.lg),
          ...rows,
        ],
      ),
    );
  }

  Widget _timelineRow(
    AppColors c, {
    required String label,
    required IconData icon,
    required bool done,
    bool current = false,
    String? time,
    bool danger = false,
    bool showConnector = true,
  }) {
    final activeColor = danger ? c.danger : c.secondary;
    final dotColor = done ? activeColor : c.border;
    final textColor = done ? c.textPrimary : c.textMuted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: current
                      ? activeColor
                      : (done
                          ? activeColor.withValues(alpha: 0.15)
                          : c.surfaceVariant),
                  shape: BoxShape.circle,
                  border: Border.all(color: dotColor, width: 1.6),
                ),
                child: Icon(icon,
                    size: 15,
                    color: current
                        ? Colors.white
                        : (done ? activeColor : c.textMuted)),
              ),
              if (showConnector)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: done ? activeColor.withValues(alpha: 0.4) : c.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 4, bottom: showConnector ? AppSpacing.lg : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: current ? activeColor : textColor,
                          fontSize: 14,
                          fontWeight: done ? FontWeight.w700 : FontWeight.w500)),
                  if (done && time != null && time.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(Order.formatTime(time),
                        style: TextStyle(color: c.textMuted, fontSize: 12)),
                  ] else if (current) ...[
                    const SizedBox(height: 2),
                    Text('Đang xử lý...',
                        style: TextStyle(color: c.textMuted, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(AppColors c, Order order) {
    return _card(
      color: c.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(c, 'Sản phẩm (${order.items.length})',
              icon: Icons.shopping_bag_outlined),
          const SizedBox(height: AppSpacing.md),
          if (order.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Không có sản phẩm',
                  style: TextStyle(color: c.textMuted, fontSize: 13)),
            )
          else
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: c.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Icon(Icons.checkroom_rounded,
                            color: c.textMuted, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                style: TextStyle(
                                    color: c.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            if (item.size.isNotEmpty || item.color.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Phân loại: ${[item.size, item.color].where((s) => s.isNotEmpty).join(' / ')}',
                                  style: TextStyle(
                                      color: c.textMuted, fontSize: 12),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${_money(item.unitPrice)} × ${item.quantity}',
                                style: TextStyle(
                                    color: c.textSecondary, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _money(item.unitPrice * item.quantity),
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildShippingCard(AppColors c, Order order) {
    return _card(
      color: c.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(c, 'Địa chỉ nhận hàng',
              icon: Icons.location_on_outlined),
          const SizedBox(height: AppSpacing.md),
          _kv(c, 'Người nhận', order.shipName),
          _kv(c, 'Số điện thoại', order.shipPhone),
          _kv(c, 'Địa chỉ', order.shipAddress),
          if (order.note != null &&
              order.note!.isNotEmpty &&
              order.status != 'cancelled')
            _kv(c, 'Ghi chú', order.note!),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(AppColors c, Order order) {
    return _card(
      color: c.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(c, 'Thanh toán', icon: Icons.receipt_outlined),
          const SizedBox(height: AppSpacing.md),
          _priceRow(c, 'Tạm tính', _money(order.subtotal)),
          _priceRow(c, 'Phí vận chuyển',
              order.shippingFee > 0 ? _money(order.shippingFee) : 'Miễn phí'),
          if (order.discountAmount > 0)
            _priceRow(
              c,
              'Giảm giá${order.voucherCode != null && order.voucherCode!.isNotEmpty ? ' (${order.voucherCode})' : ''}',
              '-${_money(order.discountAmount)}',
              valueColor: c.success,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: c.surfaceVariant, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng thanh toán',
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              Text(_money(order.total),
                  style: TextStyle(
                      color: c.secondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                order.paymentMethod == 'vnpay'
                    ? Icons.credit_card_rounded
                    : Icons.payments_outlined,
                size: 16,
                color: c.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Phương thức: ${order.paymentMethod == 'vnpay' ? 'VNPay' : 'Thanh toán khi nhận hàng (COD)'}',
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(AppColors c, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(color: c.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(AppColors c, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: c.textSecondary, fontSize: 13.5)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? c.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildError(AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: c.danger, size: 48),
            const SizedBox(height: 12),
            Text(_error ?? 'Đã có lỗi xảy ra',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            SecondaryButton(
              label: 'Thử lại',
              expanded: false,
              onPressed: _load,
            ),
          ],
        ),
      ),
    );
  }
}
