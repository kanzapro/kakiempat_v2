import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';

class ServiceCatalogV2Service {
  ServiceCatalogV2Service({V2ApiClient? client})
      : _api = client ?? V2ApiClient.instance;

  static final ServiceCatalogV2Service instance = ServiceCatalogV2Service();

  final V2ApiClient _api;
  static const _script = 'service_v2.php';

  Future<ServiceCatalogResult> getCatalog() async {
    final response =
        await _api.getAuth(_script, action: 'get_catalog');
    return _api.parse(
      response,
      ServiceCatalogResult.fromJson,
    );
  }

  Future<List<ServiceCatalogItem>> getCatalogItems() async {
    final catalog = await getCatalog();
    return catalog.services;
  }
}
