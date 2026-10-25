import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final DioClient _dioClient;
  List<AppNotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  NotificationProvider({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  List<AppNotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  static final List<AppNotificationItem> _defaultSeedNotifications = [
    AppNotificationItem(
      id: 'demo-notif-1',
      title: 'Đơn hàng #MENLY-8492 đang trên đường giao 🚚',
      body: 'Kiện hàng gồm Áo Sơ Mi Trắng Oxford & Quần Tây Slimfit đang được giao bởi shipper Menly. Dự kiến đến trước 18h hôm nay.',
      type: 'order',
      data: {'orderId': 'ord-mock-01'},
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
    ),
    AppNotificationItem(
      id: 'demo-notif-2',
      title: 'Yêu cầu đổi size đã được phê duyệt 🔄',
      body: 'Menly đã xác nhận đổi sang size L cho Áo Polo Sợi Cafe. Shipper sẽ liên hệ thu hồi và giao size mới tận nơi trong 24-48h.',
      type: 'order',
      data: {'orderId': 'ord-mock-02'},
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    ),
    AppNotificationItem(
      id: 'demo-notif-3',
      title: '⚡ Flash Sale 15:00 đang diễn ra rực lửa!',
      body: 'Giảm sốc đến 45% cho BST Quần Kaki Chino & Áo Polo Thể Thao. Số lượng có hạn, nhanh tay săn ngay!',
      type: 'promo',
      data: {'code': 'FLASHSALE15'},
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
    ),
    AppNotificationItem(
      id: 'demo-notif-4',
      title: 'Tặng anh Voucher MENLY15 giảm 15% 🎁',
      body: 'Ưu đãi giảm 15% khi mua trọn bộ Combo Lookbook (Sơ mi + Quần tây + Blazer). Đã lưu sẵn trong ví voucher của anh.',
      type: 'promo',
      data: {'code': 'MENLY15'},
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    ),
    AppNotificationItem(
      id: 'demo-notif-5',
      title: 'Gợi ý Outfit công sở hôm nay từ Stylist ✨',
      body: 'Thời tiết hôm nay rất thích hợp để mix Áo Sơ Mi Vải Twill cùng Quần Tây Xám Khói tôn vóc dáng lịch lãm.',
      type: 'system',
      data: {'action': 'chat'},
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    ),
  ];

  Future<void> fetchNotifications({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    // 1. Tải cache từ SharedPreferences trước
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('notifications_cache');
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached) as List<dynamic>;
        _notifications = decoded
            .map((e) => AppNotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      } catch (_) {}
    }

    // 2. Fetch từ API Backend
    try {
      final res = await _dioClient.dio.get('/notifications');
      if (res.statusCode == 200 && res.data != null) {
        final list = (res.data['data'] as List<dynamic>?) ?? [];
        if (list.isNotEmpty) {
          _notifications = list
              .map((e) => AppNotificationItem.fromJson(e as Map<String, dynamic>))
              .toList();
          _unreadCount = _notifications.where((n) => !n.isRead).length;
          await prefs.setString(
            'notifications_cache',
            jsonEncode(_notifications.map((n) => n.toJson()).toList()),
          );
        }
      }
    } catch (e) {
      debugPrint('[NotificationProvider] fetch error: $e');
    } finally {
      // Nếu danh sách vẫn rỗng (tài khoản mới hoặc offline), nạp dữ liệu mẫu Menly
      if (_notifications.isEmpty) {
        _notifications = List.from(_defaultSeedNotifications);
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        await prefs.setString(
          'notifications_cache',
          jsonEncode(_notifications.map((n) => n.toJson()).toList()),
        );
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final res = await _dioClient.dio.get('/notifications/unread-count');
      if (res.statusCode == 200 && res.data != null) {
        final count = res.data['data']?['unreadCount'];
        if (count != null) {
          _unreadCount = (count as num).toInt();
          notifyListeners();
          return;
        }
      }
    } catch (_) {}

    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notifications_cache',
        jsonEncode(_notifications.map((n) => n.toJson()).toList()),
      );

      try {
        await _dioClient.dio.patch('/notifications/$id/read');
      } catch (e) {
        debugPrint('[NotificationProvider] mark read error: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notifications_cache',
      jsonEncode(_notifications.map((n) => n.toJson()).toList()),
    );

    try {
      await _dioClient.dio.patch('/notifications/read-all');
    } catch (e) {
      debugPrint('[NotificationProvider] mark all read error: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notifications_cache',
      jsonEncode(_notifications.map((n) => n.toJson()).toList()),
    );

    try {
      await _dioClient.dio.delete('/notifications/$id');
    } catch (e) {
      debugPrint('[NotificationProvider] delete error: $e');
    }
  }
}
