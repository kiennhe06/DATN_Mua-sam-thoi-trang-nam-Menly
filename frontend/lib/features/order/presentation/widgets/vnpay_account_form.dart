import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format.dart';
import '../../data/order_model.dart';
import '../../data/vnpay_bank_model.dart';

class VNPayAccountForm extends StatelessWidget {
  final Order order;
  final VNPayBank bank;
  final TextEditingController cardNumCtrl;
  final TextEditingController cardHolderCtrl;
  final TextEditingController dateCtrl;
  final TextEditingController otpCtrl;
  final VoidCallback onAutoFill;
  final VoidCallback onChangeBank;

  const VNPayAccountForm({
    super.key,
    required this.order,
    required this.bank,
    required this.cardNumCtrl,
    required this.cardHolderCtrl,
    required this.dateCtrl,
    required this.otpCtrl,
    required this.onAutoFill,
    required this.onChangeBank,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isQr = bank.code == 'VNPAYQR';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card hiển thị ngân hàng đã chọn kèm nút đổi
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bank.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(bank.icon, color: bank.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bank.name,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF005BAA).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Đã chọn',
                            style: TextStyle(
                              color: Color(0xFF005BAA),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bank.fullName,
                      style: TextStyle(color: c.textMuted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onChangeBank,
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: const Text('Đổi', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: BorderSide(color: c.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (isQr)
          _buildQrSection(c)
        else
          _buildCardSection(c),
      ],
    );
  }

  /// Giao diện thanh toán qua quét mã VNPAY-QR
  Widget _buildQrSection(AppColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 190, color: Color(0xFF0B2545)),
                const SizedBox(height: 6),
                Text(
                  'MÃ THANH TOÁN VNPAY-QR',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Đơn hàng: ${order.code}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Số tiền thanh toán:', style: TextStyle(color: c.textSecondary, fontSize: 12)),
                Text(
                  formatPrice(order.total),
                  style: const TextStyle(
                    color: Color(0xFFED1C24),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Mở ứng dụng Mobile Banking của ngân hàng bất kỳ để quét mã QR.',
            style: TextStyle(color: c.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Giao diện nhập thông tin thẻ ATM / Tài khoản ngân hàng
  Widget _buildCardSection(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mô phỏng thẻ ATM
        Container(
          width: double.infinity,
          height: 175,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                bank.primaryColor,
                bank.primaryColor.withValues(alpha: 0.8),
                const Color(0xFF141E30),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: bank.primaryColor.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(bank.icon, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        bank.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.contactless_rounded, color: Colors.white70, size: 24),
                ],
              ),
              Row(
                children: [
                  // EMV chip
                  Container(
                    width: 34,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFDF7A), Color(0xFFE5B338)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber.shade700, width: 0.8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cardNumCtrl.text.isEmpty
                          ? '•••• •••• •••• ••••'
                          : cardNumCtrl.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CHỦ THẺ / TÀI KHOẢN',
                          style: TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cardHolderCtrl.text.isEmpty
                              ? 'NGUYEN VAN A'
                              : cardHolderCtrl.text.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'NGÀY PH',
                        style: TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateCtrl.text.isEmpty ? '07/15' : dateCtrl.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tiêu đề & Nút điền mẫu Sandbox
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Thông tin tài khoản / Thẻ',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: onAutoFill,
              icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF005BAA)),
              label: const Text(
                '⚡ Điền thẻ Sandbox NCB',
                style: TextStyle(
                  color: Color(0xFF005BAA),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Form Fields
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Số thẻ / Số tài khoản
              Text('Số thẻ / Số tài khoản', style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: cardNumCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: c.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.credit_card_rounded, size: 18),
                  isDense: true,
                  hintText: '9704 xxxx xxxx xxxx',
                  hintStyle: TextStyle(color: c.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: c.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // Tên chủ thẻ
              Text('Tên chủ thẻ (In hoa không dấu)', style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: cardHolderCtrl,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(color: c.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                  isDense: true,
                  hintText: 'NGUYEN VAN A',
                  hintStyle: TextStyle(color: c.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: c.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // Row Ngày phát hành & Mã OTP
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ngày phát hành', style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: dateCtrl,
                          style: TextStyle(color: c.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                            isDense: true,
                            hintText: '07/15',
                            hintStyle: TextStyle(color: c.textMuted, fontSize: 12),
                            filled: true,
                            fillColor: c.surfaceVariant,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Mã OTP', style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                            InkWell(
                              onTap: () => otpCtrl.text = '123456',
                              child: const Text('Điền: 123456', style: TextStyle(color: Color(0xFF005BAA), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: otpCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 16),
                            isDense: true,
                            hintText: '123456',
                            hintStyle: TextStyle(color: c.textMuted, fontSize: 12),
                            filled: true,
                            fillColor: c.surfaceVariant,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Badge bảo mật
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 14, color: c.textMuted),
            const SizedBox(width: 6),
            Text(
              'Giao dịch được mô phỏng & bảo mật theo tiêu chuẩn VNPay Sandbox',
              style: TextStyle(color: c.textMuted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
