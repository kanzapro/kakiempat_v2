import 'package:kaki_empat/core/config/denpasar_kecamatan.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';

class MarketplaceOfferResult {
  const MarketplaceOfferResult({
    required this.offerId,
    required this.requestId,
    required this.status,
    this.message = '',
  });

  final String offerId;
  final String requestId;
  final String status;
  final String message;

  factory MarketplaceOfferResult.fromJson(Map<String, dynamic> json) {
    return MarketplaceOfferResult(
      offerId: '${json['offer_id'] ?? ''}',
      requestId: '${json['request_id'] ?? ''}',
      status: '${json['status'] ?? ''}',
      message: '${json['message'] ?? ''}',
    );
  }
}

class MarketplaceAcceptResult {
  const MarketplaceAcceptResult({
    required this.bookingId,
    required this.offerId,
    required this.requestId,
    required this.status,
    this.totalPrice = 0,
    this.paymentAmount = 0,
    this.message = '',
  });

  final String bookingId;
  final String offerId;
  final String requestId;
  final String status;
  final int totalPrice;
  final int paymentAmount;
  final String message;

  factory MarketplaceAcceptResult.fromJson(Map<String, dynamic> json) {
    return MarketplaceAcceptResult(
      bookingId: '${json['booking_id'] ?? ''}',
      offerId: '${json['offer_id'] ?? ''}',
      requestId: '${json['request_id'] ?? ''}',
      status: '${json['status'] ?? ''}',
      totalPrice: (json['total_price'] as num?)?.toInt() ?? 0,
      paymentAmount: (json['payment_amount'] as num?)?.toInt() ?? 0,
      message: '${json['message'] ?? ''}',
    );
  }
}

class MarketplaceCreateRequestResult {
  const MarketplaceCreateRequestResult({
    required this.requestId,
    this.sitterCountInRadius,
    this.sitterCountInKecamatan,
    this.kecamatan,
    this.radiusKm = 7,
    this.message = '',
  });

  final String requestId;
  final int? sitterCountInRadius;
  final int? sitterCountInKecamatan;
  final String? kecamatan;
  final double radiusKm;
  final String message;

  factory MarketplaceCreateRequestResult.fromJson(Map<String, dynamic> json) {
    return MarketplaceCreateRequestResult(
      requestId: '${json['request_id'] ?? ''}',
      sitterCountInRadius: (json['sitter_count_in_radius'] as num?)?.toInt(),
      sitterCountInKecamatan: (json['sitter_count_in_kecamatan'] as num?)?.toInt(),
      kecamatan: DenpasarKecamatan.normalize('${json['kecamatan'] ?? ''}'),
      radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 7,
      message: '${json['message'] ?? ''}',
    );
  }
}

class MarketplaceBroadcastEstimate {
  const MarketplaceBroadcastEstimate({
    required this.sitterCountInRadius,
    required this.sitterCountInKecamatan,
    this.kecamatan,
    required this.radiusKm,
  });

  final int sitterCountInRadius;
  final int sitterCountInKecamatan;
  final String? kecamatan;
  final double radiusKm;

  int get sitterCount => sitterCountInKecamatan > 0 || kecamatan != null
      ? sitterCountInKecamatan
      : sitterCountInRadius;

  factory MarketplaceBroadcastEstimate.fromJson(Map<String, dynamic> json) {
    return MarketplaceBroadcastEstimate(
      sitterCountInRadius:
          (json['sitter_count_in_radius'] as num?)?.toInt() ?? 0,
      sitterCountInKecamatan:
          (json['sitter_count_in_kecamatan'] as num?)?.toInt() ?? 0,
      kecamatan: DenpasarKecamatan.normalize('${json['kecamatan'] ?? ''}'),
      radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 7,
    );
  }
}

class MarketplaceV2Service {
  MarketplaceV2Service({V2ApiClient? client})
      : _api = client ?? V2ApiClient.instance;

  static final MarketplaceV2Service instance = MarketplaceV2Service();

  final V2ApiClient _api;
  static const _script = 'marketplace_v2.php';

  static const double broadcastRadiusKm = 7;

  Future<MarketplaceCreateRequestResult> createRequest({
    required String serviceType,
    required List<String> petIds,
    required String dateLabel,
    required String timeRange,
    required Map<String, dynamic> location,
    String? kecamatan,
    int price = 0,
    String notes = '',
  }) async {
    final response = await _api.postAuth(
      _script,
      action: 'create_request',
      body: {
        'service_type': serviceType,
        'pets': petIds,
        'date_label': dateLabel,
        'time_range': timeRange,
        'location': location,
        if (kecamatan != null) 'kecamatan': kecamatan,
        'price': price,
        if (notes.isNotEmpty) 'notes': notes,
      },
    );
    return _api.parse(response, MarketplaceCreateRequestResult.fromJson);
  }

  Future<MarketplaceBroadcastEstimate> estimateBroadcast({
    required String serviceType,
    String? kecamatan,
    double? latitude,
    double? longitude,
    double radiusKm = broadcastRadiusKm,
  }) async {
    final response = await _api.getAuth(
      _script,
      action: 'estimate_broadcast',
      query: {
        'service_type': serviceType,
        if (kecamatan != null) 'kecamatan': kecamatan,
        if (latitude != null) 'latitude': '$latitude',
        if (longitude != null) 'longitude': '$longitude',
        if (kecamatan == null) 'radius_km': '$radiusKm',
      },
    );
    return _api.parse(response, MarketplaceBroadcastEstimate.fromJson);
  }

  Future<List<BookingRequestV2>> listRequests({
    String pool = 'open',
    String? serviceType,
  }) async {
    final response = await _api.getAuth(
      _script,
      action: 'list_requests',
      query: {
        'pool': pool,
        if (serviceType != null && serviceType.isNotEmpty)
          'service_type': serviceType,
      },
    );
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

  Future<MarketplaceOfferResult> createOffer({
    required String requestId,
    required int price,
    String message = '',
  }) async {
    final response = await _api.postAuth(
      _script,
      action: 'create_offer',
      body: {
        'request_id': requestId,
        'price': price,
        if (message.isNotEmpty) 'message': message,
      },
    );
    return _api.parse(response, MarketplaceOfferResult.fromJson);
  }

  Future<MarketplaceAcceptResult> acceptOffer(String offerId) async {
    final response = await _api.postAuth(
      _script,
      action: 'accept_offer',
      body: {'offer_id': offerId},
    );
    return _api.parse(response, MarketplaceAcceptResult.fromJson);
  }

  Future<List<BookingRequestV2>> listMyRequests({String pool = 'active'}) async {
    final response = await _api.getAuth(
      _script,
      action: 'list_my_requests',
      query: {'pool': pool},
    );
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

  Future<List<MarketplaceOfferV2>> listOffers(String requestId) async {
    final response = await _api.getAuth(
      _script,
      action: 'list_offers',
      query: {'request_id': requestId},
    );
    return _api.parse(
      response,
      (body) {
        final raw = body['offers'];
        if (raw is! List) return <MarketplaceOfferV2>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(MarketplaceOfferV2.fromJson)
            .toList();
      },
    );
  }
}
