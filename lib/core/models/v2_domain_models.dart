import 'package:kaki_empat/core/config/denpasar_kecamatan.dart';

class PetV2 {
  const PetV2({
    required this.id,
    required this.name,
    required this.species,
    this.breed = '',
    this.age = '',
    this.weight,
    this.notes = '',
  });

  final String id;
  final String name;
  final String species;
  final String breed;
  final String age;
  final double? weight;
  final String notes;

  factory PetV2.fromJson(Map<String, dynamic> json) {
    return PetV2(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      species: '${json['species'] ?? ''}',
      breed: '${json['breed'] ?? ''}',
      age: '${json['age'] ?? ''}',
      weight: (json['weight'] as num?)?.toDouble(),
      notes: '${json['notes'] ?? ''}',
    );
  }
}

class OwnerProfileV2 {
  const OwnerProfileV2({
    this.address = '',
    this.kecamatan,
    this.latitude,
    this.longitude,
    this.fullName = '',
    this.contactPhone = '',
  });

  final String address;
  final String? kecamatan;
  final double? latitude;
  final double? longitude;
  final String fullName;
  final String contactPhone;

  factory OwnerProfileV2.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OwnerProfileV2();
    return OwnerProfileV2(
      address: '${json['address'] ?? ''}',
      kecamatan: DenpasarKecamatan.normalize('${json['kecamatan'] ?? ''}'),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      fullName: '${json['full_name'] ?? ''}',
      contactPhone: '${json['contact_phone'] ?? ''}',
    );
  }
}

class OwnerProfileResult {
  const OwnerProfileResult({
    this.profile,
    required this.pets,
    required this.onboardingComplete,
    required this.needsOnboarding,
  });

  final OwnerProfileV2? profile;
  final List<PetV2> pets;
  final bool onboardingComplete;
  final bool needsOnboarding;

  factory OwnerProfileResult.fromJson(Map<String, dynamic> json) {
    final rawPets = json['pets'];
    return OwnerProfileResult(
      profile: OwnerProfileV2.fromJson(
        json['profile'] as Map<String, dynamic>?,
      ),
      pets: rawPets is List
          ? rawPets
              .whereType<Map<String, dynamic>>()
              .map(PetV2.fromJson)
              .toList()
          : const [],
      onboardingComplete: json['onboarding_complete'] == true,
      needsOnboarding: json['needs_onboarding'] == true,
    );
  }
}

/// BFF agregat home owner — satu round-trip untuk money engine.
class OwnerRecommendationV2 {
  const OwnerRecommendationV2({
    required this.kind,
    required this.title,
    this.subtitle = '',
    this.action = '',
    this.payload = const {},
  });

  final String kind;
  final String title;
  final String subtitle;
  final String action;
  final Map<String, String> payload;

  factory OwnerRecommendationV2.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    final payload = <String, String>{};
    if (rawPayload is Map) {
      rawPayload.forEach((key, value) {
        payload['$key'] = '$value';
      });
    }
    return OwnerRecommendationV2(
      kind: '${json['kind'] ?? ''}',
      title: '${json['title'] ?? ''}',
      subtitle: '${json['subtitle'] ?? ''}',
      action: '${json['action'] ?? ''}',
      payload: payload,
    );
  }
}

class OwnerDashboardResult {
  const OwnerDashboardResult({
    required this.owner,
    required this.catalog,
    required this.bookings,
    required this.requests,
    this.userName = '',
    this.recommendations = const [],
  });

  final OwnerProfileResult owner;
  final ServiceCatalogResult catalog;
  final List<BookingV2> bookings;
  final List<BookingRequestV2> requests;
  final String userName;
  final List<OwnerRecommendationV2> recommendations;

  factory OwnerDashboardResult.fromJson(Map<String, dynamic> json) {
    final rawBookings = json['bookings'];
    final rawRequests = json['requests'];
    final rawRecommendations = json['recommendations'];
    final ownerJson = json['owner'];
    final catalogJson = json['catalog'];
    return OwnerDashboardResult(
      owner: OwnerProfileResult.fromJson(
        ownerJson is Map<String, dynamic> ? ownerJson : const {},
      ),
      catalog: ServiceCatalogResult.fromJson(
        catalogJson is Map<String, dynamic> ? catalogJson : const {},
      ),
      bookings: rawBookings is List
          ? rawBookings
              .whereType<Map<String, dynamic>>()
              .map(BookingV2.fromJson)
              .toList()
          : const [],
      requests: rawRequests is List
          ? rawRequests
              .whereType<Map<String, dynamic>>()
              .map(BookingRequestV2.fromJson)
              .toList()
          : const [],
      recommendations: rawRecommendations is List
          ? rawRecommendations
              .whereType<Map<String, dynamic>>()
              .map(OwnerRecommendationV2.fromJson)
              .toList()
          : const [],
      userName: '${json['user_name'] ?? ''}'.trim(),
    );
  }
}

class SitterProfileV2 {
  const SitterProfileV2({
    this.bio = '',
    this.address = '',
    this.kecamatan,
    this.latitude,
    this.longitude,
    this.status = 'draft',
    this.submittedAt,
    this.isVerified = false,
    this.hasVerificationDocs = false,
    this.isAvailable = true,
  });

  final String bio;
  final String address;
  final String? kecamatan;
  final double? latitude;
  final double? longitude;
  final String status;
  final bool isAvailable;
  final String? submittedAt;
  final bool isVerified;
  final bool hasVerificationDocs;

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending_verification';

  factory SitterProfileV2.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SitterProfileV2();
    return SitterProfileV2(
      bio: '${json['bio'] ?? ''}',
      address: '${json['address'] ?? ''}',
      kecamatan: DenpasarKecamatan.normalize('${json['kecamatan'] ?? ''}'),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: '${json['status'] ?? 'draft'}',
      submittedAt: json['submitted_at'] as String?,
      isVerified: json['is_verified'] == true || json['status'] == 'approved',
      hasVerificationDocs: json['has_verification_docs'] == true,
      isAvailable: json['is_available'] != false,
    );
  }
}

class SitterProfileResult {
  const SitterProfileResult({
    this.profile,
    required this.services,
    required this.onboardingComplete,
    required this.needsOnboarding,
    this.badges = const [],
    this.averageRating,
    this.completedBookings = 0,
  });

  final SitterProfileV2? profile;
  final List<String> services;
  final bool onboardingComplete;
  final bool needsOnboarding;
  final List<Map<String, dynamic>> badges;
  final double? averageRating;
  final int completedBookings;

  factory SitterProfileResult.fromJson(Map<String, dynamic> json) {
    final raw = json['services'];
    final rawBadges = json['badges'];
    return SitterProfileResult(
      profile: SitterProfileV2.fromJson(
        json['profile'] as Map<String, dynamic>?,
      ),
      services: raw is List ? raw.map((e) => '$e').toList() : const [],
      onboardingComplete: json['onboarding_complete'] == true,
      needsOnboarding: json['needs_onboarding'] == true,
      badges: rawBadges is List
          ? rawBadges.whereType<Map<String, dynamic>>().toList()
          : const [],
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      completedBookings: (json['completed_bookings'] as num?)?.toInt() ?? 0,
    );
  }
}

class ServiceCatalogItem {
  const ServiceCatalogItem({
    required this.code,
    required this.label,
    required this.category,
    required this.categoryLabel,
    required this.enabled,
    required this.sortOrder,
  });

  final String code;
  final String label;
  final String category;
  final String categoryLabel;
  final bool enabled;
  final int sortOrder;

  factory ServiceCatalogItem.fromJson(Map<String, dynamic> json) {
    return ServiceCatalogItem(
      code: '${json['code'] ?? ''}',
      label: '${json['label'] ?? ''}',
      category: '${json['category'] ?? ''}',
      categoryLabel: '${json['category_label'] ?? ''}',
      enabled: json['enabled'] == true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class ServiceCategoryGroup {
  const ServiceCategoryGroup({
    required this.code,
    required this.label,
    required this.sortOrder,
    required this.services,
  });

  final String code;
  final String label;
  final int sortOrder;
  final List<ServiceCatalogItem> services;

  int get serviceCount => services.where((s) => s.enabled).length;

  factory ServiceCategoryGroup.fromJson(Map<String, dynamic> json) {
    final raw = json['services'];
    return ServiceCategoryGroup(
      code: '${json['code'] ?? ''}',
      label: '${json['label'] ?? ''}',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      services: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(ServiceCatalogItem.fromJson)
              .where((s) => s.enabled)
              .toList()
          : const [],
    );
  }
}

class ServiceCatalogResult {
  const ServiceCatalogResult({
    required this.services,
    required this.categories,
  });

  final List<ServiceCatalogItem> services;
  final List<ServiceCategoryGroup> categories;

  factory ServiceCatalogResult.fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'];
    final rawCategories = json['categories'];
    return ServiceCatalogResult(
      services: rawServices is List
          ? rawServices
              .whereType<Map<String, dynamic>>()
              .map(ServiceCatalogItem.fromJson)
              .where((s) => s.enabled)
              .toList()
          : const [],
      categories: rawCategories is List
          ? rawCategories
              .whereType<Map<String, dynamic>>()
              .map(ServiceCategoryGroup.fromJson)
              .where((c) => c.serviceCount > 0)
              .toList()
          : const [],
    );
  }
}

class RequestLocationV2 {
  const RequestLocationV2({
    this.address = '',
    this.kecamatan,
    this.latitude,
    this.longitude,
  });

  final String address;
  final String? kecamatan;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() => {
        'address': address,
        if (kecamatan != null) 'kecamatan': kecamatan,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

  factory RequestLocationV2.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RequestLocationV2();
    return RequestLocationV2(
      address: '${json['address'] ?? ''}',
      kecamatan: DenpasarKecamatan.normalize('${json['kecamatan'] ?? ''}'),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class BookingRequestV2 {
  const BookingRequestV2({
    required this.id,
    required this.ownerUserId,
    required this.ownerName,
    required this.serviceCode,
    required this.scheduledAt,
    required this.notes,
    required this.petIds,
    required this.totalPrice,
    required this.paymentAmount,
    required this.status,
    required this.createdAt,
    this.dateLabel = '',
    this.timeRange = '',
    this.location,
    this.kecamatan,
    this.distanceKm,
    this.serviceLabel = '',
    this.pendingOfferCount = 0,
    this.petNames = const [],
    this.petSpecies = const [],
  });

  final String id;
  final String ownerUserId;
  final String ownerName;
  final String serviceCode;
  final String scheduledAt;
  final String notes;
  final List<String> petIds;
  final int totalPrice;
  final int paymentAmount;
  final String status;
  final String createdAt;
  final String dateLabel;
  final String timeRange;
  final RequestLocationV2? location;
  final String? kecamatan;
  final double? distanceKm;
  final String serviceLabel;
  final int pendingOfferCount;
  final List<String> petNames;
  final List<String> petSpecies;

  factory BookingRequestV2.fromJson(Map<String, dynamic> json) {
    final rawPets = json['pet_ids'];
    final rawPetNames = json['pet_names'];
    final rawPetSpecies = json['pet_species'];
    final price = (json['price'] as num?)?.toInt() ??
        (json['total_price'] as num?)?.toInt() ??
        0;
    return BookingRequestV2(
      id: '${json['id'] ?? ''}',
      ownerUserId: '${json['owner_user_id'] ?? ''}',
      ownerName: '${json['owner_name'] ?? ''}',
      serviceCode: '${json['service_code'] ?? json['service_type'] ?? ''}',
      scheduledAt: '${json['scheduled_at'] ?? ''}',
      notes: '${json['notes'] ?? ''}',
      petIds: rawPets is List ? rawPets.map((e) => '$e').toList() : const [],
      totalPrice: price,
      paymentAmount: (json['payment_amount'] as num?)?.toInt() ?? 0,
      status: '${json['status'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
      dateLabel: '${json['date_label'] ?? ''}',
      timeRange: '${json['time_range'] ?? ''}',
      location: json['location'] is Map<String, dynamic>
          ? RequestLocationV2.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      kecamatan: DenpasarKecamatan.normalize('${json['kecamatan'] ?? ''}'),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      serviceLabel: '${json['service_label'] ?? ''}',
      pendingOfferCount: (json['pending_offer_count'] as num?)?.toInt() ?? 0,
      petNames: rawPetNames is List
          ? rawPetNames.map((e) => '$e').where((n) => n.isNotEmpty).toList()
          : const [],
      petSpecies: rawPetSpecies is List
          ? rawPetSpecies.map((e) => '$e').where((n) => n.isNotEmpty).toList()
          : const [],
    );
  }
}

class MarketplaceOfferV2 {
  const MarketplaceOfferV2({
    required this.id,
    required this.requestId,
    required this.sitterUserId,
    required this.sitterName,
    required this.price,
    required this.status,
    this.message = '',
    this.sitterPhone = '',
    this.createdAt = '',
    this.isVerified = false,
    this.hasPromo = false,
    this.averageRating,
    this.badges = const [],
  });

  final String id;
  final String requestId;
  final String sitterUserId;
  final String sitterName;
  final int price;
  final String status;
  final String message;
  final String sitterPhone;
  final String createdAt;
  final bool isVerified;
  final bool hasPromo;
  final double? averageRating;
  final List<Map<String, dynamic>> badges;

  bool get isPending => status.toLowerCase() == 'pending';

  factory MarketplaceOfferV2.fromJson(Map<String, dynamic> json) {
    final rawBadges = json['badges'];
    return MarketplaceOfferV2(
      id: '${json['offer_id'] ?? json['id'] ?? ''}',
      requestId: '${json['request_id'] ?? ''}',
      sitterUserId: '${json['sitter_user_id'] ?? ''}',
      sitterName: '${json['sitter_name'] ?? ''}',
      price: (json['price'] as num?)?.toInt() ?? 0,
      status: '${json['status'] ?? ''}',
      message: '${json['message'] ?? ''}',
      sitterPhone: '${json['sitter_phone'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
      isVerified: json['is_verified'] == true,
      hasPromo: json['has_promo'] == true,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      badges: rawBadges is List
          ? rawBadges.whereType<Map<String, dynamic>>().toList()
          : const [],
    );
  }
}

class BookingV2 {
  const BookingV2({
    required this.id,
    this.offerId,
    this.requestId,
    this.ownerUserId,
    this.sitterUserId,
    required this.status,
    required this.totalPrice,
    required this.paymentAmount,
    this.serviceCode = '',
    this.scheduledAt = '',
    this.notes = '',
    this.petIds = const [],
    this.petNames = const [],
    this.petSpecies = const [],
    this.createdAt = '',
  });

  final String id;
  final String? offerId;
  final String? requestId;
  final String? ownerUserId;
  final String? sitterUserId;
  final String status;
  final int totalPrice;
  final int paymentAmount;
  final String serviceCode;
  final String scheduledAt;
  final String notes;
  final List<String> petIds;
  final List<String> petNames;
  final List<String> petSpecies;
  final String createdAt;

  bool get needsPayment {
    final s = status.toLowerCase().replaceAll('_', '');
    return s == 'awaitingpayment' && paymentAmount > 0;
  }

  bool get isPaid => status.toLowerCase().replaceAll('_', '') == 'paid';

  factory BookingV2.fromJson(Map<String, dynamic> json) {
    final rawPets = json['pet_ids'];
    final rawPetNames = json['pet_names'];
    final rawPetSpecies = json['pet_species'];
    return BookingV2(
      id: '${json['id'] ?? ''}',
      offerId: json['offer_id']?.toString(),
      requestId: json['request_id']?.toString(),
      ownerUserId: json['owner_user_id']?.toString(),
      sitterUserId: json['sitter_user_id']?.toString(),
      status: '${json['status'] ?? ''}',
      totalPrice: (json['total_price'] as num?)?.toInt() ?? 0,
      paymentAmount: (json['payment_amount'] as num?)?.toInt() ?? 0,
      serviceCode: '${json['service_code'] ?? json['service_type'] ?? ''}',
      scheduledAt: '${json['scheduled_at'] ?? ''}',
      notes: '${json['notes'] ?? ''}',
      petIds: rawPets is List ? rawPets.map((e) => '$e').toList() : const [],
      petNames: rawPetNames is List
          ? rawPetNames.map((e) => '$e').where((n) => n.isNotEmpty).toList()
          : const [],
      petSpecies: rawPetSpecies is List
          ? rawPetSpecies.map((e) => '$e').where((n) => n.isNotEmpty).toList()
          : const [],
      createdAt: '${json['created_at'] ?? ''}',
    );
  }
}

class PendingSitterV2 {
  const PendingSitterV2({
    required this.userId,
    required this.name,
    required this.phone,
    required this.address,
    required this.bio,
    required this.services,
    required this.status,
    this.submittedAt,
    this.hasKtp = false,
    this.hasSelfie = false,
    this.ktpData,
    this.selfieData,
  });

  final String userId;
  final String name;
  final String phone;
  final String address;
  final String bio;
  final List<String> services;
  final String status;
  final String? submittedAt;
  final bool hasKtp;
  final bool hasSelfie;
  final String? ktpData;
  final String? selfieData;

  factory PendingSitterV2.fromJson(Map<String, dynamic> json) {
    final raw = json['services'];
    return PendingSitterV2(
      userId: '${json['user_id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      address: '${json['address'] ?? ''}',
      bio: '${json['bio'] ?? ''}',
      services: raw is List ? raw.map((e) => '$e').toList() : const [],
      status: '${json['status'] ?? ''}',
      submittedAt: json['submitted_at'] as String?,
      hasKtp: json['has_ktp'] == true,
      hasSelfie: json['has_selfie'] == true,
      ktpData: json['ktp_data'] as String?,
      selfieData: json['selfie_data'] as String?,
    );
  }
}

class PetTimelineEvent {
  const PetTimelineEvent({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.status = '',
    this.occurredAt = '',
    this.payload = const {},
  });

  final String kind;
  final String title;
  final String subtitle;
  final String status;
  final String occurredAt;
  final Map<String, dynamic> payload;

  factory PetTimelineEvent.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    return PetTimelineEvent(
      kind: '${json['kind'] ?? ''}',
      title: '${json['title'] ?? ''}',
      subtitle: '${json['subtitle'] ?? ''}',
      status: '${json['status'] ?? ''}',
      occurredAt: '${json['occurred_at'] ?? ''}',
      payload: rawPayload is Map<String, dynamic> ? rawPayload : const {},
    );
  }
}

class PetTimelineResult {
  const PetTimelineResult({
    required this.pet,
    required this.events,
    required this.total,
  });

  final PetV2 pet;
  final List<PetTimelineEvent> events;
  final int total;

  factory PetTimelineResult.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'];
    return PetTimelineResult(
      pet: PetV2.fromJson(json['pet'] as Map<String, dynamic>? ?? {}),
      events: rawEvents is List
          ? rawEvents
              .whereType<Map<String, dynamic>>()
              .map(PetTimelineEvent.fromJson)
              .toList()
          : const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class CategorySupplyResult {
  const CategorySupplyResult({
    required this.category,
    required this.kecamatan,
    required this.available,
    required this.totalSupply,
    this.sitterCount = 0,
    this.businessCount = 0,
  });

  final String category;
  final String kecamatan;
  final bool available;
  final int totalSupply;
  final int sitterCount;
  final int businessCount;

  factory CategorySupplyResult.fromJson(Map<String, dynamic> json) {
    return CategorySupplyResult(
      category: '${json['category'] ?? ''}',
      kecamatan: '${json['kecamatan'] ?? ''}',
      available: json['available'] == true,
      totalSupply: (json['total_supply'] as num?)?.toInt() ?? 0,
      sitterCount: (json['sitter_count'] as num?)?.toInt() ?? 0,
      businessCount: (json['business_count'] as num?)?.toInt() ?? 0,
    );
  }
}
