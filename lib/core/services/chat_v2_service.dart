import 'package:kaki_empat/core/services/v2_api_client.dart';

class ChatMessageV2 {
  const ChatMessageV2({
    required this.id,
    required this.bookingId,
    required this.text,
    required this.createdAt,
    this.senderUserId,
  });

  final String id;
  final String bookingId;
  final String text;
  final String createdAt;
  final String? senderUserId;

  factory ChatMessageV2.fromJson(Map<String, dynamic> json) {
    return ChatMessageV2(
      id: '${json['id'] ?? ''}',
      bookingId: '${json['booking_id'] ?? ''}',
      text: '${json['text'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
      senderUserId: json['sender_user_id']?.toString(),
    );
  }
}

class ChatNewMessagesResult {
  const ChatNewMessagesResult({
    required this.count,
    required this.hasNew,
    this.latestAt,
  });

  final int count;
  final bool hasNew;
  final String? latestAt;

  factory ChatNewMessagesResult.fromJson(Map<String, dynamic> json) {
    return ChatNewMessagesResult(
      count: (json['count'] as num?)?.toInt() ?? 0,
      hasNew: json['has_new'] == true,
      latestAt: json['latest_at'] as String?,
    );
  }
}

class ChatV2Service {
  ChatV2Service({V2ApiClient? client}) : _api = client ?? V2ApiClient.instance;

  static final ChatV2Service instance = ChatV2Service();

  final V2ApiClient _api;
  static const _script = 'chat_v2.php';

  Future<List<ChatMessageV2>> getMessages(String bookingId) async {
    final response = await _api.getAuth(
      _script,
      action: 'get_messages',
      query: {'booking_id': bookingId},
    );
    return _api.parse(
      response,
      (body) {
        final raw = body['messages'];
        if (raw is! List) return <ChatMessageV2>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(ChatMessageV2.fromJson)
            .toList();
      },
    );
  }

  Future<ChatMessageV2> sendMessage({
    required String bookingId,
    required String text,
  }) async {
    final response = await _api.postAuth(
      _script,
      action: 'send_message',
      body: {'booking_id': bookingId, 'text': text},
    );
    return _api.parse(
      response,
      (body) => ChatMessageV2(
        id: '${body['message_id'] ?? ''}',
        bookingId: '${body['booking_id'] ?? bookingId}',
        text: '${body['text'] ?? text}',
        createdAt: DateTime.now().toUtc().toIso8601String(),
        senderUserId: body['sender_user_id']?.toString(),
      ),
    );
  }

  Future<ChatNewMessagesResult> checkNewMessages({
    required String bookingId,
    required String since,
  }) async {
    final response = await _api.getAuth(
      _script,
      action: 'check_new_messages',
      query: {'booking_id': bookingId, 'since': since},
    );
    return _api.parse(response, ChatNewMessagesResult.fromJson);
  }
}
