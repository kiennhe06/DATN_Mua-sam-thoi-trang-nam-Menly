import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';

class SizeAdvisorSheet {
  static const List<String> sizeRanks = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    '2XL',
    '3XL',
  ];

  static Map<String, dynamic> calculateSize({
    required double heightCm,
    required double weightKg,
  }) {
    // 1. Xác định size theo chiều cao
    int heightRank = 0;
    if (heightCm < 160) {
      heightRank = 0; // XS
    } else if (heightCm <= 165) {
      heightRank = 1; // S
    } else if (heightCm <= 169) {
      heightRank = 2; // M
    } else if (heightCm <= 174) {
      heightRank = 3; // L
    } else if (heightCm <= 178) {
      heightRank = 4; // XL
    } else if (heightCm <= 183) {
      heightRank = 5; // 2XL
    } else {
      heightRank = 6; // 3XL
    }

    // 2. Xác định size theo cân nặng
    int weightRank = 0;
    if (weightKg < 50) {
      weightRank = 0; // XS
    } else if (weightKg <= 57) {
      weightRank = 1; // S
    } else if (weightKg <= 65) {
      weightRank = 2; // M
    } else if (weightKg <= 72) {
      weightRank = 3; // L
    } else if (weightKg <= 80) {
      weightRank = 4; // XL
    } else if (weightKg <= 88) {
      weightRank = 5; // 2XL
    } else {
      weightRank = 6; // 3XL
    }

    // Quy tắc: Thuật toán tự động suy ra Size chuẩn và ưu tiên size lớn hơn nếu cân nặng vượt mức
    final finalRank = weightRank > heightRank ? weightRank : heightRank;
    final recommendedSize = sizeRanks[finalRank];

    String advice = '';
    if (weightRank > heightRank) {
      advice =
          'Vóc dáng đậm người, hệ thống ưu tiên tăng 1 size để mặc thoải mái vùng bụng và ngực.';
    } else if (heightRank > weightRank) {
      advice =
          'Vóc dáng cao ráo mảnh khảnh, form dáng Regular-fit tôn chiều cao.';
    } else {
      advice = 'Vóc dáng cân đối chuẩn phong độ phái mạnh, mặc vừa vặn chuẩn size.';
    }

    return {
      'size': recommendedSize,
      'advice': advice,
      'isOverweightAdjusted': weightRank > heightRank,
    };
  }

  static void show({
    required BuildContext context,
    required List<String> availableSizes,
    required ValueChanged<String> onApplySize,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SizeAdvisorModal(
        availableSizes: availableSizes,
        onApplySize: onApplySize,
      ),
    );
  }
}

class _SizeAdvisorModal extends StatefulWidget {
  final List<String> availableSizes;
  final ValueChanged<String> onApplySize;

  const _SizeAdvisorModal({
    required this.availableSizes,
    required this.onApplySize,
  });

  @override
  State<_SizeAdvisorModal> createState() => _SizeAdvisorModalState();
}

class _SizeAdvisorModalState extends State<_SizeAdvisorModal> {
  final _heightCtrl = TextEditingController(text: '172');
  final _weightCtrl = TextEditingController(text: '68');

  String? _recommendedSize;
  String? _advice;
  bool _calculated = false;

  @override
  void initState() {
    super.initState();
    _performCalculation();
  }

  void _performCalculation() {
    final h = double.tryParse(_heightCtrl.text.trim()) ?? 0;
    final w = double.tryParse(_weightCtrl.text.trim()) ?? 0;

    if (h > 100 && w > 30) {
      final res = SizeAdvisorSheet.calculateSize(heightCm: h, weightKg: w);
      setState(() {
        _recommendedSize = res['size'] as String;
        _advice = res['advice'] as String;
        _calculated = true;
      });
    } else {
      setState(() {
        _recommendedSize = null;
        _advice = null;
        _calculated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: c.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(Icons.straighten_rounded, color: c.secondary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tư vấn chọn Size thông minh',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Chuẩn vóc dáng nam giới Việt (XS - 3XL)',
                        style: TextStyle(color: c.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Two input fields: Height and Weight
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chiều cao (cm)',
                          style: TextStyle(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        TextField(
                          controller: _heightCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.only(top: 4),
                          ),
                          onChanged: (_) => _performCalculation(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cân nặng (kg)',
                          style: TextStyle(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        TextField(
                          controller: _weightCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.only(top: 4),
                          ),
                          onChanged: (_) => _performCalculation(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Result presentation
            if (_calculated && _recommendedSize != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: c.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: c.secondary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: c.secondary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _recommendedSize!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Size gợi ý phù hợp nhất: $_recommendedSize',
                            style: TextStyle(
                              color: c.secondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _advice ?? '',
                            style: TextStyle(color: c.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Action button
            PrimaryButton(
              label: _recommendedSize != null
                  ? 'Áp dụng Size $_recommendedSize cho sản phẩm'
                  : 'Kiểm tra Size',
              onPressed: _recommendedSize != null
                  ? () {
                      widget.onApplySize(_recommendedSize!);
                      Navigator.pop(context);
                    }
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
