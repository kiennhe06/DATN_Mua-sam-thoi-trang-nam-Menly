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

    // Fallback: tính từ danh sách hiện tại
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
