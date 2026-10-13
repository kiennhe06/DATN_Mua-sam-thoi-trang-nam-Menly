import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/order_model.dart';

class OrderStatusTabs extends StatelessWidget {
  final String selectedFilter;
  final List<Order> allOrders;
  final ValueChanged<String> onFilterChanged;

  static const List<Map<String, String>> statusTabs = [
    {'id': 'all', 'label': 'Tất cả'},
    {'id': 'pending_payment', 'label': 'Chờ xác nhận'},
    {'id': 'processing', 'label': 'Đang xử lý'},
    {'id': 'shipping', 'label': 'Đang giao'},
    {'id': 'completed', 'label': 'Hoàn thành'},
    {'id': 'cancelled', 'label': 'Đã huỷ'},
  ];

  const OrderStatusTabs({
    super.key,
    required this.selectedFilter,
    required this.allOrders,
    required this.onFilterChanged,
  });

  static List<Order> filterOrders(List<Order> orders, String filter) {
    if (filter == 'all') return orders;
    if (filter == 'pending_payment') {
      return orders.where((o) => o.status == 'pending_payment' || o.status == 'pending').toList();
    }
    if (filter == 'processing') {
      return orders.where((o) => o.status == 'processing' || o.status == 'paid').toList();
    }
    if (filter == 'shipping') {
      return orders.where((o) => o.status == 'shipping').toList();
    }
    if (filter == 'completed') {
      return orders.where((o) => o.status == 'completed' || o.status == 'delivered').toList();
    }
    if (filter == 'cancelled') {
      return orders.where((o) => o.status == 'cancelled').toList();
    }
    return orders.where((o) => o.status == filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: statusTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final tab = statusTabs[i];
          final tabId = tab['id']!;
          final isSelected = selectedFilter == tabId;
          final count = filterOrders(allOrders, tabId).length;

          return GestureDetector(
            onTap: () => onFilterChanged(tabId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? c.primary : c.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(
                  color: isSelected ? Colors.transparent : c.border,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab['label']!,
                      style: TextStyle(
                        color: isSelected ? c.onPrimary : c.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? c.onPrimary.withValues(alpha: 0.2)
                              : c.border,
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected ? c.onPrimary : c.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
