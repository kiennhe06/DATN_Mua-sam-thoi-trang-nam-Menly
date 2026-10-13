import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';

class AddressFormSheet {
  static void show({
    required BuildContext context,
    Map<String, dynamic>? existing,
    required Future<void> Function({
      required String name,
      required String phone,
      required String address,
    }) onSubmit,
  }) {
    final c = AppColors.of(context);
    final isEdit = existing != null;

    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final addressCtrl = TextEditingController(text: existing?['address'] ?? '');

    Widget buildField(
      TextEditingController ctrl,
      String hint,
      IconData icon, {
      TextInputType type = TextInputType.text,
      int lines = 1,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: c.border),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: type,
          maxLines: lines,
          style: TextStyle(color: c.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
            prefixIcon: Icon(icon, color: c.textMuted, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isEdit ? 'Sửa địa chỉ nhận hàng' : 'Thêm địa chỉ nhận hàng mới',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              buildField(nameCtrl, 'Họ và tên người nhận', Icons.person_rounded),
              const SizedBox(height: AppSpacing.md),
              buildField(
                phoneCtrl,
                'Số điện thoại',
                Icons.phone_rounded,
                type: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              buildField(
                addressCtrl,
                'Địa chỉ chi tiết (Số nhà, đường, phường, quận)',
                Icons.location_on_rounded,
                lines: 2,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: isEdit ? 'Cập nhật địa chỉ' : 'Thêm địa chỉ',
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final phone = phoneCtrl.text.trim();
                  final address = addressCtrl.text.trim();

                  if (name.isEmpty || phone.isEmpty || address.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Vui lòng điền đầy đủ họ tên, SĐT và địa chỉ',
                        ),
                        backgroundColor: c.danger,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  await onSubmit(name: name, phone: phone, address: address);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
