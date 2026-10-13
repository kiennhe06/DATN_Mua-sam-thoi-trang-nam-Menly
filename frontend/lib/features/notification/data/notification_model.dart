class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final String type; // 'order' | 'promo' | 'system'
  final Map<String, dynamic> data;
  final bool isRead;
  final String createdAt;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotificationItem.fromJson(Map<String, dynamic> j) {
    return AppNotificationItem(
      id: j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? 'Thông báo',
      body: j['body']?.toString() ?? '',
      type: j['type']?.toString() ?? 'order',
      data: (j['data'] is Map) ? Map<String, dynamic>.from(j['data']) : const {},
      isRead: j['isRead'] == true || j['is_read'] == true || j['read'] == true,
      createdAt: j['createdAt']?.toString() ?? j['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'isRead': isRead,
        'createdAt': createdAt,
      };

  AppNotificationItem copyWith({bool? isRead}) {
    return AppNotificationItem(
      id: id,
      title: title,
      body: body,
      type: type,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
