import 'package:kaki_empat/core/services/v2_api_client.dart';

class EarningsPeriod {
  const EarningsPeriod({
    required this.period,
    required this.gross,
    required this.fees,
    required this.net,
  });

  final String period;
  final int gross;
  final int fees;
  final int net;

  factory EarningsPeriod.fromJson(Map<String, dynamic> json) {
    return EarningsPeriod(
      period: '${json['period'] ?? ''}',
      gross: (json['gross'] as num?)?.toInt() ?? 0,
      fees: (json['fees'] as num?)?.toInt() ?? 0,
      net: (json['net'] as num?)?.toInt() ?? 0,
    );
  }
}

class EarningsReport {
  const EarningsReport({
    required this.totalBookings,
    required this.totalNetIncome,
    required this.weekly,
    required this.monthly,
    this.averageRating,
  });

  final int totalBookings;
  final double? averageRating;
  final int totalNetIncome;
  final List<EarningsPeriod> weekly;
  final List<EarningsPeriod> monthly;

  factory EarningsReport.fromJson(Map<String, dynamic> json) {
    List<EarningsPeriod> parseList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(EarningsPeriod.fromJson)
          .toList();
    }

    return EarningsReport(
      totalBookings: (json['total_bookings'] as num?)?.toInt() ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      totalNetIncome: (json['total_net_income'] as num?)?.toInt() ?? 0,
      weekly: parseList(json['weekly']),
      monthly: parseList(json['monthly']),
    );
  }
}

class SitterAchievement {
  const SitterAchievement({
    required this.code,
    required this.label,
    required this.earnedAt,
  });

  final String code;
  final String label;
  final String earnedAt;

  factory SitterAchievement.fromJson(Map<String, dynamic> json) {
    return SitterAchievement(
      code: '${json['code'] ?? ''}',
      label: '${json['label'] ?? ''}',
      earnedAt: '${json['earned_at'] ?? ''}',
    );
  }
}

class SitterPromotion {
  const SitterPromotion({
    required this.id,
    required this.code,
    required this.discountPercent,
    required this.maxUses,
    required this.usedCount,
    required this.isActive,
    this.createdAt = '',
  });

  final String id;
  final String code;
  final int discountPercent;
  final int maxUses;
  final int usedCount;
  final bool isActive;
  final String createdAt;

  factory SitterPromotion.fromJson(Map<String, dynamic> json) {
    return SitterPromotion(
      id: '${json['id'] ?? ''}',
      code: '${json['code'] ?? ''}',
      discountPercent: (json['discount_percent'] as num?)?.toInt() ?? 0,
      maxUses: (json['max_uses'] as num?)?.toInt() ?? 1,
      usedCount: (json['used_count'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] == true,
      createdAt: '${json['created_at'] ?? ''}',
    );
  }
}

class BusinessV2Service {
  BusinessV2Service({V2ApiClient? client})
      : _api = client ?? V2ApiClient.instance;

  static final BusinessV2Service instance = BusinessV2Service();

  final V2ApiClient _api;
  static const _script = 'business_v2.php';

  Future<EarningsReport> getEarningsReport() async {
    final response =
        await _api.getAuth(_script, action: 'get_earnings_report');
    return _api.parse(response, EarningsReport.fromJson);
  }

  Future<List<SitterAchievement>> getAchievements() async {
    final response = await _api.getAuth(_script, action: 'get_achievements');
    return _api.parse(
      response,
      (body) {
        final raw = body['achievements'];
        if (raw is! List) return <SitterAchievement>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(SitterAchievement.fromJson)
            .toList();
      },
    );
  }

  Future<List<SitterPromotion>> listMyPromotions() async {
    final response =
        await _api.getAuth(_script, action: 'list_my_promotions');
    return _api.parse(
      response,
      (body) {
        final raw = body['promotions'];
        if (raw is! List) return <SitterPromotion>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(SitterPromotion.fromJson)
            .toList();
      },
    );
  }

  Future<SitterPromotion> createPromotion({int discountPercent = 10}) async {
    final response = await _api.postAuth(
      _script,
      action: 'create_promotion',
      body: {'discount_percent': discountPercent},
    );
    return _api.parse(
      response,
      (body) =>
          SitterPromotion.fromJson(body['promotion'] as Map<String, dynamic>),
    );
  }
}
