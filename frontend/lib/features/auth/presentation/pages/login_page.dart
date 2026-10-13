import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../cart/data/cart_model.dart';
import '../../../order/presentation/providers/order_provider.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_text_field.dart';

class LoginPage extends StatefulWidget {
  final String? redirect;
  const LoginPage({super.key, this.redirect});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('savedEmail') ?? '';
    final savedPass = prefs.getString('savedPassword') ?? '';
    final remember = prefs.getBool('rememberMe') ?? true;

    if (mounted) {
      setState(() {
        _rememberMe = remember;
        if (remember) {
          if (savedEmail.isNotEmpty) _emailCtrl.text = savedEmail;
          if (savedPass.isNotEmpty) _passCtrl.text = savedPass;
        }
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _snack('Vui lòng nhập email và mật khẩu');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', _rememberMe);
      if (_rememberMe) {
        await prefs.setString('savedEmail', _emailCtrl.text.trim());
        await prefs.setString('savedPassword', _passCtrl.text);
      } else {
        await prefs.remove('savedEmail');
        await prefs.remove('savedPassword');
      }

      if (mounted) {
        final c = AppColors.of(context);
        context.read<CartProvider>().fetchCart();
        context.read<WishlistProvider>().fetchWishlist(forceRefresh: true);
        context.read<OrderProvider>().fetchMyOrders(forceRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Chào mừng trở lại, ${auth.user?.fullName ?? ''}!',
            ),
            backgroundColor: c.success,
          ),
        );
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
      _snack(
        auth.state.message ??
            'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.',
      );
    }
  }

  void _snack(String msg) {
    final cleanMsg = DioClient.cleanErrorMessage(msg);
    final c = AppColors.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(cleanMsg), backgroundColor: c.danger),
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
              const AuthBrandHeader(
                title: 'Đăng nhập',
                subtitle: 'Chào mừng bạn trở lại!',
              ),
              const SizedBox(height: 28),

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
                hint: '••••••••',
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

              // Remember me + Quên mật khẩu
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _rememberMe = !_rememberMe);
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setBool('rememberMe', _rememberMe);
                        if (!_rememberMe) {
                          prefs.remove('savedEmail');
                          prefs.remove('savedPassword');
                        }
                      });
                    },
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _rememberMe ? c.primary : Colors.transparent,
                            border: Border.all(
                              color: _rememberMe ? c.primary : c.textMuted,
                              width: 1.8,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                          ),
                          child: _rememberMe
                              ? Icon(
                                  Icons.check_rounded,
                                  color: c.onPrimary,
                                  size: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tự động lưu mật khẩu',
                          style: TextStyle(
                            fontSize: 13,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/forgot-password'),
                    child: Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        fontSize: 13,
                        color: c.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Login button
              PrimaryButton(
                label: 'Đăng nhập',
                loading: isLoading,
                onPressed: isLoading ? null : _login,
              ),
              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: c.surfaceVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'hoặc',
                      style: TextStyle(color: c.textMuted, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: c.surfaceVariant)),
                ],
              ),
              const SizedBox(height: 20),

              // Go to register
              SecondaryButton(
                label: 'Tạo tài khoản mới',
                onPressed: () {
                  final target =
                      widget.redirect ??
                      GoRouterState.of(context).uri.queryParameters['redirect'];
                  if (target != null && target.isNotEmpty) {
                    context.push(
                      '/register?redirect=${Uri.encodeComponent(target)}',
                    );
                  } else {
                    context.push('/register');
                  }
                },
              ),
              const SizedBox(height: 24),

              // Continue as guest
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(
                  'Tiếp tục không đăng nhập →',
                  style: TextStyle(color: c.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
