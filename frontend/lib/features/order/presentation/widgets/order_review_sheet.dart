import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../data/order_model.dart';

class OrderReviewSheet {
  static Future<String?> resolveProductId(OrderItem item) async {
    if (item.productId != null && item.productId!.isNotEmpty) {
      return item.productId;
    }
    try {
      final res = await DioClient.instance.dio.get(
        '/products',
        queryParameters: {'search': item.productName, 'limit': 1},
      );
      final data = res.data;
      final items = data['data']?['items'] ?? data['items'] ?? [];
      if (items is List && items.isNotEmpty) {
        return items[0]['id']?.toString();
      }
    } catch (_) {}
    return null;
  }

  static void show(BuildContext context, Order order) {
    if (order.items.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đơn hàng không có sản phẩm nào để đánh giá'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    if (order.items.length == 1) {
      showProductReviewForm(context, order.items.first);
      return;
    }

    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
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
              Row(
                children: [
                  Icon(Icons.rate_review_outlined, color: c.secondary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Đánh giá đơn hàng #${order.code}',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Chọn sản phẩm bạn muốn viết đánh giá:',
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: order.items.length,
                  separatorBuilder: (_, __) => Divider(color: c.surfaceVariant, height: 1),
                  itemBuilder: (_, i) {
                    final item = order.items[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      title: Text(
                        item.productName,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Phân loại: ${item.size.isNotEmpty ? item.size : "Tiêu chuẩn"}${item.color.isNotEmpty ? " - ${item.color}" : ""}',
                        style: TextStyle(color: c.textMuted, fontSize: 12),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary,
                          foregroundColor: c.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          showProductReviewForm(context, item);
                        },
                        child: const Text('Đánh giá', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showProductReviewForm(BuildContext context, OrderItem item) {
    final c = AppColors.of(context);
    int selectedRating = 5;
    final commentCtrl = TextEditingController();
    bool isSubmitting = false;

    const ratingLabels = [
      'Rất tệ',
      'Không hài lòng',
      'Bình thường',
      'Hài lòng',
      'Rất tuyệt vời',
    ];

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
              Row(
                children: [
                  Icon(Icons.stars_rounded, color: c.secondary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Đánh giá sản phẩm',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: c.secondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.size.isNotEmpty || item.color.isNotEmpty)
                            Text(
                              'Phân loại: ${item.size}${item.color.isNotEmpty ? ", ${item.color}" : ""}',
                              style: TextStyle(color: c.textMuted, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        return IconButton(
                          icon: Icon(
                            star <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: star <= selectedRating
                                ? const Color(0xFFF59E0B)
                                : c.textMuted,
                            size: 38,
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () => setModalState(() => selectedRating = star),
                        );
                      }),
                    ),
                    Text(
                      ratingLabels[selectedRating - 1],
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Chia sẻ cảm nhận của bạn về sản phẩm, chất vải, độ vừa vặn...',
                  hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
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
                  label: isSubmitting ? 'Đang gửi...' : 'Gửi đánh giá',
                  icon: isSubmitting ? null : Icons.send_rounded,
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final comment = commentCtrl.text.trim();
                          setModalState(() => isSubmitting = true);

                          final pid = await resolveProductId(item);
                          if (pid == null || pid.isEmpty) {
                            setModalState(() => isSubmitting = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Không tìm thấy thông tin sản phẩm để gửi đánh giá'),
                                  duration: Duration(milliseconds: 1500),
                                ),
                              );
                            }
                            return;
                          }

                          try {
                            final res = await DioClient.instance.dio.post(
                              '/reviews/$pid',
                              data: {
                                'rating': selectedRating,
                                'comment': comment,
                              },
                            );

                            if (res.statusCode == 201 || res.statusCode == 200) {
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                              }
                              messenger.hideCurrentSnackBar();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text('Đánh giá sản phẩm thành công! Cảm ơn bạn.'),
                                  backgroundColor: c.success,
                                  duration: const Duration(milliseconds: 1500),
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (ctx.mounted) {
                              String msg = 'Lỗi gửi đánh giá';
                              if (e is DioException) {
                                final errCode = e.response?.data?['error']?['code'] ?? '';
                                final errMsg = e.response?.data?['error']?['message'] ??
                                    e.response?.data?['message'];
                                if (e.response?.statusCode == 403 ||
                                    errCode == 'CANNOT_REVIEW' ||
                                    (errMsg != null && errMsg.toString().contains('mua hàng'))) {
                                  msg = 'Bạn phải mua hàng thành công sản phẩm này thì mới có thể đánh giá.';
                                } else if (errMsg != null) {
                                  msg = errMsg.toString();
                                }
                              }
                              ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                  backgroundColor: c.danger,
                                  duration: const Duration(milliseconds: 1500),
                                ),
                              );
                            }
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
