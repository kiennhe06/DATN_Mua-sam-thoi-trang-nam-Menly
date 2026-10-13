import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/app_pill_nav.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/product/presentation/providers/product_provider.dart';
import 'features/wishlist/presentation/providers/wishlist_provider.dart';
import 'features/wishlist/presentation/pages/wishlist_page.dart';
import 'features/cart/data/cart_model.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/product/presentation/pages/product_list_page.dart';
import 'features/product/presentation/pages/product_detail_page.dart';
import 'features/cart/presentation/pages/cart_page.dart';
import 'features/order/presentation/pages/checkout_page.dart';
import 'features/order/presentation/pages/order_list_page.dart';
import 'features/order/presentation/pages/order_detail_page.dart';
import 'features/order/data/order_model.dart';
import 'features/order/presentation/pages/admin_order_management_page.dart';
import 'features/order/presentation/pages/order_success_page.dart';
import 'features/order/presentation/pages/vnpay_payment_page.dart';
import 'features/order/presentation/pages/vnpay_webview_page.dart';
import 'features/order/presentation/providers/order_provider.dart';
import 'features/notification/presentation/providers/notification_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/profile_page.dart';
import 'features/auth/presentation/pages/edit_profile_page.dart';
import 'features/auth/presentation/pages/change_password_page.dart';
import 'features/auth/presentation/pages/shipping_address_page.dart';
import 'features/auth/presentation/pages/notifications_page.dart';
import 'features/auth/presentation/pages/help_support_page.dart';
import 'features/order/presentation/pages/my_orders_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint(
      'Supabase initialization notice (offline or local fallback): $e',
    );
  }

  final themeController = ThemeController();
  await themeController.load();

  runApp(MenlyApp(themeController: themeController));
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Splash screen
    GoRoute(path: '/splash', builder: (ctx, s) => const SplashPage()),

    // Onboarding — giới thiệu, ngoài shell
    GoRoute(path: '/onboarding', builder: (ctx, s) => const OnboardingPage()),

    // Auth routes — ngoài shell (không có bottom nav)
    GoRoute(
      path: '/login',
      builder: (ctx, s) =>
          LoginPage(redirect: s.uri.queryParameters['redirect']),
    ),
    GoRoute(
      path: '/register',
      builder: (ctx, s) =>
          RegisterPage(redirect: s.uri.queryParameters['redirect']),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (ctx, s) => const ForgotPasswordPage(),
    ),

    // Product detail — full screen (no bottom nav), giống thiết kế tham chiếu
    GoRoute(
      path: '/products/:id',
      builder: (ctx, s) =>
          ProductDetailPage(productId: s.pathParameters['id']!),
    ),

    // Màn push toàn màn hình (không có bottom nav)
    GoRoute(path: '/cart', builder: (ctx, s) => const CartPage()),
    GoRoute(path: '/checkout', builder: (ctx, s) => const CheckoutPage()),
    GoRoute(
      path: '/payment/vnpay',
      builder: (ctx, s) {
        Order? order;
        String? paymentUrl;
        String? bankCode;

        if (s.extra is Order) {
          order = s.extra as Order;
        } else if (s.extra is Map<String, dynamic>) {
          final map = s.extra as Map<String, dynamic>;
          order = map['order'] as Order?;
          paymentUrl = map['paymentUrl'] as String?;
          bankCode = map['bankCode'] as String?;
        }

        order ??= Order(
          id: s.uri.queryParameters['orderId'] ?? '',
          code: s.uri.queryParameters['code'] ?? 'ORD',
          userId: '',
          status: 'pending_payment',
          paymentMethod: 'vnpay',
          subtotal: int.tryParse(s.uri.queryParameters['total'] ?? '') ?? 0,
          shippingFee: 0,
          total: int.tryParse(s.uri.queryParameters['total'] ?? '') ?? 0,
          shipName: s.uri.queryParameters['shipName'] ?? 'Khách hàng',
          shipPhone: s.uri.queryParameters['shipPhone'] ?? '',
          shipAddress: '',
          createdAt: DateTime.now().toIso8601String(),
        );

        paymentUrl ??= s.uri.queryParameters['paymentUrl'];
        bankCode ??= s.uri.queryParameters['bankCode'];

        return VNPayWebViewPage(
          order: order,
          paymentUrl: paymentUrl,
          bankCode: bankCode,
        );
      },
    ),
    GoRoute(
      path: '/payment/vnpay/banks',
      builder: (ctx, s) {
        final order = s.extra is Order ? (s.extra as Order) : null;
        if (order != null) {
          return VNPayPaymentPage(order: order);
        }
        final fallbackOrder = Order(
          id: s.uri.queryParameters['orderId'] ?? '',
          code: s.uri.queryParameters['code'] ?? 'ORD',
          userId: '',
          status: 'pending_payment',
          paymentMethod: 'vnpay',
          subtotal: int.tryParse(s.uri.queryParameters['total'] ?? '') ?? 0,
          shippingFee: 0,
          total: int.tryParse(s.uri.queryParameters['total'] ?? '') ?? 0,
          shipName: s.uri.queryParameters['shipName'] ?? 'Khách hàng',
          shipPhone: s.uri.queryParameters['shipPhone'] ?? '',
          shipAddress: '',
          createdAt: DateTime.now().toIso8601String(),
        );
        return VNPayPaymentPage(order: fallbackOrder);
      },
    ),
    GoRoute(
      path: '/order-success',
      builder: (ctx, s) => OrderSuccessPage(
        orderCode: s.uri.queryParameters['code'],
        total: int.tryParse(s.uri.queryParameters['total'] ?? ''),
      ),
    ),
    GoRoute(path: '/orders', builder: (ctx, s) => const OrderListPage()),
    GoRoute(
      path: '/orders/:id',
      builder: (ctx, s) => OrderDetailPage(
        orderId: s.pathParameters['id']!,
        order: s.extra is Order ? (s.extra as Order) : null,
      ),
    ),
    GoRoute(
      path: '/admin/orders',
      builder: (ctx, s) => const AdminOrderManagementPage(),
    ),
    GoRoute(path: '/my-orders', builder: (ctx, s) => const MyOrdersPage()),
    GoRoute(
      path: '/shipping-address',
      builder: (ctx, s) => const ShippingAddressPage(),
    ),
    GoRoute(
      path: '/change-password',
      builder: (ctx, s) => const ChangePasswordPage(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (ctx, s) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (ctx, s) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/help-support',
      builder: (ctx, s) => const HelpSupportPage(),
    ),

    // 4 tab chính (có bottom nav)
    ShellRoute(
      builder: (ctx, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (ctx, s) => const HomePage()),
        GoRoute(
          path: '/products',
          builder: (ctx, s) {
            final catId =
                (s.extra as String?) ?? s.uri.queryParameters['categoryId'];
            return ProductListPage(
              key: ValueKey(catId ?? 'all'),
              initialCategoryId: catId,
            );
          },
        ),
        GoRoute(path: '/wishlist', builder: (ctx, s) => const WishlistPage()),
        GoRoute(path: '/profile', builder: (ctx, s) => const ProfilePage()),
      ],
    ),
  ],
);

class MenlyApp extends StatelessWidget {
  final ThemeController? themeController;
  const MenlyApp({super.key, this.themeController});

  @override
  Widget build(BuildContext context) {
    final controller = themeController ?? ThemeController();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: controller),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()..fetchUnreadCount(),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) => MaterialApp.router(
          title: 'Menly - Thời trang nam',
          theme: theme.lightTheme,
          darkTheme: theme.darkTheme,
          themeMode: theme.mode,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/wishlist')) return 2;
    if (location.startsWith('/cart')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(int i, BuildContext ctx) {
    switch (i) {
      case 0:
        ctx.go('/');
        break;
      case 1:
        ctx.go('/products');
        break;
      case 2:
        ctx.go('/wishlist');
        break;
      case 3:
        ctx.push('/cart');
        break;
      case 4:
        ctx.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().totalItems;
    final favCount = context.watch<WishlistProvider>().favoriteCount;
    final currentIdx = _calculateSelectedIndex(context);

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: AppPillNav(
        currentIndex: currentIdx,
        onTap: (i) => _onTap(i, context),
        items: [
          const PillNavItem(Icons.home_rounded),
          const PillNavItem(Icons.grid_view_rounded),
          PillNavItem(Icons.favorite_rounded, badge: favCount),
          PillNavItem(Icons.shopping_bag_rounded, badge: cartCount),
          const PillNavItem(Icons.person_rounded),
        ],
      ),
    );
  }
}
