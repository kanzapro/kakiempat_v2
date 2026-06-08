import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/services/partner_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/core/web/web_nav.dart';
import 'package:kaki_empat/features/shared/widgets/v2_empty_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Discover tab — partner / mini-service registry (fase full).
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<PartnerServiceV2> _services = [];
  List<BusinessPartnerV2> _businesses = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        PartnerV2Service.instance.listServices(),
        PartnerV2Service.instance.listBusinesses(),
      ]);
      if (!mounted) return;
      setState(() {
        _services = results[0] as List<PartnerServiceV2>;
        _businesses = results[1] as List<BusinessPartnerV2>;
        _loading = false;
      });
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _openPartner(PartnerServiceV2 service) {
    if (service.actionUrl.isEmpty) return;
    navigateToUrl(service.actionUrl);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final padding = V2Responsive.pagePadding(context);

    if (!MvpScope.showPartnerDiscover) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.discoverTitle)),
        body: Center(child: Text(l10n.discoverComingSoon)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.discoverTitle)),
      body: V2Responsive.constrain(
        _loading
            ? const V2ListSkeleton()
            : _error != null && _services.isEmpty
                ? V2ErrorState.fromError(context, error: _error, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _services.isEmpty && _businesses.isEmpty
                        ? ListView(
                            padding: padding,
                            children: [
                              V2EmptyState(
                                message: l10n.discoverEmpty,
                                icon: Icons.explore_outlined,
                              ),
                            ],
                          )
                        : ListView(
                            padding: padding,
                            children: [
                              if (_businesses.isNotEmpty) ...[
                                Text(
                                  l10n.discoverBusinessesTitle,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                ..._businesses.map(
                                  (business) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const Icon(Icons.storefront_outlined),
                                      title: Text(business.legalName),
                                      subtitle: Text(
                                        [
                                          if (business.locationKecamatan.isNotEmpty)
                                            business.locationKecamatan,
                                          if (business.serviceCodes.isNotEmpty)
                                            business.serviceCodes.join(', '),
                                        ].join(' · '),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (_services.isNotEmpty) ...[
                                Text(
                                  l10n.discoverServicesTitle,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                ..._services.map(
                                  (service) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: Text(
                                        service.logoEmoji,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      title: Text(service.name),
                                      subtitle: Text(
                                        service.description.isNotEmpty
                                            ? service.description
                                            : service.category,
                                      ),
                                      trailing: const Icon(Icons.open_in_new),
                                      onTap: () => _openPartner(service),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
        context,
      ),
    );
  }
}
