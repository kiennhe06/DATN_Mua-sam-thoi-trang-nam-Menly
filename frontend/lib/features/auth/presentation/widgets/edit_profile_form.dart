import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class EditProfileForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController addressCtrl;
  final AuthUser user;

  const EditProfileForm({
    super.key,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section: Thông tin cá nhân
        Text(
          'THÔNG TIN CƠ BẢN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: c.textMuted,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),

        // Họ và tên
        _buildField(
          c: c,
          controller: nameCtrl,
          label: 'Họ và tên',
          hintText: 'Nhập họ và tên đầy đủ',
          icon: Icons.person_outline_rounded,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Vui lòng nhập họ và tên';
            }
            if (v.trim().length < 2) {
              return 'Họ và tên tối thiểu 2 ký tự';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Số điện thoại
        _buildField(
          c: c,
          controller: phoneCtrl,
          label: 'Số điện thoại liên hệ',
          hintText: 'VD: 0912345678',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v != null && v.trim().isNotEmpty) {
              final cleaned = v.trim();
              if (!RegExp(r'^(0|\+84)[3|5|7|8|9][0-9]{8}$').hasMatch(cleaned)) {
                return 'Số điện thoại không hợp lệ (10 chữ số)';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Địa chỉ mặc định
        _buildField(
          c: c,
          controller: addressCtrl,
          label: 'Địa chỉ mặc định',
          hintText: 'Số nhà, tên đường, phường/xã, quận/huyện, tỉnh/TP',
          icon: Icons.location_on_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 24),

        // Section: Thông tin tài khoản (Chỉ đọc)
        Text(
          'TÀI KHOẢN ĐĂNG NHẬP',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: c.textMuted,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),

        // Email (Read-only)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              Icon(Icons.email_outlined, color: c.textMuted, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email tài khoản',
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.lock_outline_rounded, color: c.textMuted, size: 18),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 6, top: 6, bottom: 20),
          child: Text(
            'Email dùng để xác thực và đăng nhập nên không thể sửa đổi trực tiếp.',
            style: TextStyle(color: c.textMuted, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required AppColors c,
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: c.textPrimary, fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
            prefixIcon: Icon(icon, color: c.secondary, size: 20),
            filled: true,
            fillColor: c.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
