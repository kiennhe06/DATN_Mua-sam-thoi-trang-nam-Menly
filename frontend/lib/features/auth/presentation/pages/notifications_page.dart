import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  void _handleTapNotification(AppNotificationItem item) {
    context.read<NotificationProvider>().markAsRead(item.id);

    // Nếu thông báo liên quan đến đơn hàng, mở chi tiết đơn hàng
    final orderId = item.data['orderId']?.toString();
    if (orderId != null && orderId.isNotEmpty) {
      context.push('/orders/$orderId');
    }
  }

  void _confirmClearAll() {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
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

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.notifications;
    final unreadCount = notifProvider.unreadCount;
    final isLoading = notifProvider.isLoading && notifications.isEmpty;

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
          if (notifications.isNotEmpty && unreadCount > 0)
            TextButton(
              onPressed: _confirmClearAll,
              child: Text(
                'Đã đọc tất cả',
                style: TextStyle(color: c.secondary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const LoadingView()
          : notifications.isEmpty
              ? StatusView(
                  icon: Icons.notifications_off_outlined,
                  title: 'Chưa có thông báo nào',
                  message: 'Các cập nhật đơn hàng và chương trình khuyến mãi sẽ hiển thị tại đây',
                )
              : RefreshIndicator(
                  onRefresh: () => notifProvider.fetchNotifications(forceRefresh: true),
                  color: c.secondary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _notificationCard(notifications[i]),
                  ),
                ),
    );
  }

  Widget _notificationCard(AppNotificationItem n) {
    final c = AppColors.of(context);

    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (n.type) {
      case 'order':
        icon = Icons.local_shipping_rounded;
        iconColor = const Color(0xFF3B82F6);
        iconBg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        break;
      case 'promo':
        icon = Icons.discount_rounded;
        iconColor = c.secondary;
        iconBg = c.secondary.withValues(alpha: 0.12);
        break;
      case 'system':
      default:
        icon = Icons.notifications_rounded;
        iconColor = const Color(0xFF8B5CF6);
        iconBg = const Color(0xFF8B5CF6).withValues(alpha: 0.12);
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
                              fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 14,
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formatDate(n.createdAt),
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 11,
                      ),
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
