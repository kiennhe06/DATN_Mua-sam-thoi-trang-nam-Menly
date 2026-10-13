import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../widgets/home_category_rail.dart';
import '../widgets/home_header.dart';
import '../widgets/home_product_tile.dart';
import '../widgets/home_promo_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: c.background,
      body: RefreshIndicator(
        color: c.primary,
        onRefresh: () => provider.fetchAll(forceRefresh: true),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const HomeHeader(),
            const SizedBox(height: 18),
            const HomePromoBanner(),
            const SizedBox(height: 24),
            HomeCategoryRail(provider: provider),
            const SizedBox(height: 24),
            _buildProducts(provider),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 96),
          ],
        ),
      ),
    );
  }

  Widget _buildProducts(ProductProvider provider) {
    return provider.productsState.when(
      initial: () => const SizedBox(height: 280, child: LoadingView()),
      loading: () => const SizedBox(height: 280, child: LoadingView()),
      error: (msg) => SizedBox(
        height: 320,
        child: StatusView(
          icon: Icons.wifi_off_rounded,
          title: 'Không tải được sản phẩm',
          message: msg,
          actionLabel: 'Thử lại',
          danger: true,
          onAction: () => provider.fetchAll(forceRefresh: true),
        ),
      ),
      success: (products) {
        if (products.isEmpty) {
          return const SizedBox(
            height: 280,
            child: StatusView(
              icon: Icons.inventory_2_outlined,
              title: 'Chưa có sản phẩm',
              message: 'Hãy quay lại sau nhé',
            ),
          );
        }
        final featured = products.take(8).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(
                title: 'Sản phẩm nổi bật',
                actionLabel: 'Xem tất cả',
                onAction: () => context.go('/products'),
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.55,
              ),
              itemCount: featured.length,
              itemBuilder: (_, i) => HomeProductTile(product: featured[i]),
            ),
          ],
        );
      },
    );
  }
}
