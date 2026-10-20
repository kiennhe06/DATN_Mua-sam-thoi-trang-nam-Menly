import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class VNPayBrowserDialog {
  static void show({
    required BuildContext context,
    required VoidCallback onConfirmed,
  }) {
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
            onPressed: () {
              Navigator.pop(ctx);
              onConfirmed();
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
}
