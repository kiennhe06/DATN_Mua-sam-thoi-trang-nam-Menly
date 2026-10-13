import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../../data/models/product_model.dart';

class ProductImageHeader extends StatelessWidget {
  final Product product;
  final bool favorite;

  const ProductImageHeader({
    super.key,
    required this.product,
    required this.favorite,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
          child: SizedBox(
            height: 380,
            width: double.infinity,
            child: product.imageUrl.isEmpty
                ? Container(color: c.surfaceVariant)
                : CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: c.surfaceVariant),
                    errorWidget: (_, __, ___) =>
                        Container(color: c.surfaceVariant),
                  ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                background: c.surface,
                onTap: () => context.pop(),
              ),
              Consumer<WishlistProvider>(
                builder: (context, wishlist, _) {
                  final isFav = wishlist.isFavorite(product.id);
                  return CircleIconButton(
                    icon: isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    foreground: isFav ? c.danger : c.textPrimary,
                    background: c.surface,
                    onTap: () async {
                      try {
                        await wishlist.toggleWishlist(product);
                      } catch (_) {}
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
