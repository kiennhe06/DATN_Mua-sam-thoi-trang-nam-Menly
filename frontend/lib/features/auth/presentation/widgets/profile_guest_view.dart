import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_buttons.dart';

class ProfileGuestView extends StatelessWidget {
  const ProfileGuestView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: c.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 44,
                color: c.secondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Bạn chưa đăng nhập',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Đăng nhập để theo dõi đơn hàng, quản lý danh sách yêu thích và trải nghiệm mua sắm tốt hơn',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          PrimaryButton(
            label: 'Đăng nhập',
            onPressed: () => context.push('/login'),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: 'Tạo tài khoản',
            onPressed: () => context.push('/register'),
          ),
        ],
      ),
    );
  }
}
