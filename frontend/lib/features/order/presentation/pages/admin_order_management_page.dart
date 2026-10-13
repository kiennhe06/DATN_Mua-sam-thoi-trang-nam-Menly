import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/order_model.dart';
import '../providers/order_provider.dart';
import '../widgets/admin_order_card.dart';
import '../widgets/admin_order_status_sheet.dart';
import '../widgets/admin_order_tabs.dart';

class AdminOrderManagementPage extends StatefulWidget {
  const AdminOrderManagementPage({super.key});

  @override
  State<AdminOrderManagementPage> createState() =>
      _AdminOrderManagementPageState();
}

class _AdminOrderManagementPageState extends State<AdminOrderManagementPage> {
  String _selectedStatus = 'all';

  final List<Map<String, String>> _statusTabs = const [
    {'id': 'all', 'label': 'Tất cả'},
    {'id': 'pending_payment', 'label': 'Chờ xác nhận'},
    {'id': 'processing', 'label': 'Đang xử lý'},
    {'id': 'shipping', 'label': 'Đang giao'},
    {'id': 'completed', 'label': 'Hoàn thành'},
    {'id': 'cancelled', 'label': 'Đã huỷ'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchAdminOrders(forceRefresh: true);
    });
  }

  void _onSelectTab(String status) {
    setState(() => _selectedStatus = status);
  }

  List<Order> _getFilteredOrders(List<Order> orders) {
    if (_selectedStatus == 'all') return orders;
    return orders.where((o) => o.status == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final state = orderProvider.adminOrdersState;
    final allOrders = state.data ?? [];
    final filtered = _getFilteredOrders(allOrders);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: c.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý đơn hàng',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              auth.user?.isAdmin == true
                  ? 'Quyền Quản trị viên (Toàn quyền)'
                  : 'Quyền Nhân viên (Vận hành)',
              style: TextStyle(
                color: auth.user?.isAdmin == true
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF3B82F6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: c.textPrimary),
            onPressed: () => context.read<OrderProvider>().fetchAdminOrders(
              forceRefresh: true,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            AdminOrderTabs(
              selectedStatus: _selectedStatus,
              onSelectStatus: _onSelectTab,
              tabs: _statusTabs,
            ),
            const SizedBox(height: 8),

            // Orders list
            Expanded(
              child: state.isLoading && allOrders.isEmpty
                  ? const LoadingView(message: 'Đang tải đơn hàng...')
                  : state.isError && allOrders.isEmpty
                  ? StatusView(
                      icon: Icons.error_outline_rounded,
                      title: 'Không tải được đơn hàng',
                      message: state.message ?? 'Đã có lỗi xảy ra',
                      danger: true,
                      actionLabel: 'Thử lại',
                      onAction: () => context
                          .read<OrderProvider>()
                          .fetchAdminOrders(forceRefresh: true),
                    )
                  : filtered.isEmpty
                  ? const StatusView(
                      icon: Icons.inbox_rounded,
                      title: 'Không có đơn hàng nào',
                    )
                  : RefreshIndicator(
                      onRefresh: () => context
                          .read<OrderProvider>()
                          .fetchAdminOrders(forceRefresh: true),
                      color: c.secondary,
                      backgroundColor: c.surfaceVariant,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 14),
                        itemBuilder: (_, i) => AdminOrderCard(
                          order: filtered[i],
                          onUpdateStatus: () =>
                              AdminOrderStatusSheet.show(context, filtered[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
