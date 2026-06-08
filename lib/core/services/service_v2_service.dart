import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';

class ServiceV2Service {
  ServiceV2Service({V2ApiClient? client}) : _api = client ?? V2ApiClient.instance;

  static final ServiceV2Service instance = ServiceV2Service();

  final V2ApiClient _api;
  static const _script = 'service_v2.php';

  Future<CategorySupplyResult> checkCategorySupply({
    required String category,
    required String kecamatan,
  }) async {
    final response = await _api.getAuth(
      _script,
      action: 'check_category_supply',
      query: {
        'category': category,
        'kecamatan': kecamatan,
      },
    );
    return _api.parse(response, CategorySupplyResult.fromJson);
  }
}
