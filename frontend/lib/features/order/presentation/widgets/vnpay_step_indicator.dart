import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class VNPayStepIndicator extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStepChanged;

  const VNPayStepIndicator({
    super.key,
    required this.currentStep,
    required this.onStepChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          // Bước 1: Chọn ngân hàng
          InkWell(
            onTap: () => onStepChanged(0),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: currentStep == 0
                          ? const Color(0xFF005BAA)
                          : const Color(0xFF005BAA).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: currentStep > 0
                        ? const Icon(Icons.check_rounded, color: Color(0xFF005BAA), size: 14)
                        : const Text(
                            '1',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chọn ngân hàng',
                    style: TextStyle(
                      color: currentStep == 0 ? const Color(0xFF005BAA) : c.textSecondary,
                      fontSize: 12,
                      fontWeight: currentStep == 0 ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Đường nối
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: currentStep > 0 ? const Color(0xFF005BAA) : c.border,
            ),
          ),

          // Bước 2: Nhập thông tin
          InkWell(
            onTap: () => onStepChanged(1),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: currentStep == 1
                          ? const Color(0xFF005BAA)
                          : c.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: currentStep == 1 ? Colors.white : c.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nhập thông tin thẻ',
                    style: TextStyle(
                      color: currentStep == 1 ? const Color(0xFF005BAA) : c.textMuted,
                      fontSize: 12,
                      fontWeight: currentStep == 1 ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
