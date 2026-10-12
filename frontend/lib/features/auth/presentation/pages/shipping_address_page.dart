import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../address/data/address_model.dart';
import '../../../address/presentation/providers/address_provider.dart';

class ShippingAddressPage extends StatefulWidget {
  const ShippingAddressPage({super.key});
  @override
  State<ShippingAddressPage> createState() => _ShippingAddressPageState();
}

class _ShippingAddressPageState extends State<ShippingAddressPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().load(force: true);
    });
  }

  Future<void> _openAddressForm({Address? edit}) async {
    final c = AppColors.of(context);
    final isEdit = edit != null;
    final nameCtrl = TextEditingController(text: edit?.recipientName ?? '');
    final phoneCtrl = TextEditingController(text: edit?.phone ?? '');
    final addressCtrl = TextEditingController(text: edit?.detailAddress ?? '');
    final provinceCtrl = TextEditingController(text: edit?.province ?? '');
    bool setAsDefault = edit?.isDefault ?? false;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusXl)),
            ),
            child: SingleChildScrollView(
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
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill))),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(isEdit ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary)),
                  const SizedBox(height: AppSpacing.xl),
                  _buildField(nameCtrl, 'Họ và tên', Icons.person_rounded),
                  const SizedBox(height: AppSpacing.md),
                  _buildField(phoneCtrl, 'Số điện thoại', Icons.phone_rounded,
                      type: TextInputType.phone),
                  const SizedBox(height: AppSpacing.md),
                  _buildField(addressCtrl, 'Địa chỉ chi tiết', Icons.location_on_rounded,
                      lines: 2),
                  const SizedBox(height: AppSpacing.md),
                  _buildField(provinceCtrl, 'Tỉnh/Thành phố (tùy chọn)',
                      Icons.map_rounded),
                  const SizedBox(height: AppSpacing.md),
                  InkWell(
                    onTap: () =>
                        setModalState(() => setAsDefault = !setAsDefault),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: Row(
                      children: [
                        Checkbox(
                          value: setAsDefault,
                          activeColor: c.primary,
                          onChanged: (v) =>
                              setModalState(() => setAsDefault = v ?? false),
                        ),
                        Expanded(
                          child: Text('Đặt làm địa chỉ mặc định',
                              style: TextStyle(
                                  color: c.textSecondary, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: isEdit ? 'Cập nhật' : 'Thêm địa chỉ',
                    loading: submitting,
                    onPressed: submitting
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final phone = phoneCtrl.text.trim();
                            final address = addressCtrl.text.trim();
                            if (name.isEmpty ||
                                phone.isEmpty ||
                                address.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: const Text(
                                        'Vui lòng điền đầy đủ thông tin'),
                                    backgroundColor: c.danger),
                              );
                              return;
                            }
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(ctx);
                            setModalState(() => submitting = true);
                            try {
                              final provider = context.read<AddressProvider>();
                              if (isEdit) {
                                await provider.updateAddress(
                                  edit.id,
                                  recipientName: name,
                                  phone: phone,
                                  detailAddress: address,
                                  province: provinceCtrl.text.trim(),
                                  isDefault: setAsDefault,
                                );
                              } else {
                                await provider.add(
                                  recipientName: name,
                                  phone: phone,
                                  detailAddress: address,
                                  province: provinceCtrl.text.trim(),
                                  isDefault: setAsDefault,
                                );
                              }
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                    content: Text(isEdit
                                        ? 'Cập nhật địa chỉ thành công'
                                        : 'Thêm địa chỉ thành công'),
                                    backgroundColor: Colors.green.shade700),
                              );
                            } catch (e) {
                              setModalState(() => submitting = false);
                              messenger.showSnackBar(
                                SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: c.danger),
                              );
                            }
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    provinceCtrl.dispose();
  }

  Future<void> _deleteAddress(Address address) async {
    final c = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text('Xoá địa chỉ',
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn xoá địa chỉ này?',
            style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Huỷ', style: TextStyle(color: c.textMuted))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Xoá',
                style: TextStyle(color: c.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AddressProvider>().remove(address.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã xoá địa chỉ')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: c.danger),
      );
    }
  }

  Future<void> _setDefault(Address address) async {
    final c = AppColors.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AddressProvider>().setDefault(address.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã đặt làm địa chỉ mặc định')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: c.danger),
      );
    }
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text, int lines = 1}) {
    final c = AppColors.of(context);
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

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final provider = context.watch<AddressProvider>();
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Địa chỉ giao hàng'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: c.secondary),
            onPressed: () => _openAddressForm(),
          ),
        ],
      ),
      body: provider.loading && provider.addresses.isEmpty
          ? const LoadingView()
          : provider.addresses.isEmpty
              ? StatusView(
                  icon: Icons.location_off_rounded,
                  title: 'Chưa có địa chỉ nào',
                  message: 'Thêm địa chỉ giao hàng để mua sắm nhanh hơn',
                  actionLabel: 'Thêm địa chỉ',
                  onAction: () => _openAddressForm(),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.load(force: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: provider.addresses.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => _addressCard(provider.addresses[i]),
                  ),
                ),
    );
  }

  Widget _addressCard(Address address) {
    final c = AppColors.of(context);
    final isDefault = address.isDefault;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
            color: isDefault
                ? c.secondary.withValues(alpha: 0.5)
                : c.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
              color: c.shadow, blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: isDefault ? c.secondary : c.textMuted, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(address.recipientName,
                    style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text('Mặc định',
                      style: TextStyle(
                          color: c.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(address.phone,
              style: TextStyle(color: c.textSecondary, fontSize: 13)),
          const SizedBox(height: AppSpacing.xs),
          Text(address.fullAddress,
              style: TextStyle(color: c.textMuted, fontSize: 12)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (!isDefault)
                Pressable(
                  onTap: () => _setDefault(address),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border.all(color: c.secondary),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text('Đặt mặc định',
                        style: TextStyle(
                            color: c.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              const Spacer(),
              CircleIconButton(
                icon: Icons.edit_rounded,
                onTap: () => _openAddressForm(edit: address),
                size: 38,
                bordered: false,
                background: c.surfaceVariant,
                foreground: c.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleIconButton(
                icon: Icons.delete_outline_rounded,
                onTap: () => _deleteAddress(address),
                size: 38,
                bordered: false,
                background: c.danger.withValues(alpha: 0.12),
                foreground: c.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
