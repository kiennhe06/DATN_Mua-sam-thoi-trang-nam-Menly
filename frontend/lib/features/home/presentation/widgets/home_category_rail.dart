import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/category_pill.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../product/presentation/providers/product_provider.dart';

class HomeCategoryRail extends StatelessWidget {
  final ProductProvider provider;
  const HomeCategoryRail({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return provider.categoriesState.when(
      initial: () => const SizedBox.shrink(),
      loading: () => const _RailSkeleton(height: 46),
      error: (_) => const SizedBox.shrink(),
      success: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: 'Danh mục'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  return CategoryPill(
                    label: cat.name,
                    icon: categoryIcon('${cat.slug} ${cat.name}'),
                    onTap: () => context.go('/products', extra: cat.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RailSkeleton extends StatelessWidget {
  final double height;
  const _RailSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(
          3,
          (_) => Container(
            width: 110,
            height: height,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
          ),
        ),
      ),
    );
  }
}
