import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';

class OwnerV2Service {
  OwnerV2Service({V2ApiClient? client}) : _api = client ?? V2ApiClient.instance;

  static final OwnerV2Service instance = OwnerV2Service();

  final V2ApiClient _api;
  static const _script = 'owner_v2.php';

  Future<OwnerProfileResult> getProfile() async {
    final response = await _api.getAuth(_script, action: 'get_profile');
    return _api.parse(response, OwnerProfileResult.fromJson);
  }

  /// BFF agregat — profil, katalog, booking, permintaan terbuka (1 request).
  Future<OwnerDashboardResult> getDashboard() async {
    final response = await _api.getAuth(_script, action: 'get_dashboard');
    return _api.parse(response, OwnerDashboardResult.fromJson);
  }

  Future<OwnerProfileResult> saveProfile({
    required String address,
    required String kecamatan,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _api.postAuth(
      _script,
      action: 'save_profile',
      body: {
        'address': address,
        'kecamatan': kecamatan,
        'latitude': ?latitude,
        'longitude': ?longitude,
      },
    );
    return _api.parse(response, OwnerProfileResult.fromJson);
  }

  Future<PetV2> addPet({
    required String name,
    required String species,
    String breed = '',
    String age = '',
    double? weight,
    String notes = '',
  }) async {
    final response = await _api.postAuth(
      _script,
      action: 'add_pet',
      body: {
        'name': name,
        'species': species,
        if (breed.isNotEmpty) 'breed': breed,
        if (age.isNotEmpty) 'age': age,
        'weight': ?weight,
        if (notes.isNotEmpty) 'notes': notes,
      },
    );
    return _api.parse(
      response,
      (body) => PetV2.fromJson(body['pet'] as Map<String, dynamic>),
    );
  }

  Future<PetV2> updatePet({
    required String petId,
    required String name,
    required String species,
    String breed = '',
    String age = '',
    double? weight,
    String notes = '',
  }) async {
    final response = await _api.postAuth(
      _script,
      action: 'update_pet',
      body: {
        'pet_id': petId,
        'name': name,
        'species': species,
        if (breed.isNotEmpty) 'breed': breed,
        if (age.isNotEmpty) 'age': age,
        'weight': ?weight,
        if (notes.isNotEmpty) 'notes': notes,
      },
    );
    return _api.parse(
      response,
      (body) => PetV2.fromJson(body['pet'] as Map<String, dynamic>),
    );
  }

  Future<PetTimelineResult> getPetTimeline(String petId) async {
    final response = await _api.getAuth(
      _script,
      action: 'get_pet_timeline',
      query: {'pet_id': petId},
    );
    return _api.parse(response, PetTimelineResult.fromJson);
  }

  Future<void> deletePet(String petId) async {
    final response = await _api.postAuth(
      _script,
      action: 'delete_pet',
      body: {'pet_id': petId},
    );
    await _api.parse<void>(response, (_) {});
  }
}
