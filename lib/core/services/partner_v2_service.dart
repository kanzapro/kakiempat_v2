import 'package:kaki_empat/core/services/v2_api_client.dart';

class PartnerServiceV2 {
  const PartnerServiceV2({
    required this.id,
    required this.code,
    required this.name,
    this.category = '',
    this.description = '',
    this.logoEmoji = '🐾',
    this.actionType = 'external_url',
    this.actionUrl = '',
  });

  final String id;
  final String code;
  final String name;
  final String category;
  final String description;
  final String logoEmoji;
  final String actionType;
  final String actionUrl;

  factory PartnerServiceV2.fromJson(Map<String, dynamic> json) {
    return PartnerServiceV2(
      id: '${json['id'] ?? ''}',
      code: '${json['code'] ?? ''}',
      name: '${json['name'] ?? ''}',
      category: '${json['category'] ?? ''}',
      description: '${json['description'] ?? ''}',
      logoEmoji: '${json['logo_emoji'] ?? '🐾'}',
      actionType: '${json['action_type'] ?? 'external_url'}',
      actionUrl: '${json['action_url'] ?? ''}',
    );
  }
}

class BusinessPartnerV2 {
  const BusinessPartnerV2({
    required this.id,
    required this.legalName,
    this.providerType = 'business',
    this.status = '',
    this.serviceCodes = const [],
    this.locationAddress = '',
    this.locationKecamatan = '',
  });

  final String id;
  final String legalName;
  final String providerType;
  final String status;
  final List<String> serviceCodes;
  final String locationAddress;
  final String locationKecamatan;

  factory BusinessPartnerV2.fromJson(Map<String, dynamic> json) {
    final rawCodes = json['service_codes'];
    final rawLocation = json['location'];
    final location = rawLocation is Map<String, dynamic> ? rawLocation : const {};
    return BusinessPartnerV2(
      id: '${json['id'] ?? ''}',
      legalName: '${json['legal_name'] ?? ''}',
      providerType: '${json['provider_type'] ?? 'business'}',
      status: '${json['status'] ?? ''}',
      serviceCodes: rawCodes is List ? rawCodes.map((e) => '$e').toList() : const [],
      locationAddress: '${location['address'] ?? ''}',
      locationKecamatan: '${location['kecamatan'] ?? ''}',
    );
  }
}

class PartnerV2Service {
  PartnerV2Service({V2ApiClient? client}) : _api = client ?? V2ApiClient.instance;

  static final PartnerV2Service instance = PartnerV2Service();

  final V2ApiClient _api;
  static const _script = 'partner_v2.php';

  Future<List<BusinessPartnerV2>> listBusinesses({
    String? category,
    String? kecamatan,
  }) async {
    final response = await _api.getAuth(
      _script,
      action: 'list_businesses',
      query: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (kecamatan != null && kecamatan.isNotEmpty) 'kecamatan': kecamatan,
      },
    );
    return _api.parse(
      response,
      (body) {
        final raw = body['businesses'];
        if (raw is! List) return <BusinessPartnerV2>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(BusinessPartnerV2.fromJson)
            .toList();
      },
    );
  }

  Future<List<PartnerServiceV2>> listServices({String? category}) async {
    final response = await _api.getAuth(
      _script,
      action: 'list_services',
      query: {if (category != null && category.isNotEmpty) 'category': category},
    );
    return _api.parse(
      response,
      (body) {
        final raw = body['services'];
        if (raw is! List) return <PartnerServiceV2>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(PartnerServiceV2.fromJson)
            .toList();
      },
    );
  }
}
