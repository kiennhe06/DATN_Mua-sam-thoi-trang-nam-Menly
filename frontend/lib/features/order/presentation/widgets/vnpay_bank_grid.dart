import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/vnpay_bank_model.dart';
import '../controllers/vnpay_payment_controller.dart';

class VNPayBankGrid extends StatelessWidget {
  final VNPayPaymentController controller;

  const VNPayBankGrid({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final banks = controller.filteredBanks;

    final tabs = [
      {'id': VNPayPaymentCategory.all, 'label': 'Tất cả'},
      {'id': VNPayPaymentCategory.atm, 'label': 'Thẻ ATM / Nội địa'},
      {'id': VNPayPaymentCategory.qr, 'label': 'VNPAY-QR'},
      {'id': VNPayPaymentCategory.intl, 'label': 'Thẻ Quốc tế'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Danh mục ngân hàng
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: tabs.map((t) {
              final cat = t['id'] as VNPayPaymentCategory;
              final isSelected = controller.selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    t['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : c.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF005BAA),
                  backgroundColor: c.surfaceVariant,
                  showCheckmark: false,
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF005BAA) : c.border,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (val) {
                    if (val) controller.setSelectedCategory(cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Ô tìm kiếm ngân hàng
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: TextField(
            controller: controller.searchCtrl,
            style: TextStyle(color: c.textPrimary, fontSize: 13),
            onChanged: (val) => controller.setSearchQuery(val.trim()),
            decoration: InputDecoration(
              hintText: 'Tìm ngân hàng (NCB, Vietcombank, BIDV, ...)',
              hintStyle: TextStyle(color: c.textMuted, fontSize: 12),
              prefixIcon: Icon(Icons.search_rounded, color: c.textMuted, size: 18),
              suffixIcon: controller.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        controller.searchCtrl.clear();
                        controller.setSearchQuery('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Header danh sách
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Chọn ngân hàng / phương thức (${banks.length})',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (controller.selectedBank.isSandboxRecommended) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF005BAA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF005BAA).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF005BAA), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Thẻ Sandbox NCB',
                      style: TextStyle(color: Color(0xFF005BAA), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Lưới ngân hàng
        if (banks.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, color: c.textMuted, size: 36),
                const SizedBox(height: 8),
                Text(
                  'Không tìm thấy ngân hàng phù hợp',
                  style: TextStyle(color: c.textMuted, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: banks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              final bank = banks[index];
              final isSelected = controller.selectedBank.code == bank.code;

              return InkWell(
                onTap: () => controller.setSelectedBank(bank),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF005BAA).withValues(alpha: 0.08) : c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF005BAA) : c.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: bank.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(bank.icon, color: bank.primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    bank.name,
                                    style: TextStyle(
                                      color: c.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (bank.isSandboxRecommended) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Khuyên dùng Demo',
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bank.fullName,
                              style: TextStyle(color: c.textMuted, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: bank.code,
                        groupValue: controller.selectedBank.code,
                        activeColor: const Color(0xFF005BAA),
                        onChanged: (val) {
                          if (val != null) controller.setSelectedBank(bank);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
