import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/add_to_cart_button.dart';
import '../../../cart/data/cart_model.dart';
import '../../../product/data/models/product_model.dart';
import '../providers/wishlist_provider.dart';

class WishlistItemCard extends StatelessWidget {
  final Product product;

  const WishlistItemCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh + Nút Bỏ thích
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: product.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: c.surfaceVariant,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: c.surfaceVariant,
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  color: c.textMuted,
                                ),
                              ),
                            )
                          : Container(color: c.surfaceVariant),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        tooltip: 'Bỏ thích',
                        onPressed: () {
                          context.read<WishlistProvider>().toggleWishlist(
                                product,
                              );
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã bỏ thích "${product.name}"'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Thông tin sản phẩm
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatVnd(product.price),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AddToCartButton(
                    height: 36,
                    onTap: () {
                      if (!AuthGuard.check(
                        context,
                        actionTitle: 'Đăng nhập để mua hàng',
                        actionMessage:
                            'Bạn đang duyệt ẩn danh. Vui lòng đăng nhập để thêm "${product.name}" vào giỏ hàng và thanh toán.',
                      )) {
                        return;
                      }
                      if (product.variants.isNotEmpty) {
                        final v = product.variants.first;
                        context.read<CartProvider>().addItem(product, v, 1);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã thêm "${product.name}" vào giỏ hàng',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      } else {
                        context.push('/products/${product.id}');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
