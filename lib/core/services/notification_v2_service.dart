import 'package:kaki_empat/core/services/v2_api_client.dart';

class AppNotificationV2 {
  const AppNotificationV2({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.bookingId,
    this.type = 'general',
    this.createdAt = '',
  });

  final String id;
  final String title;
  final String message;
  final bool isRead;
  final String? bookingId;
  final String type;
  final String createdAt;

  factory AppNotificationV2.fromJson(Map<String, dynamic> json) {
    return AppNotificationV2(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      message: '${json['message'] ?? ''}',
      isRead: json['is_read'] == true,
      bookingId: json['booking_id']?.toString(),
      type: '${json['type'] ?? 'general'}',
      createdAt: '${json['created_at'] ?? ''}',
    );
  }
}

class NotificationPageResult {
  const NotificationPageResult({
    required this.notifications,
    required this.page,
    required this.total,
    required this.unreadCount,
    required this.hasMore,
  });

  final List<AppNotificationV2> notifications;
  final int page;
  final int total;
  final int unreadCount;
  final bool hasMore;

  factory NotificationPageResult.fromJson(Map<String, dynamic> json) {
    final raw = json['notifications'];
    return NotificationPageResult(
      notifications: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(AppNotificationV2.fromJson)
              .toList()
          : const [],
      page: (json['page'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? 0,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      hasMore: json['has_more'] == true,
    );
  }
}

class NotificationV2Service {
  NotificationV2Service({V2ApiClient? client})
      : _api = client ?? V2ApiClient.instance;

  static final NotificationV2Service instance = NotificationV2Service();

  final V2ApiClient _api;
  static const _script = 'notification_v2.php';

  Future<int> checkNew() async {
    final response = await _api.getAuth(_script, action: 'check_new');
    return _api.parse(
      response,
      (body) => (body['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<NotificationPageResult> getNotifications({
    int page = 1,
    int limit = 20,
    String? typeFilter,
  }) async {
    final response = await _api.getAuth(
      _script,
      action: 'get_notifications',
      query: {
        'page': '$page',
        'limit': '$limit',
        if (typeFilter != null && typeFilter.isNotEmpty) 'type': typeFilter,
      },
    );
    return _api.parse(response, NotificationPageResult.fromJson);
  }

  Future<void> markRead({String? notificationId, bool markAll = false}) async {
    final response = await _api.postAuth(
      _script,
      action: 'mark_read',
      body: {
        if (markAll) 'mark_all': true,
        if (!markAll && notificationId != null)
          'notification_id': notificationId,
      },
    );
    await _api.parse<void>(response, (_) {});
  }

  /// Ambil halaman pertama yang belum dibaca, lalu tandai dibaca.
  Future<List<AppNotificationV2>> pollUnreadBatch() async {
    final unread = await checkNew();
    if (unread < 1) return [];

    final page = await getNotifications(limit: unread.clamp(1, 50));
    final items = page.notifications.where((n) => !n.isRead).toList();
    if (items.isEmpty) return [];

    await markRead(markAll: true);
    return items;
  }
}
