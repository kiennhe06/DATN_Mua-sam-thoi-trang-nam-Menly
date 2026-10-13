import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../data/cart_model.dart';
import '../widgets/cart_bottom_bar.dart';
import '../widgets/cart_clear_dialog.dart';
import '../widgets/cart_empty_view.dart';
import '../widgets/cart_item_card.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  void _proceedToCheckout(BuildContext context) {
    if (!AuthGuard.check(
      context,
      actionTitle: 'Đăng nhập để thanh toán',
      actionMessage:
          'Bạn đang ở chế độ xem ẩn danh. Để tiến hành đặt hàng và thanh toán, vui lòng đăng nhập tài khoản.',
      redirectPath: '/checkout',
    )) {
      return;
    }

    context.push('/checkout');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(
          'Giỏ hàng${cart.totalItems > 0 ? " (${cart.totalItems})" : ""}',
        ),
        backgroundColor: c.background,
        actions: [
          if (cart.items.isNotEmpty)
            TextButton.icon(
              onPressed: () => CartClearDialog.show(context, cart),
              icon: Icon(Icons.delete_sweep_rounded, size: 18, color: c.danger),
              label: Text(
                'Xoá hết',
                style: TextStyle(color: c.danger, fontSize: 13),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => cart.fetchCart(showLoading: true),
        color: c.secondary,
        backgroundColor: c.surface,
        child: cart.items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const CartEmptyView(),
                  ),
                ],
              )
            : Column(
                children: [
                  _SelectAllHeader(cart: cart),
                  Expanded(
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: cart.items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) => CartItemCard(
                        item: cart.items[i],
                        selected: cart.isSelected(cart.items[i].variant.id),
                        onToggleSelected: () =>
                            cart.toggleSelected(cart.items[i].variant.id),
                        onRemove: () =>
                            cart.removeItem(cart.items[i].variant.id),
                        onQtyChange: (q) =>
                            cart.updateQty(cart.items[i].variant.id, q),
                      ),
                    ),
                  ),
                  CartBottomBar(
                    cart: cart,
                    onCheckout: () => _proceedToCheckout(context),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SelectAllHeader extends StatelessWidget {
  final CartProvider cart;
  const _SelectAllHeader({required this.cart});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: () => cart.setAllSelected(!cart.allSelected),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: cart.allSelected ? c.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: cart.allSelected ? c.primary : c.border,
                  width: 1.6,
                ),
              ),
              child: cart.allSelected
                  ? Icon(Icons.check_rounded, size: 15, color: c.onPrimary)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              'Chọn tất cả',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${cart.selectedCount} sản phẩm đã chọn',
              style: TextStyle(color: c.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
