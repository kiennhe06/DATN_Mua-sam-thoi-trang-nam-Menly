import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../product/data/models/product_model.dart';

class FlashSaleSlot {
  final int hour;
  final String label;

  const FlashSaleSlot(this.hour, this.label);
}

class HomeFlashSaleSection extends StatefulWidget {
  final List<Product> products;

  const HomeFlashSaleSection({super.key, required this.products});

  @override
  State<HomeFlashSaleSection> createState() => _HomeFlashSaleSectionState();
}

class _HomeFlashSaleSectionState extends State<HomeFlashSaleSection> {
  static const List<FlashSaleSlot> _slots = [
    FlashSaleSlot(0, '00:00'),
    FlashSaleSlot(9, '09:00'),
    FlashSaleSlot(12, '12:00'),
    FlashSaleSlot(15, '15:00'),
    FlashSaleSlot(18, '18:00'),
    FlashSaleSlot(21, '21:00'),
  ];

  late int _activeSlotIndex;
  late int _selectedSlotIndex;
  late final ScrollController _slotScrollController;
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _slotScrollController = ScrollController();
    _activeSlotIndex = _calculateCurrentActiveSlot();
    _selectedSlotIndex = _activeSlotIndex;
    _updateRemainingTime();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveSlot();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final oldActive = _activeSlotIndex;
      _updateRemainingTime();

      // Nếu vừa bước sang khung giờ mới khi khách đang mở app (ví dụ 8h59 -> 9h00)
      if (oldActive != _activeSlotIndex && _selectedSlotIndex == oldActive) {
        setState(() {
          _selectedSlotIndex = _activeSlotIndex;
        });
        _scrollToActiveSlot();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _slotScrollController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _scrollToActiveSlot() {
    if (!_slotScrollController.hasClients) return;
    // Mỗi slot rộng 88px + khoảng cách 8px = 96px
    const itemWidth = 96.0;
    final targetOffset = (_selectedSlotIndex * itemWidth) - 30.0;
    _slotScrollController.animateTo(
      targetOffset.clamp(0.0, _slotScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  /// Tính toán khung giờ hiện tại đang diễn ra dựa theo đồng hồ thực tế
  int _calculateCurrentActiveSlot() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour < 9) return 0; // 00:00 - 09:00
    if (hour < 12) return 1; // 09:00 - 12:00
    if (hour < 15) return 2; // 12:00 - 15:00
    if (hour < 18) return 3; // 15:00 - 18:00
    if (hour < 21) return 4; // 18:00 - 21:00
    return 5; // 21:00 - 24:00 (00:00)
  }

  /// Cập nhật thời gian đếm ngược chính xác theo khung giờ đang chọn
  void _updateRemainingTime() {
    final now = DateTime.now();
    _activeSlotIndex = _calculateCurrentActiveSlot();

    if (_selectedSlotIndex == _activeSlotIndex) {
      // Đang xem khung giờ đang sale -> Đếm ngược đến khi kết thúc slot này
      int nextSlotHour;
      if (_selectedSlotIndex == 5) {
        nextSlotHour = 24; // Hết ngày lúc 24h/0h
      } else {
        nextSlotHour = _slots[_selectedSlotIndex + 1].hour;
      }
      final endTarget = DateTime(now.year, now.month, now.day, nextSlotHour, 0, 0);
      _timeLeft = endTarget.difference(now);
      if (_timeLeft.isNegative) _timeLeft = Duration.zero;
    } else if (_selectedSlotIndex > _activeSlotIndex) {
      // Đang xem khung giờ tương lai -> Đếm ngược đến thời điểm mở bán
      final targetHour = _slots[_selectedSlotIndex].hour;
      final startTarget = DateTime(now.year, now.month, now.day, targetHour, 0, 0);
      _timeLeft = startTarget.difference(now);
      if (_timeLeft.isNegative) _timeLeft = Duration.zero;
    } else {
      // Khung giờ quá khứ đã kết thúc
      _timeLeft = Duration.zero;
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _getSlotStatusText(int index) {
    if (index == _activeSlotIndex) return 'Đang diễn ra';
    if (index > _activeSlotIndex) return 'Sắp diễn ra';
    return 'Đã kết thúc';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();

    final c = AppColors.of(context);

    // Phân bổ 6 sản phẩm khác nhau cho từng khung giờ
    final startIndex = (_selectedSlotIndex * 6) % widget.products.length;
    List<Product> flashProducts = widget.products.skip(startIndex).take(6).toList();
    if (flashProducts.length < 6) {
      flashProducts = widget.products.take(6).toList();
    }

    final isLive = _selectedSlotIndex == _activeSlotIndex;
    final isUpcoming = _selectedSlotIndex > _activeSlotIndex;
    final isEnded = _selectedSlotIndex < _activeSlotIndex;

    final hours = _twoDigits(_timeLeft.inHours);
    final minutes = _twoDigits(_timeLeft.inMinutes.remainder(60));
    final seconds = _twoDigits(_timeLeft.inSeconds.remainder(60));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Tiêu đề + Countdown Timer + Nút Xem tất cả
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE11D48), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '⚡ FLASH SALE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              if (isLive) ...[
                _timerBox(hours, c),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text(':', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ),
                _timerBox(minutes, c),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text(':', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ),
                _timerBox(seconds, c),
              ] else if (isUpcoming) ...[
                Text(
                  'Bắt đầu sau: $hours:$minutes:$seconds',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else ...[
                Text(
                  'Đã kết thúc',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],

              const Spacer(),
              Pressable(
                onTap: () => context.go('/products'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: c.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Timeline Bar: Danh sách 6 khung giờ (0h, 9h, 12h, 15h, 18h, 21h)
          SizedBox(
            height: 52,
            child: ListView.separated(
              controller: _slotScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _slots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final slot = _slots[index];
                final isSelected = index == _selectedSlotIndex;
                final isSlotLive = index == _activeSlotIndex;
                final statusText = _getSlotStatusText(index);

                Color bgColor;
                Color textColor;
                Color statusColor;

                if (isSelected) {
                  bgColor = isSlotLive ? c.danger : c.secondary;
                  textColor = Colors.white;
                  statusColor = Colors.white.withValues(alpha: 0.9);
                } else {
                  bgColor = c.surfaceVariant.withValues(alpha: 0.5);
                  textColor = c.textPrimary;
                  statusColor = isSlotLive ? c.danger : c.textMuted;
                }

                return Pressable(
                  onTap: () {
                    setState(() {
                      _selectedSlotIndex = index;
                      _updateRemainingTime();
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 88,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : isSlotLive
                                ? c.danger.withValues(alpha: 0.6)
                                : c.border.withValues(alpha: 0.6),
                        width: isSlotLive && !isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slot.label,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9.5,
                            fontWeight: isSelected || isSlotLive
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Danh sách sản phẩm tương ứng khung giờ
          SizedBox(
            height: 262,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 2),
              itemCount: flashProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, index) {
                final p = flashProducts[index];
                final discountPct = 25 + ((index + _selectedSlotIndex) * 5) % 25; // 25% - 45%
                final originalPrice = (p.price / (1 - (discountPct / 100))).round();
                final soldPercent = isLive
                    ? (0.50 + ((index * 13) % 45) / 100)
                    : isEnded
                        ? 1.0
                        : 0.0;

                return Pressable(
                  onTap: () => context.push('/products/${p.id}'),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: Container(
                    width: 148,
                    decoration: BoxDecoration(
                      color: c.surfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: c.border.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ảnh sản phẩm với nhãn giảm giá
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppTheme.radiusLg),
                              ),
                              child: AspectRatio(
                                aspectRatio: 1.04,
                                child: p.imageUrl.isNotEmpty
                                    ? Image.network(
                                        p.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: c.surfaceVariant,
                                          child: Icon(Icons.image_outlined, color: c.textMuted),
                                        ),
                                      )
                                    : Container(
                                        color: c.surfaceVariant,
                                        child: Icon(Icons.image_outlined, color: c.textMuted),
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.danger,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-$discountPct%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Thông tin giá & Tiến trình bán
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatVnd(p.price),
                                style: TextStyle(
                                  color: c.secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                formatVnd(originalPrice),
                                style: TextStyle(
                                  color: c.textMuted,
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(height: 6),

                              if (isLive) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: soldPercent,
                                    minHeight: 5,
                                    backgroundColor: c.border,
                                    valueColor: AlwaysStoppedAnimation<Color>(c.danger),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '🔥 Đã bán ${(soldPercent * 100).toInt()}%',
                                  style: TextStyle(
                                    color: c.danger,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ] else if (isUpcoming) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: c.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.notifications_active_outlined, size: 12, color: c.secondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Nhắc tôi',
                                        style: TextStyle(
                                          color: c.secondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: c.surfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Đã kết thúc',
                                    style: TextStyle(
                                      color: c.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _timerBox(String val, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: c.inkCard,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        val,
        style: TextStyle(
          color: c.onInk,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
