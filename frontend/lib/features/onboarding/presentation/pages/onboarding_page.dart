import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../widgets/onboarding_collage.dart';
import '../widgets/onboarding_indicator_dots.dart';

/// First-run onboarding screen, styled after the reference design:
/// a photo collage, a bold headline and the primary "Get Started" CTA.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const _heroImages = [
    'https://images.unsplash.com/photo-1490114538077-0a7f8cb49891?w=600',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600',
    'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600',
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: OnboardingCollage(images: _heroImages)),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 30,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: c.textPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: 'Dễ dàng tiếp cận\n',
                      style: TextStyle(
                        color: c.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const TextSpan(text: 'thời trang nam cao cấp'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Khám phá bộ sưu tập chọn lọc, đặt hàng nhanh gọn và '
                'nhận hàng tận nơi — mua sắm chưa bao giờ dễ đến thế.',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              const OnboardingIndicatorDots(count: 3, active: 0),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Bắt đầu ngay',
                onPressed: () => context.go('/'),
              ),
              const SizedBox(height: 14),
              Center(
                child: GestureDetector(
                  onTap: () => context.push('/login'),
                  child: Text.rich(
                    TextSpan(
                      text: 'Đã có tài khoản? ',
                      style: TextStyle(color: c.textSecondary, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Đăng nhập',
                          style: TextStyle(
                            color: c.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
