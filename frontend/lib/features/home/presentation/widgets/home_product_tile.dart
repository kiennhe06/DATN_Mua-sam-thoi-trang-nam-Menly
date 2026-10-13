import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/auth_guard.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../cart/data/cart_model.dart';
import '../../../product/data/models/product_model.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';

class HomeProductTile extends StatelessWidget {
  final Product product;
  const HomeProductTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    return ProductCard(
      product: product,
      isFavorite: wishlist.isFavorite(product.id),
      onTap: () => context.push('/products/${product.id}'),
      onToggleFavorite: () async {
        try {
          await context.read<WishlistProvider>().toggleWishlist(product);
        } catch (_) {}
      },
      onAdd: () => _quickAdd(context, product),
    );
  }

  void _quickAdd(BuildContext context, Product product) {
    if (product.variants.isEmpty) {
      context.push('/products/${product.id}');
      return;
    }
    final ok = AuthGuard.check(context, redirectPath: '/');
    if (!ok) return;
    context.read<CartProvider>().addItem(product, product.variants.first, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
    );
  }
}
