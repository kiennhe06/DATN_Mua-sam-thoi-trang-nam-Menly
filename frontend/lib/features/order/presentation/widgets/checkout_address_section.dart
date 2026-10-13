import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../controllers/checkout_controller.dart';
import 'checkout_section_card.dart';

class CheckoutAddressSection extends StatelessWidget {
  final CheckoutController controller;

  const CheckoutAddressSection({
    super.key,
    required this.controller,
  });

  Widget _buildField(
    BuildContext context,
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int lines = 1,
  }) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: lines,
        style: TextStyle(color: c.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: c.textMuted),
          isDense: true,
        ),
      ),
    );
  }

  void _showAddressPicker(BuildContext context) {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chọn địa chỉ nhận hàng',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await context.push('/shipping-address');
                      await controller.loadSavedAddresses();
                    },
                    icon: Icon(Icons.settings_outlined, size: 16, color: c.secondary),
                    label: Text('Quản lý', style: TextStyle(color: c.secondary, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.savedAddresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final addr = controller.savedAddresses[i];
                    final isSelected = !controller.useManualAddress &&
                        controller.selectedAddressIndex == i;
                    final isDefault = i == controller.defaultAddressIndex;
                    return InkWell(
                      onTap: () {
                        controller.selectAddress(i);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? c.primarySoft : c.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? c.secondary : c.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? c.secondary : c.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        addr['name'] ?? '',
                                        style: TextStyle(
                                          color: c.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${addr['phone'] ?? ''})',
                                        style: TextStyle(
                                          color: c.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: c.primarySoft,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Mặc định',
                                            style: TextStyle(
                                              color: c.secondary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    addr['address'] ?? '',
                                    style: TextStyle(color: c.textMuted, fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  controller.setUseManualAddress(
                    true,
                    defaultName: auth.user?.fullName,
                  );
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                label: const Text('Nhập địa chỉ nhận hàng khác'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.textPrimary,
                  side: BorderSide(color: c.border),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isSavedView =
        controller.savedAddresses.isNotEmpty && !controller.useManualAddress;

    if (isSavedView) {
      final isDefaultSelected =
          controller.selectedAddressIndex == controller.defaultAddressIndex;

      return CheckoutSectionCard(
        title: 'Địa chỉ giao hàng',
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDefaultSelected
                    ? c.secondary.withValues(alpha: 0.6)
                    : c.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: isDefaultSelected ? c.secondary : c.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            controller.nameCtrl.text,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${controller.phoneCtrl.text})',
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          if (isDefaultSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: c.primarySoft,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Mặc định',
                                style: TextStyle(
                                  color: c.secondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showAddressPicker(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              'Đổi',
                              style: TextStyle(
                                color: c.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 16, color: c.secondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  controller.addressCtrl.text,
                  style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.3),
                ),
                if (!isDefaultSelected) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => controller.selectAddress(controller.defaultAddressIndex),
                    child: Text(
                      '← Chọn lại địa chỉ mặc định',
                      style: TextStyle(color: c.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildField(context, controller.noteCtrl, 'Ghi chú cho shipper (tùy chọn)', Icons.note_rounded),
        ],
      );
    }

    // Giao diện nhập địa chỉ thủ công
    return CheckoutSectionCard(
      title: 'Thông tin giao hàng',
      children: [
        if (controller.savedAddresses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nhập địa chỉ mới',
                  style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () => controller.selectAddress(controller.defaultAddressIndex),
                  child: Text(
                    'Dùng địa chỉ mặc định',
                    style: TextStyle(color: c.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        _buildField(context, controller.nameCtrl, 'Họ và tên', Icons.person_rounded),
        _buildField(context, controller.phoneCtrl, 'Số điện thoại', Icons.phone_rounded, type: TextInputType.phone),
        _buildField(context, controller.addressCtrl, 'Địa chỉ giao hàng', Icons.location_on_rounded, lines: 2),
        _buildField(context, controller.noteCtrl, 'Ghi chú (tùy chọn)', Icons.note_rounded),
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: controller.saveAsDefault,
                onChanged: (v) => controller.setSaveAsDefault(v ?? false),
                activeColor: c.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đặt địa chỉ này làm mặc định cho lần mua sau',
                style: TextStyle(color: c.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
