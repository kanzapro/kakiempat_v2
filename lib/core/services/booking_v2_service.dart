import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';

class BookingV2Service {
  BookingV2Service({V2ApiClient? client}) : _api = client ?? V2ApiClient.instance;

  static final BookingV2Service instance = BookingV2Service();

  final V2ApiClient _api;
  static const _script = 'booking_v2.php';

  Future<String> createRequest({
    required String serviceCode,
    required DateTime scheduledAt,
    required List<String> petIds,
    int totalPrice = 0,
    String notes = '',
  }) async {
    final response = await _api.postAuth(
      _script,
      action: 'create_request',
      body: {
        'service_code': serviceCode,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'pet_ids': petIds,
        'total_price': totalPrice,
        if (notes.isNotEmpty) 'notes': notes,
      },
    );
    return _api.parse(
      response,
      (body) => '${body['request_id'] ?? ''}',
    );
  }

  Future<List<BookingRequestV2>> listIncomingRequests() async {
    final response =
        await _api.getAuth(_script, action: 'list_incoming_requests');
    return _api.parse(
      response,
      (body) {
        final raw = body['requests'];
        if (raw is! List) return <BookingRequestV2>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(BookingRequestV2.fromJson)
            .toList();
      },
    );
  }

  Future<String> acceptRequest(String requestId) async {
    final response = await _api.postAuth(
      _script,
      action: 'accept_request',
      body: {'request_id': requestId},
    );
    return _api.parse(
      response,
      (body) => '${body['booking_id'] ?? ''}',
    );
  }

  Future<void> rejectRequest(String requestId) async {
    final response = await _api.postAuth(
      _script,
      action: 'reject_request',
      body: {'request_id': requestId},
    );
    await _api.parse<void>(response, (_) {});
  }

  Future<BookingV2> getBooking(String bookingId) async {
    final response = await _api.getAuth(
      _script,
      action: 'get_booking',
      query: {'booking_id': bookingId},
    );
    return _api.parse(
      response,
      (body) => BookingV2.fromJson(body['booking'] as Map<String, dynamic>),
    );
  }

  Future<List<BookingV2>> listMyBookings() async {
    final response = await _api.getAuth(_script, action: 'list_my_bookings');
    return _parseBookings(response);
  }

  Future<List<BookingV2>> listByOwner() async {
    final response = await _api.getAuth(_script, action: 'list_by_owner');
    return _parseBookings(response);
  }

  Future<List<BookingV2>> listBySitter() async {
    final response = await _api.getAuth(_script, action: 'list_by_sitter');
    return _parseBookings(response);
  }

  Future<List<BookingV2>> _parseBookings(dynamic response) async {
    return _api.parse(
      response,
      (body) {
        final raw = body['bookings'];
        if (raw is! List) return <BookingV2>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(BookingV2.fromJson)
            .toList();
      },
    );
  }

  Future<void> sitterConfirm(String bookingId) async {
    final response = await _api.postAuth(
      _script,
      action: 'sitter_confirm',
      body: {'booking_id': bookingId},
    );
    await _api.parse<void>(response, (_) {});
  }

  Future<void> sitterEnRoute(String bookingId) async {
    final response = await _api.postAuth(
      _script,
      action: 'sitter_en_route',
      body: {'booking_id': bookingId},
    );
    await _api.parse<void>(response, (_) {});
  }

  Future<void> startBooking(String bookingId) async {
    final response = await _api.postAuth(
      _script,
      action: 'start_booking',
      body: {'booking_id': bookingId},
    );
    await _api.parse<void>(response, (_) {});
  }

  Future<void> completeBooking(String bookingId) async {
    final response = await _api.postAuth(
      _script,
      action: 'complete_booking',
      body: {'booking_id': bookingId},
    );
    await _api.parse<void>(response, (_) {});
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    final response = await _api.postAuth(
      _script,
      action: 'cancel_booking',
      body: {
        'booking_id': bookingId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    await _api.parse<void>(response, (_) {});
  }
}
