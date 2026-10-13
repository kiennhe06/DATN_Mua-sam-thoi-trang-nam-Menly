import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../data/order_model.dart';
import '../providers/order_provider.dart';

class OrderCancelDialog extends StatefulWidget {
  final Order order;

  const OrderCancelDialog({super.key, required this.order});

  static Future<bool?> show(BuildContext context, Order order) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => OrderCancelDialog(order: order),
    );
  }

  @override
  State<OrderCancelDialog> createState() => _OrderCancelDialogState();
}

class _OrderCancelDialogState extends State<OrderCancelDialog> {
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: c.danger, size: 26),
          const SizedBox(width: 10),
          Text(
            'Huỷ đơn hàng',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn có chắc chắn muốn huỷ đơn hàng #${widget.order.code}?',
            style: TextStyle(color: c.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Nhập lý do huỷ (tùy chọn)...',
              hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
              filled: true,
              fillColor: c.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(color: c.textPrimary, fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: Text('Đóng', style: TextStyle(color: c.textMuted)),
        ),
        PrimaryButton(
          label: _isSubmitting ? 'Đang huỷ...' : 'Xác nhận huỷ',
          expanded: false,
          height: 44,
          background: c.danger,
          foreground: c.onPrimary,
          loading: _isSubmitting,
          onPressed: _isSubmitting
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  final reason = _noteCtrl.text.trim().isNotEmpty
                      ? _noteCtrl.text.trim()
                      : 'Khách hàng huỷ đơn';

                  final success = await context.read<OrderProvider>().cancelOrder(
                        widget.order.id,
                        reason: reason,
                      );

                  if (context.mounted) {
                    Navigator.of(context).pop(success);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Đã huỷ đơn hàng thành công'),
                          backgroundColor: c.success,
                          duration: const Duration(milliseconds: 1500),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Không thể huỷ đơn hàng. Vui lòng thử lại sau'),
                          backgroundColor: c.danger,
                          duration: const Duration(milliseconds: 1500),
                        ),
                      );
                    }
                  }
                },
        ),
      ],
    );
  }
}
