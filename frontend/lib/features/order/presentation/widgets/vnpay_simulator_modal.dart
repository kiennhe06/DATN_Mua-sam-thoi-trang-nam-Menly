import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../data/order_model.dart';
import '../../data/vnpay_bank_model.dart';

/// Màn hình BottomSheet mô phỏng giao dịch VNPay Sandbox
class VNPaySimulatorModal extends StatefulWidget {
  final Order order;
  final VNPayBank bank;
  final VoidCallback onConfirmSuccess;
  final VoidCallback onCancelOrFailed;

  const VNPaySimulatorModal({
    super.key,
    required this.order,
    required this.bank,
    required this.onConfirmSuccess,
    required this.onCancelOrFailed,
  });

  @override
  State<VNPaySimulatorModal> createState() => _VNPaySimulatorModalState();
}

class _VNPaySimulatorModalState extends State<VNPaySimulatorModal> {
  int _step = 1; // 1: Nhập thẻ / Quét QR -> 2: Nhập OTP
  final TextEditingController _cardNumCtrl = TextEditingController(text: '9704 1985 2619 1432 198');
  final TextEditingController _cardHolderCtrl = TextEditingController(text: 'NGUYEN VAN A');
  final TextEditingController _dateCtrl = TextEditingController(text: '07/15');
  final TextEditingController _otpCtrl = TextEditingController(text: '123456');

  bool _isProcessing = false;
  int _otpCountdown = 60;
  Timer? _otpTimer;

  void _startOtpTimer() {
    _otpCountdown = 60;
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_otpCountdown > 0) {
        setState(() => _otpCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    _cardNumCtrl.dispose();
    _cardHolderCtrl.dispose();
    _dateCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _autoFillDemoCard() {
    setState(() {
      _cardNumCtrl.text = '9704 1985 2619 1432 198';
      _cardHolderCtrl.text = 'NGUYEN VAN A';
      _dateCtrl.text = '07/15';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã điền tự động thông tin thẻ thử nghiệm NCB Sandbox'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _proceedToOtp() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _step = 2;
    });
    _startOtpTimer();
  }

  Future<void> _submitOtp() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isProcessing = false);
    widget.onConfirmSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isQr = widget.bank.code == 'VNPAYQR';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh gạt
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),

            // Header Modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF005BAA).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: Color(0xFF005BAA), size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mô phỏng VNPay Sandbox',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: c.textMuted, size: 20),
                  ),
                ],
              ),
            ),
            Divider(color: c.border),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge tổng số tiền
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ngân hàng: ${widget.bank.name}', style: TextStyle(color: c.textSecondary, fontSize: 12)),
                              Text('Đơn hàng: ${widget.order.code}', style: TextStyle(color: c.textMuted, fontSize: 11)),
                            ],
                          ),
                          Text(
                            formatPrice(widget.order.total),
                            style: const TextStyle(
                              color: Color(0xFFED1C24),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (isQr)
                      _buildQrSimulator(c)
                    else if (_step == 1)
                      _buildCardForm(c)
                    else
                      _buildOtpForm(c),
                  ],
                ),
              ),
            ),

            // Nút hủy hoặc mô phỏng lỗi
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: TextButton.icon(
                onPressed: widget.onCancelOrFailed,
                icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                label: const Text(
                  'Mô phỏng hủy giao dịch / thanh toán thất bại',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Giao diện quét mã QR
  Widget _buildQrSimulator(AppColors c) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.qr_code_2_rounded, size: 180, color: Color(0xFF0B2545)),
              const SizedBox(height: 8),
              Text(
                'Mã VNPAY-QR Demo',
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                'Quét bằng ứng dụng Mobile Banking bất kỳ',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: '⚡ Xác nhận quét mã thành công (Demo)',
          icon: Icons.check_circle_outline,
          loading: _isProcessing,
          onPressed: _isProcessing ? null : widget.onConfirmSuccess,
        ),
      ],
    );
  }

  /// Form nhập thẻ ATM
  Widget _buildCardForm(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
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
                  Text(
                    widget.bank.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Icon(Icons.contactless_rounded, color: Colors.white70, size: 24),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _cardNumCtrl.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CHỦ THẺ', style: TextStyle(color: Colors.white60, fontSize: 9)),
                      Text(
                        _cardHolderCtrl.text,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HIỆU LỰC', style: TextStyle(color: Colors.white60, fontSize: 9)),
                      Text(
                        _dateCtrl.text,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _autoFillDemoCard,
            icon: const Icon(Icons.bolt_rounded, color: Color(0xFF005BAA), size: 18),
            label: const Text(
              'Điền nhanh thẻ Sandbox NCB',
              style: TextStyle(color: Color(0xFF005BAA), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 4),

        Text('Số thẻ ngân hàng', style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _cardNumCtrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: c.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.credit_card, size: 18),
            isDense: true,
            hintText: '9704 xxxx xxxx xxxx',
            filled: true,
            fillColor: c.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tên chủ thẻ', style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _cardHolderCtrl,
                    style: TextStyle(color: c.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person, size: 18),
                      isDense: true,
                      hintText: 'NGUYEN VAN A',
                      filled: true,
                      fillColor: c.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ngày phát hành', style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _dateCtrl,
                    style: TextStyle(color: c.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.calendar_today, size: 16),
                      isDense: true,
                      hintText: 'MM/YY',
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
        const SizedBox(height: 20),

        PrimaryButton(
          label: 'Tiếp tục xác nhận OTP',
          loading: _isProcessing,
          onPressed: _proceedToOtp,
        ),
        const SizedBox(height: 8),

        OutlinedButton(
          onPressed: widget.onConfirmSuccess,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('⚡ Thanh toán thành công ngay (1 chạm)'),
        ),
      ],
    );
  }

  /// Form xác nhận mã OTP
  Widget _buildOtpForm(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phonelink_ring_rounded, color: Colors.green, size: 36),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Xác thực giao dịch OTP',
            style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Mã OTP thử nghiệm đã được tạo: 123456',
            style: TextStyle(color: c.textSecondary, fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),

        Text('Nhập mã xác thực OTP', style: TextStyle(color: c.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 20,
            letterSpacing: 6,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: c.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Thời gian còn lại: ${_otpCountdown}s', style: TextStyle(color: c.textMuted, fontSize: 12)),
            TextButton(
              onPressed: () => setState(() => _otpCtrl.text = '123456'),
              child: const Text('Điền mã: 123456', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        PrimaryButton(
          label: 'Xác nhận OTP & Hoàn tất thanh toán',
          loading: _isProcessing,
          onPressed: _submitOtp,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text('Quay lại bước nhập thẻ'),
          ),
        ),
      ],
    );
  }
}
