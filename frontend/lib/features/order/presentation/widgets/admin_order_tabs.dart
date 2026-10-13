import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class AdminOrderTabs extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onSelectStatus;
  final List<Map<String, String>> tabs;

  const AdminOrderTabs({
    super.key,
    required this.selectedStatus,
    required this.onSelectStatus,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final tab = tabs[i];
          final isSelected = selectedStatus == tab['id'];
          return GestureDetector(
            onTap: () => onSelectStatus(tab['id']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? c.primary : c.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(
                  color: isSelected ? Colors.transparent : c.border,
                ),
              ),
              child: Center(
                child: Text(
                  tab['label']!,
                  style: TextStyle(
                    color: isSelected ? c.onPrimary : c.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
