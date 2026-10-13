import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ProductStockBadge extends StatelessWidget {
  final int stock;
  const ProductStockBadge({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final inStock = stock > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: (inStock ? c.success : c.danger).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        inStock ? 'Còn $stock sản phẩm' : 'Hết hàng',
        style: TextStyle(
          color: inStock ? c.success : c.danger,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ProductOptionRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const ProductOptionRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final o in options)
          GestureDetector(
            onTap: () => onSelect(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: o == selected ? c.inkCard : c.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                o,
                style: TextStyle(
                  color: o == selected ? c.onInk : c.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ProductQtyStepper extends StatelessWidget {
  final int qty;
  final int max;
  final ValueChanged<int> onChanged;

  const ProductQtyStepper({
    super.key,
    required this.qty,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget btn(IconData icon, VoidCallback? onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: c.textPrimary),
          ),
        );
    return Row(
      children: [
        btn(Icons.remove_rounded, qty > 1 ? () => onChanged(qty - 1) : null),
        SizedBox(
          width: 48,
          child: Center(
            child: Text(
              '$qty',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        btn(
          Icons.add_rounded,
          (max <= 0 || qty < max) ? () => onChanged(qty + 1) : null,
        ),
      ],
    );
  }
}
