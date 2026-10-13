import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../cart/data/cart_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_guest_view.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_logout_dialog.dart';
import '../widgets/profile_menu_item.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showLogoutDialog = false;

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
      context.go('/login');
    }
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
              : const ProfileGuestView(),
        ),
        if (_showLogoutDialog)
          ProfileLogoutDialog(
            onCancel: () => setState(() => _showLogoutDialog = false),
            onConfirm: _doLogout,
          ),
      ],
    );
  }

  Widget _buildLoggedIn(AuthUser user) {
    final c = AppColors.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        MediaQuery.of(context).padding.bottom + 96,
      ),
      children: [
        ProfileHeaderCard(user: user),
        const SizedBox(height: AppSpacing.xxl),

        ProfileMenuItem(
          icon: Icons.person_outline_rounded,
          label: 'Thông tin cá nhân',
          onTap: () => context.push('/edit-profile'),
        ),
        ProfileMenuItem(
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
          ProfileMenuItem(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Quản lý đơn hàng (${user.isAdmin ? "Admin" : "Vận hành"})',
            badgeText: user.isAdmin ? 'Admin' : 'Staff',
            onTap: () => context.push('/admin/orders'),
          ),
        ],
        ProfileMenuItem(
          icon: Icons.location_on_outlined,
          label: 'Địa chỉ giao hàng',
          onTap: () => context.push('/shipping-address'),
        ),
        ProfileMenuItem(
          icon: Icons.notifications_outlined,
          label: 'Thông báo',
          onTap: () => context.push('/notifications'),
        ),
        ProfileMenuItem(
          icon: Icons.help_outline_rounded,
          label: 'Trợ giúp & Hỗ trợ',
          onTap: () => context.push('/help-support'),
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(color: c.border.withValues(alpha: 0.6)),
        const SizedBox(height: AppSpacing.md),
        ProfileMenuItem(
          icon: Icons.logout_rounded,
          label: 'Đăng xuất',
          onTap: _confirmLogout,
          isRed: true,
        ),
      ],
    );
  }
}
