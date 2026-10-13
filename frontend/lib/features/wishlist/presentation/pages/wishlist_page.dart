import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/wishlist_empty_view.dart';
import '../widgets/wishlist_guest_view.dart';
import '../widgets/wishlist_item_card.dart';
import '../widgets/wishlist_skeleton_grid.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().isLoggedIn) {
        context.read<WishlistProvider>().fetchWishlist();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final wishlistProv = context.watch<WishlistProvider>();
    final state = wishlistProv.state;
    final items = wishlistProv.items;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(
          items.isNotEmpty
              ? 'Sản phẩm yêu thích (${items.length})'
              : 'Sản phẩm yêu thích',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: c.background,
        elevation: 0,
        actions: [
          if (auth.isLoggedIn && items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Làm mới',
              onPressed: () => context
                  .read<WishlistProvider>()
                  .fetchWishlist(forceRefresh: true),
            ),
        ],
      ),
      body: !auth.isLoggedIn
          ? const WishlistGuestView()
          : RefreshIndicator(
              onRefresh: () => context
                  .read<WishlistProvider>()
                  .fetchWishlist(forceRefresh: true),
              color: c.secondary,
              backgroundColor: c.surface,
              child: Builder(
                builder: (context) {
                  if (state.isLoading && items.isEmpty) {
                    return const WishlistSkeletonGrid();
                  }

                  if (state.isError && items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: c.danger,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.message ??
                                  'Không thể tải danh sách yêu thích',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => context
                                  .read<WishlistProvider>()
                                  .fetchWishlist(forceRefresh: true),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (items.isEmpty) {
                    return const WishlistEmptyView();
                  }

                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      MediaQuery.of(context).padding.bottom + 96,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return WishlistItemCard(product: items[index]);
                    },
                  );
                },
              ),
            ),
    );
  }
}
