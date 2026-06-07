import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kaki_empat/core/config/app_config.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';

class EventNotificationSnapshot {
  const EventNotificationSnapshot({
    required this.unread,
    this.message,
    this.title,
    this.bookingId,
    this.notificationId,
    this.timestamp,
    this.type,
  });

  final bool unread;
  final String? message;
  final String? title;
  final String? bookingId;
  final String? notificationId;
  final int? timestamp;
  final String? type;

  bool get hasContent =>
      (message != null && message!.isNotEmpty) ||
      (title != null && title!.isNotEmpty);

  factory EventNotificationSnapshot.empty() {
    return const EventNotificationSnapshot(unread: false);
  }

  factory EventNotificationSnapshot.fromJson(Map<String, dynamic> json) {
    final unread = json['unread'] == true;
    if (!unread && json['message'] == 'No new notifications') {
      return EventNotificationSnapshot.empty();
    }
    return EventNotificationSnapshot(
      unread: unread,
      message: json['message'] as String?,
      title: json['title'] as String?,
      bookingId: json['booking_id']?.toString(),
      notificationId: json['notification_id']?.toString(),
      timestamp: json['timestamp'] is int
          ? json['timestamp'] as int
          : int.tryParse('${json['timestamp'] ?? ''}'),
      type: json['type'] as String?,
    );
  }
}

class EventNotificationService {
  EventNotificationService({http.Client? client}) : _client = client ?? http.Client();

  static final EventNotificationService instance = EventNotificationService();

  final http.Client _client;

  String get _url => '${AppConfig.apiBaseUrl}/get_notifications.php';

  Future<EventNotificationSnapshot> poll({bool markRead = false}) async {
    final token = await AuthServiceV2.instance.getToken();
    if (token == null || token.isEmpty) {
      return EventNotificationSnapshot.empty();
    }

    final user = await AuthServiceV2.instance.getStoredUser();
    final query = <String, String>{
      if (user != null) 'user_id': '${user.id}',
      if (markRead) 'mark_read': '1',
    };

    final uri = Uri.parse(_url).replace(queryParameters: query);
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return EventNotificationSnapshot.empty();
    }

    if (response.statusCode >= 400 || body['ok'] != true) {
      return EventNotificationSnapshot.empty();
    }

    return EventNotificationSnapshot.fromJson(body);
  }

  String get _unreadUrl => '${AppConfig.apiBaseUrl}/get_unread_notifications.php';

  /// Polling batch: server auto-mark is_read setelah data dikirim.
  Future<List<LocalNotificationItem>> pollUnreadBatch({int? userId}) async {
    final token = await AuthServiceV2.instance.getToken();
    if (token == null || token.isEmpty) {
      return [];
    }

    final user = await AuthServiceV2.instance.getStoredUser();
    final uid = userId ?? user?.id;
    if (uid == null) return [];

    final uri = Uri.parse(_unreadUrl).replace(
      queryParameters: {'user_id': '$uid'},
    );
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return [];
    }

    if (response.statusCode >= 400 || body['ok'] != true) {
      return [];
    }

    final raw = body['data'];
    if (raw is! List) return [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(LocalNotificationItem.fromJson)
        .toList();
  }
}

class LocalNotificationItem {
  const LocalNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.bookingId,
    this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String? bookingId;
  final String? createdAt;

  factory LocalNotificationItem.fromJson(Map<String, dynamic> json) {
    return LocalNotificationItem(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? 'Notification'}',
      message: '${json['message'] ?? ''}',
      bookingId: json['booking_id']?.toString(),
      createdAt: json['created_at'] as String?,
    );
  }
}
