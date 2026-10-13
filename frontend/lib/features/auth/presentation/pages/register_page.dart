import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_role_selector.dart';
import '../widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  final String? redirect;
  const RegisterPage({super.key, this.redirect});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  String _selectedRole = 'customer'; // 'customer' | 'staff'
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _snack('Vui lòng điền đầy đủ thông tin');
      return;
    }
    if (pass.length < 6) {
      _snack('Mật khẩu phải ít nhất 6 ký tự');
      return;
    }
    if (pass != confirm) {
      _snack('Mật khẩu xác nhận không khớp');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(name, email, pass, role: _selectedRole);

    if (!mounted) return;

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('savedEmail', email.trim());
      await prefs.setString('savedPassword', pass);
      await prefs.setBool('rememberMe', true);

      if (!mounted) return;
      final c = AppColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedRole == 'staff'
                ? '🎉 Đăng ký tài khoản Nhân viên thành công!'
                : '🎉 Đăng ký tài khoản Khách hàng thành công!',
          ),
          backgroundColor: c.success,
        ),
      );
      context.read<WishlistProvider>().fetchWishlist(forceRefresh: true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        final target =
            widget.redirect ??
            GoRouterState.of(context).uri.queryParameters['redirect'];
        if (target != null && target.isNotEmpty) {
          context.go(target);
        } else {
          context.go('/');
        }
      }
    } else {
      _snack(auth.state.message ?? 'Đăng ký thất bại. Vui lòng thử lại.');
    }
  }

  void _snack(String msg) {
    final cleanMsg = DioClient.cleanErrorMessage(msg);
    final c = AppColors.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cleanMsg),
        backgroundColor: c.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final authState = context.watch<AuthProvider>().state;
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Back
              Align(
                alignment: Alignment.centerLeft,
                child: CircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  size: 40,
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tạo tài khoản',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Đăng ký để mua sắm hoặc quản lý vận hành Menly',
                style: TextStyle(fontSize: 14, color: c.textMuted),
              ),
              const SizedBox(height: 24),

              // Vai trò tài khoản (Khách hàng vs Nhân viên)
              AuthRoleSelector(
                selectedRole: _selectedRole,
                onRoleChanged: (role) => setState(() => _selectedRole = role),
              ),
              const SizedBox(height: 16),

              // Name
              AuthTextField(
                label: 'Họ và tên',
                hint: 'Nguyễn Văn A',
                icon: Icons.person_outline_rounded,
                controller: _nameCtrl,
              ),
              const SizedBox(height: 16),

              // Email
              AuthTextField(
                label: 'Email',
                hint: 'example@email.com',
                icon: Icons.email_outlined,
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password
              AuthTextField(
                label: 'Mật khẩu',
                hint: 'Ít nhất 6 ký tự',
                icon: Icons.lock_outline_rounded,
                controller: _passCtrl,
                obscureText: _obscure,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: c.textMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm password
              AuthTextField(
                label: 'Xác nhận mật khẩu',
                hint: 'Nhập lại mật khẩu',
                icon: Icons.lock_outline_rounded,
                controller: _confirmPassCtrl,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: c.textMuted,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 28),

              // Register button
              PrimaryButton(
                label: _selectedRole == 'staff'
                    ? 'Đăng ký Nhân viên'
                    : 'Đăng ký Khách hàng',
                loading: isLoading,
                onPressed: isLoading ? null : _register,
              ),
              const SizedBox(height: 20),

              // Go to login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Đã có tài khoản? ',
                    style: TextStyle(color: c.textMuted, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: c.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
