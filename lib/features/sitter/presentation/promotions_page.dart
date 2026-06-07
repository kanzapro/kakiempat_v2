import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/business_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/features/shared/widgets/v2_empty_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  List<SitterPromotion> _promotions = [];
  bool _loading = true;
  bool _creating = false;
  String? _error;

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
      final items = await BusinessV2Service.instance.listMyPromotions();
      if (!mounted) return;
      setState(() {
        _promotions = items;
        _loading = false;
      });
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.loadFailed;
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _creating = true);
    try {
      await BusinessV2Service.instance.createPromotion(discountPercent: 10);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.promoCreateSuccess)),
      );
      await _load();
    } on V2ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.promoTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creating ? null : _create,
        icon: _creating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.local_offer_outlined),
        label: Text(l10n.promoCreate),
      ),
      body: V2Responsive.constrain(
        _loading
            ? const V2ListSkeleton()
            : _error != null && _promotions.isEmpty
                ? V2ErrorState(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _promotions.isEmpty
                        ? ListView(
                            children: [
                              V2EmptyState(
                                message: l10n.promoEmpty,
                                icon: Icons.local_offer_outlined,
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: V2Responsive.pagePadding(context),
                            itemCount: _promotions.length,
                            itemBuilder: (context, index) {
                              final p = _promotions[index];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.local_offer),
                                  title: Text(p.code),
                                  subtitle: Text(
                                    l10n.promoDiscountLabel(p.discountPercent),
                                  ),
                                  trailing: Chip(
                                    label: Text(
                                      p.isActive ? l10n.promoActive : l10n.promoUsed,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
        context,
      ),
    );
  }
}
