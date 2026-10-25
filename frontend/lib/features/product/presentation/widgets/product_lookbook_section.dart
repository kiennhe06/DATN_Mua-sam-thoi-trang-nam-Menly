import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/pressable.dart';
import '../../data/models/product_model.dart';

class ProductLookbookSection extends StatefulWidget {
  final Product currentProduct;
  final VoidCallback onBuyLookbook;

  const ProductLookbookSection({
    super.key,
    required this.currentProduct,
    required this.onBuyLookbook,
  });

  @override
  State<ProductLookbookSection> createState() => _ProductLookbookSectionState();
}

class _ProductLookbookSectionState extends State<ProductLookbookSection> {
  int _selectedStyleIndex = 0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final pName = widget.currentProduct.name;
    final isTop = !pName.toLowerCase().contains('quần') &&
        !pName.toLowerCase().contains('giày');

    // Danh sách 4 phong cách phối đồ đa dạng cho phái mạnh
    final List<Map<String, dynamic>> styles = [
      {
        'chip': '🔥 Năng động',
        'title': 'Gợi ý phối đồ Năng động & Trẻ trung',
        'desc': 'Phong cách Casual phóng khoáng, thoải mái cho những buổi dạo phố, cà phê cuối tuần.',
        'item2': isTop ? 'Quần Jean Slimfit Co Giãn 4 Chiều' : 'Áo Thun Cotton Compact Kháng Khuẩn',
        'role2': isTop ? 'Quần jeans năng động' : 'Áo phông basic thoáng mát',
        'item3': 'Giày Sneaker Da Trắng Tối Giản',
        'role3': 'Giày thể thao trẻ trung',
        'item2Price': 420000,
        'item3Price': 680000,
      },
      {
        'chip': '💼 Công sở',
        'title': 'Gợi ý phối đồ Công sở & Hiện đại',
        'desc': 'Phong cách Smart-Casual chỉn chu, chuyên nghiệp mà vẫn giữ trọn vẻ trẻ trung, thoải mái khi làm việc.',
        'item2': isTop ? 'Quần Chinos Co Giãn Tôn Dáng' : 'Áo Polo Dệt Kim Cao Cấp Khí Chất',
        'role2': isTop ? 'Quần kaki chinos thời thượng' : 'Áo polo lịch thiệp',
        'item3': 'Giày Loafer Da Nam Thời Trang',
        'role3': 'Giày lười da tiện lợi',
        'item2Price': 480000,
        'item3Price': 780000,
      },
      {
        'chip': '✨ Lịch lãm',
        'title': 'Gợi ý phối đồ Lịch lãm & Cuốn hút',
        'desc': 'Diện mạo sang trọng, sắc nét tôn dáng cho các buổi gặp gỡ quan trọng, tiệc tối hoặc sự kiện.',
        'item2': isTop ? 'Quần Tây May Đo Chống Nhăn Cao Cấp' : 'Áo Sơ Mi Lụa Dệt Không Nhăn',
        'role2': isTop ? 'Quần âu may đo chuẩn form' : 'Sơ mi cao cấp sắc nét',
        'item3': 'Giày Derby Da Thật Tinh Tế',
        'role3': 'Giày tây sang trọng',
        'item2Price': 550000,
        'item3Price': 890000,
      },
      {
        'chip': '🌿 Tối giản',
        'title': 'Gợi ý phối đồ Tối giản & Tinh tế',
        'desc': 'Phong cách Minimalism mộc mạc, nhẹ nhàng với gam màu trung tính, dễ mặc và không lỗi mốt.',
        'item2': isTop ? 'Quần Khaki Ống Suông Thoải Mái' : 'Áo Sơ Mi Đũi Cổ Tàu Thoáng Mát',
        'role2': isTop ? 'Quần form suông thoải mái' : 'Áo đũi thanh thoát',
        'item3': 'Giày Slip-on Da Lộn Êm Chân',
        'role3': 'Giày lười tối giản',
        'item2Price': 390000,
        'item3Price': 590000,
      },
    ];

    final currentStyle = styles[_selectedStyleIndex];
    final item2 = currentStyle['item2'] as String;
    final role2 = currentStyle['role2'] as String;
    final item3 = currentStyle['item3'] as String;
    final role3 = currentStyle['role3'] as String;

    final comboPrice = widget.currentProduct.price +
        (currentStyle['item2Price'] as int) +
        (currentStyle['item3Price'] as int);
    final discountedComboPrice = (comboPrice * 0.85).round(); // Giảm 15% khi mua cả set

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with tag
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LOOKBOOK',
                  style: TextStyle(
                    color: c.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentStyle['title'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            currentStyle['desc'] as String,
            style: TextStyle(color: c.textMuted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),

          // Style selection chips: Năng động | Công sở | Lịch lãm | Tối giản
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < styles.length; i++) ...[
                  Pressable(
                    onTap: () => setState(() => _selectedStyleIndex = i),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedStyleIndex == i
                            ? c.secondary
                            : c.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusPill),
                        border: Border.all(
                          color: _selectedStyleIndex == i
                              ? c.secondary
                              : c.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        styles[i]['chip'] as String,
                        style: TextStyle(
                          color: _selectedStyleIndex == i
                              ? Colors.white
                              : c.textSecondary,
                          fontSize: 12,
                          fontWeight: _selectedStyleIndex == i
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (i < styles.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3 Lookbook items
          _lookItem(
            context,
            index: '01',
            title: pName,
            role: 'Trang phục bạn đang xem',
            isMain: true,
          ),
          const SizedBox(height: 8),
          _lookItem(
            context,
            index: '02',
            title: item2,
            role: role2,
            isMain: false,
          ),
          const SizedBox(height: 8),
          _lookItem(
            context,
            index: '03',
            title: item3,
            role: role3,
            isMain: false,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Total & Buy Set Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            formatVnd(discountedComboPrice),
                            style: TextStyle(
                              color: c.secondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: c.danger.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '-15%',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Tiết kiệm ${formatVnd(comboPrice - discountedComboPrice)} khi mua cả set',
                        style: TextStyle(color: c.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Pressable(
                  onTap: widget.onBuyLookbook,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: c.inkCard,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Text(
                      'Mua cả set',
                      style: TextStyle(
                        color: c.onInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lookItem(
    BuildContext context, {
    required String index,
    required String title,
    required String role,
    required bool isMain,
  }) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isMain ? c.secondary : c.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            index,
            style: TextStyle(
              color: isMain ? Colors.white : c.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 13,
                  fontWeight: isMain ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              Text(
                role,
                style: TextStyle(color: c.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        if (isMain)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Đang xem',
              style: TextStyle(
                color: c.secondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
