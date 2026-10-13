import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/order_status_tabs.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchMyOrders(forceRefresh: true);
    });
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final orderProvider = context.watch<OrderProvider>();
    final state = orderProvider.myOrdersState;
    final allOrders = state.data ?? [];
    final filtered = OrderStatusTabs.filterOrders(allOrders, _selectedFilter);

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary, size: 20),
            onPressed: _handleBack,
          ),
          title: Text(
            'Đơn hàng của tôi',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              OrderStatusTabs(
                selectedFilter: _selectedFilter,
                allOrders: allOrders,
                onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: state.isLoading && allOrders.isEmpty
                    ? _buildSkeletonList(c)
                    : state.isError && allOrders.isEmpty
                        ? _buildErrorView(state.message ?? 'Đã có lỗi xảy ra')
                        : filtered.isEmpty
                            ? _buildEmptyView()
                            : RefreshIndicator(
                                onRefresh: () => context
                                    .read<OrderProvider>()
                                    .fetchMyOrders(forceRefresh: true),
                                color: c.secondary,
                                backgroundColor: c.surfaceVariant,
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                                  itemBuilder: (_, i) => OrderCard(
                                    order: filtered[i],
                                    onCancelled: () => context
                                        .read<OrderProvider>()
                                        .fetchMyOrders(forceRefresh: true),
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonList(AppColors c) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        height: 140,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: c.border.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final tabLabel = OrderStatusTabs.statusTabs
        .firstWhere((t) => t['id'] == _selectedFilter)['label']!
        .toLowerCase();

    return StatusView(
      icon: Icons.shopping_bag_outlined,
      title: _selectedFilter == 'all'
          ? 'Chưa có đơn hàng nào'
          : 'Không có đơn hàng $tabLabel',
      message: 'Khám phá các sản phẩm thời trang và đặt hàng ngay!',
      actionLabel: 'Mua sắm ngay',
      onAction: () => context.go('/products'),
    );
  }

  Widget _buildErrorView(String msg) {
    return StatusView(
      icon: Icons.error_outline_rounded,
      title: 'Không tải được đơn hàng',
      message: msg,
      danger: true,
      actionLabel: 'Thử lại',
      onAction: () => context.read<OrderProvider>().fetchMyOrders(forceRefresh: true),
    );
  }
}
