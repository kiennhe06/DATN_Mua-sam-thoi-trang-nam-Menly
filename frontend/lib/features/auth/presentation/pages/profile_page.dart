import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../cart/data/cart_model.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../../../address/presentation/providers/address_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_avatar_view.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showLogoutDialog = false;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchProfile();
    });
  }

  void _confirmLogout() => setState(() => _showLogoutDialog = true);

  Future<void> _doLogout() async {
    setState(() => _showLogoutDialog = false);
    await context.read<AuthProvider>().logout();
    if (mounted) {
      context.read<CartProvider>().resetLocal();
      context.read<AddressProvider>().reset();
      context.go('/login');
    }
  }

  Future<void> _showAvatarSourceSheet() async {
    final c = AppColors.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: c.secondary),
              title: Text('Chụp ảnh',
                  style: TextStyle(
                      color: c.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: c.secondary),
              title: Text('Chọn từ thư viện',
                  style: TextStyle(
                      color: c.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final c = AppColors.of(context);
    final auth = context.read<AuthProvider>();
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      setState(() => _uploadingAvatar = true);
      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

      final res = await auth.uploadAvatar(bytes, mimeType: mime);
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);

      final ok = res['success'] == true;
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ??
              (ok ? 'Cập nhật ảnh đại diện thành công' : 'Tải ảnh thất bại')),
          backgroundColor: ok ? c.success : c.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Không thể tải ảnh lên. Vui lòng thử lại.'),
          backgroundColor: c.danger,
        ),
      );
    }
  }

  InputDecoration _dialogDecoration(String label, IconData icon, AppColors c) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: c.textMuted),
      prefixIcon: Icon(icon, size: 18, color: c.textMuted),
      filled: true,
      fillColor: c.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Future<void> _showEditNamePhone() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final c = AppColors.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final formKey = GlobalKey<FormState>();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
          title: Text('Chỉnh sửa thông tin',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: c.textPrimary)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: c.textPrimary),
                  decoration:
                      _dialogDecoration('Họ và tên', Icons.person_outline, c),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    if (v.trim().length < 2) {
                      return 'Họ tên quá ngắn';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: c.textPrimary),
                  decoration: _dialogDecoration(
                      'Số điện thoại', Icons.phone_outlined, c),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    if (!RegExp(r'^(0|\+84)[0-9]{8,10}$').hasMatch(t)) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text('Huỷ',
                  style: TextStyle(
                      color: c.textMuted, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlg(() => saving = true);
                      final res = await auth.updateProfile(
                        fullName: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      final ok = res['success'] == true;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(res['message']?.toString() ??
                              (ok
                                  ? 'Cập nhật thông tin thành công'
                                  : 'Cập nhật thất bại')),
                          backgroundColor: ok ? c.success : c.danger,
                        ),
                      );
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Lưu',
                      style: TextStyle(
                          color: c.secondary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final user = authProvider.user;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: c.background,
          appBar: AppBar(
            title: const Text('Tài khoản'),
            backgroundColor: c.background,
            foregroundColor: c.textPrimary,
            elevation: 0,
          ),
          body: isLoggedIn && user != null
              ? _buildLoggedIn(user)
              : _buildGuest(),
        ),
        // Logout confirm overlay
        if (_showLogoutDialog)
          GestureDetector(
            onTap: () => setState(() => _showLogoutDialog = false),
            child: Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {}, // block tap-through
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(color: c.border.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Đăng xuất',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Bạn có chắc muốn đăng xuất khỏi tài khoản không?',
                        style: TextStyle(fontSize: 14, color: c.textMuted),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: 'Huỷ',
                              height: 48,
                              onPressed: () =>
                                  setState(() => _showLogoutDialog = false),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Đăng xuất',
                              height: 48,
                              background: c.danger,
                              foreground: Colors.white,
                              onPressed: _doLogout,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoggedIn(AuthUser user) {
    final c = AppColors.of(context);
    final favCount = context.watch<WishlistProvider>().favoriteCount;

    String roleLabel = 'Khách hàng';
    Color roleColor = c.secondary;
    if (user.isAdmin) {
      roleLabel = 'Quản trị viên (Admin)';
      roleColor = const Color(0xFFEF4444);
    } else if (user.isStaff) {
      roleLabel = 'Nhân viên vận hành';
      roleColor = const Color(0xFF3B82F6);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl,
          MediaQuery.of(context).padding.bottom + 96),
      children: [
        // Avatar & info
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _uploadingAvatar ? null : _showAvatarSourceSheet,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    UserAvatarView(
                      avatarUrl: user.avatarUrl,
                      fullName: user.fullName,
                      size: 84,
                    ),
                    if (_uploadingAvatar)
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: c.secondary,
                            ),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: c.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.background, width: 2.5),
                      ),
                      child: Icon(Icons.camera_alt_rounded,
                          size: 14, color: c.onPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: _showEditNamePhone,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.edit_outlined, size: 16, color: c.secondary),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                user.email,
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _showEditNamePhone,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 13, color: c.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        (user.phone != null && user.phone!.isNotEmpty)
                            ? user.phone!
                            : 'Thêm số điện thoại',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: (user.phone != null && user.phone!.isNotEmpty)
                              ? c.textPrimary
                              : c.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit_outlined, size: 12, color: c.secondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.isAdmin
                          ? Icons.shield_rounded
                          : (user.isStaff
                              ? Icons.badge_rounded
                              : Icons.person_rounded),
                      size: 14,
                      color: roleColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/edit-profile'),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text(
                  'Chỉnh sửa hồ sơ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryLight,
                  side: BorderSide(color: AppTheme.primaryLight.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        _menuItem(
          icon: Icons.person_outline_rounded,
          label: 'Thông tin cá nhân',
          onTap: () => context.push('/edit-profile'),
        ),
        _menuItem(
          icon: Icons.favorite_rounded,
          label: 'Sản phẩm yêu thích',
          badgeText: favCount > 0 ? '$favCount' : null,
          onTap: () => context.push('/wishlist'),
        ),
        _menuItem(
          icon: Icons.shopping_bag_outlined,
          label: 'Đơn hàng của tôi',
          onTap: () => context.push('/my-orders'),
        ),
        if (user.isAdmin || user.isStaff) ...[
          const SizedBox(height: AppSpacing.sm),
          Divider(color: c.border.withValues(alpha: 0.6)),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text(
              user.isAdmin ? 'QUẢN TRỊ VIÊN' : 'VẬN HÀNH HỆ THỐNG',
              style: TextStyle(
                color: c.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _menuItem(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Quản lý đơn hàng (${user.isAdmin ? "Admin" : "Vận hành"})',
            badgeText: user.isAdmin ? 'Admin' : 'Staff',
            onTap: () => context.push('/admin/orders'),
          ),
        ],
        _menuItem(
            icon: Icons.location_on_outlined,
            label: 'Địa chỉ giao hàng',
            onTap: () => context.push('/shipping-address')),
        _menuItem(
            icon: Icons.notifications_outlined,
            label: 'Thông báo',
            onTap: () => context.push('/notifications')),
        _menuItem(
            icon: Icons.help_outline_rounded,
            label: 'Trợ giúp & Hỗ trợ',
            onTap: () => context.push('/help-support')),
        const SizedBox(height: AppSpacing.md),
        Divider(color: c.border.withValues(alpha: 0.6)),
        const SizedBox(height: AppSpacing.md),
        _menuItem(
          icon: Icons.logout_rounded,
          label: 'Đăng xuất',
          onTap: _confirmLogout,
          isRed: true,
        ),
      ],
    );
  }

  Widget _buildGuest() {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: c.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_outline_rounded,
                  size: 44, color: c.secondary),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Bạn chưa đăng nhập',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Text(
              'Đăng nhập để theo dõi đơn hàng, quản lý danh sách yêu thích và trải nghiệm mua sắm tốt hơn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.5)),
          const SizedBox(height: AppSpacing.xxxl),
          PrimaryButton(
            label: 'Đăng nhập',
            onPressed: () => context.push('/login'),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: 'Tạo tài khoản',
            onPressed: () => context.push('/register'),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badgeText,
    bool isRed = false,
  }) {
    final c = AppColors.of(context);
    final accent = isRed ? c.danger : c.secondary;
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: c.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(color: c.shadow, blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isRed ? c.danger.withValues(alpha: 0.12) : c.primarySoft,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isRed ? c.danger : c.textPrimary,
                ),
              ),
            ),
            if (badgeText != null)
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: c.danger,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (!isRed)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
