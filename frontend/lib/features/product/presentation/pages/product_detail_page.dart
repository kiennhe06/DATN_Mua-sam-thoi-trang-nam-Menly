import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../cart/data/cart_model.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/models/review_model.dart';
import '../providers/product_provider.dart';
import '../widgets/product_bottom_bar.dart';
import '../widgets/product_image_header.dart';
import '../widgets/product_lookbook_section.dart';
import '../widgets/product_reviews_section.dart';
import '../widgets/product_variant_selector.dart';
import '../widgets/size_advisor_sheet.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Product> _future;
  String? _size;
  String? _color;
  int _qty = 1;
  List<Review> _reviews = [];
  bool _loadingReviews = true;
  double _avgRating = 5.0;

  @override
  void initState() {
    super.initState();
    _future = context.read<ProductProvider>().getProductDetail(
      widget.productId,
    );
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final res = await DioClient.instance.dio.get(
        '/reviews/product/${widget.productId}?limit=100',
      );
      final data = res.data;
      final payload = data is Map && data['data'] != null ? data['data'] : data;
      final items =
          (payload['items'] as List?)
              ?.map((j) => Review.fromJson(j))
              .toList() ??
          [];
      if (mounted) {
        setState(() {
          _reviews = items;
          if (_reviews.isNotEmpty) {
            _avgRating =
                _reviews.fold(0.0, (s, r) => s + r.rating) / _reviews.length;
          }
          _loadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  List<String> _distinct(
    List<ProductVariant> v,
    String Function(ProductVariant) f,
  ) {
    final seen = <String>[];
    for (final x in v) {
      final val = f(x);
      if (val.isNotEmpty && !seen.contains(val)) seen.add(val);
    }
    return seen;
  }

  ProductVariant? _selectedVariant(Product p) {
    for (final v in p.variants) {
      if ((_size == null || v.size == _size) &&
          (_color == null || v.color == _color)) {
        return v;
      }
    }
    return p.variants.isNotEmpty ? p.variants.first : null;
  }

  Future<void> _addToCart(Product p, {bool buyNow = false}) async {
    final variant = _selectedVariant(p);
    if (variant == null) return;
    final ok = AuthGuard.check(context, redirectPath: '/products/${p.id}');
    if (!ok) return;
    await context.read<CartProvider>().addItem(p, variant, _qty);
    if (!mounted) return;
    if (buyNow) {
      context.push('/checkout');
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm vào giỏ hàng'),
          duration: Duration(milliseconds: 1500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: FutureBuilder<Product>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }
          if (snap.hasError || !snap.hasData) {
            return _ProductErrorView(onBack: () => context.pop());
          }
          return _buildContent(snap.data!, c);
        },
      ),
    );
  }

  Widget _buildContent(Product p, AppColors c) {
    final sizes = _distinct(p.variants, (v) => v.size);
    final colors = _distinct(p.variants, (v) => v.color);
    final variant = _selectedVariant(p);
    final stock = variant?.stock ?? p.stock;
    final wishlist = context.watch<WishlistProvider>();
    final fav = wishlist.isFavorite(p.id);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ProductImageHeader(product: p, favorite: fav),
              Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  // Responsive margin chuẩn 14px giúp nội dung thoáng đãng
                  padding: const EdgeInsets.fromLTRB(14, 22, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                        ),
                        child: Text(
                          'Thời trang nam',
                          style: TextStyle(
                            color: c.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.name,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatVnd(p.price),
                            style: TextStyle(
                              color: c.secondary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          ProductStockBadge(stock: stock),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Đánh giá tối giản: Bỏ icon sao, hiển thị text số chuẩn phong cách sang trọng
                      Text(
                        '${_avgRating.toStringAsFixed(1)} / 5.0 • ${_reviews.length} đánh giá',
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (p.description != null &&
                          p.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          p.description!,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 14,
                            height: 1.55,
                          ),
                        ),
                      ],
                      if (sizes.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Text(
                              'Kích cỡ',
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                SizeAdvisorSheet.show(
                                  context: context,
                                  availableSizes: sizes,
                                  onApplySize: (advisedSize) {
                                    // Tự động chọn size đề xuất
                                    if (sizes.contains(advisedSize)) {
                                      setState(() => _size = advisedSize);
                                    } else if (sizes.isNotEmpty) {
                                      setState(() => _size = advisedSize);
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Đã áp dụng Size $advisedSize theo vóc dáng của bạn',
                                        ),
                                        duration: const Duration(
                                          milliseconds: 1500,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.straighten_rounded,
                                    size: 16,
                                    color: c.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tư vấn Size',
                                    style: TextStyle(
                                      color: c.secondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ProductOptionRow(
                          options: sizes,
                          selected: _size ?? sizes.first,
                          onSelect: (s) => setState(() => _size = s),
                        ),
                      ],
                      if (colors.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Màu sắc',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ProductOptionRow(
                          options: colors,
                          selected: _color ?? colors.first,
                          onSelect: (s) => setState(() => _color = s),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'Số lượng',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ProductQtyStepper(
                        qty: _qty,
                        max: stock,
                        onChanged: (q) => setState(() => _qty = q),
                      ),
                      const SizedBox(height: 20),
                      // Lookbook Mix & Match gợi ý phối đồ
                      ProductLookbookSection(
                        currentProduct: p,
                        onBuyLookbook: () async {
                          await _addToCart(p);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Đã thêm trọn bộ phối đồ vào giỏ hàng!',
                                ),
                                duration: Duration(milliseconds: 1800),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 28),
                      // Reviews section
                      ProductReviewsSection(
                        productId: p.id,
                        reviews: _reviews,
                        isLoading: _loadingReviews,
                        onReviewSubmitted: _loadReviews,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ProductBottomBar(
          onAddToCart: () => _addToCart(p),
          onBuyNow: () => _addToCart(p, buyNow: true),
          disabled: stock <= 0,
        ),
      ],
    );
  }
}

class _ProductErrorView extends StatelessWidget {
  final VoidCallback onBack;
  const _ProductErrorView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: c.textMuted, size: 44),
            const SizedBox(height: 12),
            Text(
              'Không tải được sản phẩm',
              style: TextStyle(color: c.textSecondary),
            ),
            const SizedBox(height: 16),
            SecondaryButton(
              label: 'Quay lại',
              expanded: false,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}
