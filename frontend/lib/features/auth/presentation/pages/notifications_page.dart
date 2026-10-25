import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../notification/data/notification_model.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // 'all' | 'order' | 'promo' | 'system'
  String _selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  void _handleTapNotification(AppNotificationItem item) {
    context.read<NotificationProvider>().markAsRead(item.id);

    // 1. Nếu có orderId -> Mở chi tiết đơn hàng
    final orderId = item.data['orderId']?.toString();
    if (orderId != null && orderId.isNotEmpty) {
      context.push('/orders/$orderId');
      return;
    }

    // 2. Nếu có productId -> Mở chi tiết sản phẩm
    final productId = item.data['productId']?.toString();
    if (productId != null && productId.isNotEmpty) {
      context.push('/products/$productId');
      return;
    }

    // 3. Nếu là khuyến mãi / voucher -> Mở kho voucher
    if (item.type == 'promo' || item.data['code'] != null) {
      context.push('/vouchers');
      return;
    }

    // 4. Nếu là gợi ý stylist hoặc chat -> Mở live chat tư vấn
    if (item.data['action'] == 'chat' || item.type == 'system') {
      context.push('/live-chat');
      return;
    }
  }

  void _confirmClearAll() {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          'Đánh dấu tất cả đã đọc',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có muốn đánh dấu tất cả thông báo là đã đọc không?',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Huỷ', style: TextStyle(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NotificationProvider>().markAllAsRead();
            },
            child: Text(
              'Đồng ý',
              style: TextStyle(color: c.secondary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// Mở bảng cài đặt thông báo (Preferences)
  void _openNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    bool notifOrder = prefs.getBool('setting_notif_order') ?? true;
    bool notifPromo = prefs.getBool('setting_notif_promo') ?? true;
    bool notifStylist = prefs.getBool('setting_notif_stylist') ?? true;
    bool notifSound = prefs.getBool('setting_notif_sound') ?? true;

    if (!mounted) return;
    final c = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cài đặt nhận thông báo',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeColor: c.secondary,
                    title: Text(
                      '📦 Tiến trình đơn hàng & Đổi trả',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Nhận cập nhật khi đơn đóng gói, đang giao hoặc duyệt đổi size',
                      style: TextStyle(color: c.textMuted, fontSize: 11),
                    ),
                    value: notifOrder,
                    onChanged: (val) {
                      setModalState(() => notifOrder = val);
                      prefs.setBool('setting_notif_order', val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeColor: c.secondary,
                    title: Text(
                      '🏷️ Khuyến mãi & Flash Sale',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Nhận thông báo mã giảm giá mới và khung giờ Flash Sale',
                      style: TextStyle(color: c.textMuted, fontSize: 11),
                    ),
                    value: notifPromo,
                    onChanged: (val) {
                      setModalState(() => notifPromo = val);
                      prefs.setBool('setting_notif_promo', val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeColor: c.secondary,
                    title: Text(
                      '✨ Gợi ý phối đồ AI Stylist',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Nhận lời khuyên trang phục theo thời tiết và xu hướng',
                      style: TextStyle(color: c.textMuted, fontSize: 11),
                    ),
                    value: notifStylist,
                    onChanged: (val) {
                      setModalState(() => notifStylist = val);
                      prefs.setBool('setting_notif_stylist', val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeColor: c.secondary,
                    title: Text(
                      '🔔 Âm thanh & Rung',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: notifSound,
                    onChanged: (val) {
                      setModalState(() => notifSound = val);
                      prefs.setBool('setting_notif_sound', val);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final notifProvider = context.watch<NotificationProvider>();
    final allNotifications = notifProvider.notifications;
    final unreadCount = notifProvider.unreadCount;
    final isLoading = notifProvider.isLoading && allNotifications.isEmpty;

    // Lọc danh sách theo Tab đang chọn
    final filteredNotifications = _selectedTab == 'all'
        ? allNotifications
        : allNotifications.where((n) => n.type == _selectedTab).toList();

    // Đếm số lượng chưa đọc theo từng Tab
    final orderUnread =
        allNotifications.where((n) => n.type == 'order' && !n.isRead).length;
    final promoUnread =
        allNotifications.where((n) => n.type == 'promo' && !n.isRead).length;
    final systemUnread =
        allNotifications.where((n) => n.type == 'system' && !n.isRead).length;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Thông báo'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: c.secondary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Text(
                  '$unreadCount mới',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (allNotifications.isNotEmpty && unreadCount > 0)
            TextButton(
              onPressed: _confirmClearAll,
              child: Text(
                'Đã đọc tất cả',
                style: TextStyle(
                  color: c.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20),
            tooltip: 'Cài đặt nhận thông báo',
            onPressed: _openNotificationSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Filter Tabs Bar: Tất cả | Đơn hàng | Khuyến mãi | Stylist
          Container(
            height: 48,
            color: c.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              children: [
                _buildFilterTab(
                  key: 'all',
                  label: 'Tất cả',
                  unreadBadge: unreadCount,
                  c: c,
                ),
                const SizedBox(width: 8),
                _buildFilterTab(
                  key: 'order',
                  label: '📦 Đơn hàng',
                  unreadBadge: orderUnread,
                  c: c,
                ),
                const SizedBox(width: 8),
                _buildFilterTab(
                  key: 'promo',
                  label: '🏷️ Khuyến mãi',
                  unreadBadge: promoUnread,
                  c: c,
                ),
                const SizedBox(width: 8),
                _buildFilterTab(
                  key: 'system',
                  label: '👔 Stylist & Khác',
                  unreadBadge: systemUnread,
                  c: c,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // 2. Nội dung danh sách thông báo
          Expanded(
            child: isLoading
                ? const LoadingView()
                : filteredNotifications.isEmpty
                    ? StatusView(
                        icon: _selectedTab == 'order'
                            ? Icons.local_shipping_outlined
                            : _selectedTab == 'promo'
                                ? Icons.discount_outlined
                                : Icons.notifications_off_outlined,
                        title: _selectedTab == 'order'
                            ? 'Chưa có thông báo đơn hàng'
                            : _selectedTab == 'promo'
                                ? 'Chưa có thông báo khuyến mãi'
                                : 'Chưa có thông báo nào',
                        message: 'Các cập nhật mới nhất sẽ hiển thị tại đây',
                      )
                    : RefreshIndicator(
                        onRefresh: () => notifProvider.fetchNotifications(
                          forceRefresh: true,
                        ),
                        color: c.secondary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: filteredNotifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, i) =>
                              _notificationCard(filteredNotifications[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String key,
    required String label,
    required int unreadBadge,
    required AppColors c,
  }) {
    final isSelected = _selectedTab == key;

    return Pressable(
      onTap: () {
        setState(() {
          _selectedTab = key;
        });
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? c.secondary
              : c.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: isSelected ? Colors.transparent : c.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : c.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (unreadBadge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : c.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadBadge',
                  style: TextStyle(
                    color: isSelected ? c.secondary : Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _notificationCard(AppNotificationItem n) {
    final c = AppColors.of(context);

    IconData icon;
    Color iconColor;
    Color iconBg;
    String actionHint;

    switch (n.type) {
      case 'order':
        icon = Icons.local_shipping_rounded;
        iconColor = const Color(0xFF3B82F6);
        iconBg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        actionHint = 'Xem đơn hàng →';
        break;
      case 'promo':
        icon = Icons.discount_rounded;
        iconColor = c.secondary;
        iconBg = c.secondary.withValues(alpha: 0.12);
        actionHint = 'Săn ưu đãi ngay →';
        break;
      case 'system':
      default:
        icon = Icons.auto_awesome_rounded;
        iconColor = const Color(0xFF8B5CF6);
        iconBg = const Color(0xFF8B5CF6).withValues(alpha: 0.12);
        actionHint = 'Tư vấn Stylist →';
        break;
    }

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: c.danger,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<NotificationProvider>().deleteNotification(n.id);
      },
      child: Pressable(
        onTap: () => _handleTapNotification(n),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: n.isRead ? c.surface : c.surfaceVariant.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: n.isRead
                  ? c.border.withValues(alpha: 0.5)
                  : c.secondary.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight:
                                  n.isRead ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: c.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      n.body,
                      style: TextStyle(
                        color: n.isRead ? c.textMuted : c.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(n.createdAt),
                          style: TextStyle(
                            color: c.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          actionHint,
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} phút trước';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} giờ trước';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} ngày trước';
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {
      return iso;
    }
  }
}
