import 'package:kaki_empat/core/services/v2_api_client.dart';

class LoyaltyProfile {
  const LoyaltyProfile({
    required this.points,
    required this.redeemRate,
    required this.redeemValue,
    required this.redeemableDiscount,
  });

  final int points;
  final int redeemRate;
  final int redeemValue;
  final int redeemableDiscount;

  factory LoyaltyProfile.fromJson(Map<String, dynamic> json) {
    return LoyaltyProfile(
      points: (json['points'] as num?)?.toInt() ?? 0,
      redeemRate: (json['redeem_rate'] as num?)?.toInt() ?? 100,
      redeemValue: (json['redeem_value'] as num?)?.toInt() ?? 10000,
      redeemableDiscount: (json['redeemable_discount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReferralProfile {
  const ReferralProfile({
    required this.referralCode,
    required this.bonusReferrer,
    required this.discountRefereePercent,
  });

  final String referralCode;
  final int bonusReferrer;
  final int discountRefereePercent;

  factory ReferralProfile.fromJson(Map<String, dynamic> json) {
    return ReferralProfile(
      referralCode: '${json['referral_code'] ?? ''}',
      bonusReferrer: (json['bonus_referrer'] as num?)?.toInt() ?? 20000,
      discountRefereePercent:
          (json['discount_referee_percent'] as num?)?.toInt() ?? 10,
    );
  }
}

class UserV2Service {
  UserV2Service({V2ApiClient? client}) : _api = client ?? V2ApiClient.instance;

  static final UserV2Service instance = UserV2Service();

  final V2ApiClient _api;
  static const _script = 'user_v2.php';

  Future<LoyaltyProfile> getLoyaltyPoints() async {
    final response = await _api.getAuth(_script, action: 'get_loyalty_points');
    return _api.parse(response, LoyaltyProfile.fromJson);
  }

  Future<ReferralProfile> getReferralCode() async {
    final response = await _api.getAuth(_script, action: 'get_referral_code');
    return _api.parse(response, ReferralProfile.fromJson);
  }

  Future<int> redeemLoyalty({required int points}) async {
    final response = await _api.postAuth(
      _script,
      action: 'redeem_loyalty',
      body: {'points': points},
    );
    return _api.parse(
      response,
      (body) => (body['remaining_points'] as num?)?.toInt() ?? 0,
    );
  }
}
