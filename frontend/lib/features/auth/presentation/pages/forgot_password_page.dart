import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMsg = 'Vui lòng nhập địa chỉ email';
        _successMsg = null;
      });
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorMsg = 'Địa chỉ email không đúng định dạng';
        _successMsg = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
      _successMsg = null;
    });

    try {
      final res = await DioClient.instance.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      if (mounted) {
        setState(() {
          _loading = false;
          _successMsg = res.data?['message'] ??
              'Đã gửi liên kết khôi phục mật khẩu đến email của bạn. Vui lòng kiểm tra hộp thư!';
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data?['error']?['message'] ??
            e.response?.data?['message'] ??
            'Không thể gửi yêu cầu đặt lại mật khẩu. Vui lòng thử lại sau.';
        setState(() {
          _loading = false;
          _errorMsg = msg;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = 'Đã có lỗi xảy ra. Vui lòng thử lại!';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nút quay lại
              CircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                background: c.surfaceVariant,
                foreground: c.textPrimary,
                onTap: () => context.pop(),
              ),
              const SizedBox(height: 32),

              // Biểu tượng ổ khóa
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      c.primary,
                      c.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: c.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_reset_rounded,
                  color: c.onPrimary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 24),

              // Tiêu đề
              Text(
                'Quên mật khẩu?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đừng lo lắng! Nhập email tài khoản của bạn để nhận liên kết đặt lại mật khẩu.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: c.textMuted,
                ),
              ),
              const SizedBox(height: 32),

              // Thông báo thành công
              if (_successMsg != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: c.success.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: c.success, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMsg!,
                          style: TextStyle(
                            color: c.success,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Thông báo lỗi
              if (_errorMsg != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: c.danger.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: c.danger, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: TextStyle(
                            color: c.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Ô nhập email
              Text(
                'Địa chỉ Email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
                  prefixIcon: Icon(Icons.email_outlined, color: c.textMuted, size: 20),
                  filled: true,
                  fillColor: c.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(color: c.primary, width: 1.8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 28),

              // Nút Gửi liên kết
              PrimaryButton(
                label: 'Gửi liên kết khôi phục',
                icon: Icons.send_rounded,
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),

              // Quay lại đăng nhập
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: RichText(
                    text: TextSpan(
                      text: 'Nhớ lại mật khẩu? ',
                      style: TextStyle(color: c.textMuted, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Đăng nhập ngay',
                          style: TextStyle(
                            color: c.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
