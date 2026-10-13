import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../data/models/review_model.dart';

class ProductReviewsSection extends StatelessWidget {
  final String productId;
  final List<Review> reviews;
  final bool isLoading;
  final VoidCallback onReviewSubmitted;

  const ProductReviewsSection({
    super.key,
    required this.productId,
    required this.reviews,
    required this.isLoading,
    required this.onReviewSubmitted,
  });

  void _showCannotReviewDialog(BuildContext context, AppColors c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.shopping_bag_outlined, color: Colors.orange[700], size: 28),
            const SizedBox(width: 10),
            Text(
              'Chưa thể đánh giá',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn phải mua hàng thành công sản phẩm này thì mới có thể gửi đánh giá. Hãy đặt hàng và trải nghiệm sản phẩm trước nhé!',
          style: TextStyle(color: c.textSecondary, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Đã hiểu',
              style: TextStyle(color: c.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndShowReviewForm(BuildContext context, AppColors c) async {
    if (!AuthGuard.check(
      context,
      redirectPath: '/products/$productId',
    )) {
      return;
    }

    try {
      final res = await DioClient.instance.dio.get(
        '/reviews/can-review/$productId',
      );
      final canReview = res.data?['data']?['canReview'] == true;
      if (!canReview) {
        if (context.mounted) {
          _showCannotReviewDialog(context, c);
        }
        return;
      }
    } catch (_) {
      // Nếu có lỗi mạng hoặc API tạm thời thì vẫn cho mở form, backend sẽ kiểm tra khi submit
    }

    if (context.mounted) {
      _showReviewForm(context, c);
    }
  }

  Future<void> _submitReview(
    BuildContext context,
    int rating,
    String comment,
    AppColors c,
  ) async {
    if (!AuthGuard.check(
      context,
      redirectPath: '/products/$productId',
    )) {
      return;
    }
    try {
      final res = await DioClient.instance.dio.post(
        '/reviews/$productId',
        data: {'rating': rating, 'comment': comment},
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        if (context.mounted) {
          Navigator.of(context).pop();
          onReviewSubmitted();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đánh giá thành công! Cảm ơn bạn.'),
              backgroundColor: c.success,
              duration: const Duration(milliseconds: 1500),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        String msg = 'Lỗi gửi đánh giá';
        bool cannotReview = false;
        if (e is DioException) {
          final errCode = e.response?.data?['error']?['code'] ?? '';
          final errMsg =
              e.response?.data?['error']?['message'] ??
              e.response?.data?['message'];
          if (e.response?.statusCode == 403 ||
              errCode == 'CANNOT_REVIEW' ||
              (errMsg != null && errMsg.toString().contains('mua hàng'))) {
            cannotReview = true;
            msg = 'Bạn phải mua hàng thành công sản phẩm này thì mới có thể đánh giá.';
          } else if (errMsg != null) {
            msg = errMsg.toString();
          }
        }

        if (cannotReview) {
          Navigator.of(context).pop();
          _showCannotReviewDialog(context, c);
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: c.danger,
              duration: const Duration(milliseconds: 1500),
            ),
          );
        }
      }
    }
  }

  void _showReviewForm(BuildContext context, AppColors c) {
    if (!AuthGuard.check(
      context,
      redirectPath: '/products/$productId',
    )) {
      return;
    }
    int selectedRating = 5;
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Đánh giá sản phẩm',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return IconButton(
                      icon: Icon(
                        star <= selectedRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: star <= selectedRating ? c.primary : c.textMuted,
                        size: 36,
                      ),
                      onPressed: () {
                        setModalState(() => selectedRating = star);
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Nhận xét của bạn về sản phẩm này...',
                  hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: c.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(color: c.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Gửi đánh giá',
                  onPressed: () {
                    final comment = commentCtrl.text.trim();
                    _submitReview(context, selectedRating, comment, c);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đánh giá & Nhận xét (${reviews.length})',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: () => _checkAndShowReviewForm(context, c),
              icon: Icon(
                Icons.rate_review_outlined,
                color: c.secondary,
                size: 16,
              ),
              label: Text(
                'Viết đánh giá',
                style: TextStyle(
                  color: c.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: c.primary,
                strokeWidth: 2,
              ),
            ),
          )
        else if (reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Chưa có đánh giá nào cho sản phẩm này.',
              style: TextStyle(color: c.textMuted, fontSize: 13),
            ),
          )
        else
          ...reviews.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: c.primary.withValues(alpha: 0.15),
                        child: Text(
                          r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: c.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.userName,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: i < r.rating ? c.secondary : c.border,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((r.comment ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      r.comment!,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
