import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';

class SitterV2Service {
  SitterV2Service({V2ApiClient? client}) : _api = client ?? V2ApiClient.instance;

  static final SitterV2Service instance = SitterV2Service();

  final V2ApiClient _api;
  static const _script = 'sitter_v2.php';

  Future<SitterProfileResult> getProfile() async {
    final response = await _api.getAuth(_script, action: 'get_profile');
    return _api.parse(response, SitterProfileResult.fromJson);
  }

  Future<SitterProfileResult> saveProfile({
    required String address,
    required String bio,
    required List<String> services,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _api.postAuth(
      _script,
      action: 'save_profile',
      body: {
        'address': address,
        'bio': bio,
        'services': services,
        'latitude': ?latitude,
        'longitude': ?longitude,
      },
    );
    return _api.parse(response, SitterProfileResult.fromJson);
  }

  Future<void> uploadVerification({
    required String ktpData,
    required String selfieData,
  }) async {
    final response = await _api.postAuth(
      _script,
      action: 'upload_verification',
      body: {
        'ktp_data': ktpData,
        'selfie_data': selfieData,
      },
    );
    await _api.parse<void>(response, (_) {});
  }

  Future<void> submitVerification() async {
    final response = await _api.postAuth(
      _script,
      action: 'submit_verification',
    );
    await _api.parse<void>(response, (_) {});
  }

  Future<SitterProfileResult> setAvailability({required bool isAvailable}) async {
    final response = await _api.postAuth(
      _script,
      action: 'set_availability',
      body: {'is_available': isAvailable},
    );
    return _api.parse(response, SitterProfileResult.fromJson);
  }

  Future<Map<String, dynamic>> getBadges(String sitterId) async {
    final response = await _api.getAuth(
      _script,
      action: 'get_badges',
      query: {'sitter_id': sitterId},
    );
    return _api.parse(response, (body) => body);
  }
}
