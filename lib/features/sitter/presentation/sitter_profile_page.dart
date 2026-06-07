import 'package:flutter/material.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/navigation/v2_page_route.dart';
import 'package:kaki_empat/core/services/booking_v2_service.dart';
import 'package:kaki_empat/core/services/service_catalog_v2_service.dart';
import 'package:kaki_empat/core/services/sitter_v2_service.dart';
import 'package:kaki_empat/core/services/sitter_wallet_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/theme/theme_notifier.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/features/shared/presentation/booking_history_page.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/features/sitter/presentation/sitter_onboarding_page.dart';
import 'package:kaki_empat/features/shared/widgets/v2_sitter_badge_row.dart';
import 'package:kaki_empat/features/sitter/presentation/wallet_page.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class SitterProfilePage extends StatefulWidget {
  const SitterProfilePage({super.key});

  @override
  State<SitterProfilePage> createState() => _SitterProfilePageState();
}

class _SitterProfilePageState extends State<SitterProfilePage> {
  SitterProfileResult? _profile;
  Map<String, String> _serviceLabels = {};
  SitterWalletSummary? _wallet;
  List<SitterBadge> _badges = [];
  double? _averageRating;
  int _bookingCount = 0;
  bool _loading = true;
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
      final results = await Future.wait([
        SitterV2Service.instance.getProfile(),
        ServiceCatalogV2Service.instance.getCatalogItems(),
        BookingV2Service.instance.listMyBookings(),
        SitterWalletService.instance.getWallet(),
      ]);
      if (!mounted) return;
      final profile = results[0] as SitterProfileResult;
      final catalog = results[1] as List<ServiceCatalogItem>;
      setState(() {
        _profile = profile;
        _serviceLabels = {for (final item in catalog) item.code: item.label};
        _bookingCount = (results[2] as List).length;
        _wallet = results[3] as SitterWalletSummary;
        _badges = profile.badges.map(SitterBadge.fromJson).toList();
        _averageRating = profile.averageRating;
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

  String _statusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'draft' => l10n.sitterStatusDraft,
      'pending_verification' => l10n.sitterStatusPending,
      'approved' => l10n.sitterStatusApproved,
      'rejected' => l10n.sitterStatusRejected,
      _ => status,
    };
  }

  Future<void> _editProfile() async {
    final ok = await Navigator.of(context).push<bool>(
      V2PageRoute(page: const SitterOnboardingPage(editOnly: true)),
    );
    if (ok == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = _profile?.profile;
    final padding = V2Responsive.pagePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sitterProfileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.actionEditProfile,
            onPressed: _loading ? null : _editProfile,
          ),
        ],
      ),
      body: V2Responsive.constrain(
        _loading
            ? const V2ListSkeleton()
            : _error != null && _profile == null
                ? V2ErrorState(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: padding,
                      children: [
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _error!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$_bookingCount',
                                        style: Theme.of(context).textTheme.headlineSmall,
                                      ),
                                      Text(l10n.profileStatsBookings(_bookingCount)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Text(
                                        V2Formatters.money(_wallet?.netIncome ?? 0),
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      Text(l10n.profileStatsEarnings, textAlign: TextAlign.center),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.darkModeTitle),
                          secondary: Icon(
                            ThemeNotifier.instance.isDark
                                ? Icons.dark_mode
                                : Icons.light_mode_outlined,
                          ),
                          value: ThemeNotifier.instance.isDark,
                          onChanged: (v) => ThemeNotifier.instance.toggleDark(v),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history),
                          title: Text(l10n.profileBookingHistory),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              V2PageRoute(page: const BookingHistoryPage()),
                            );
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.account_balance_wallet_outlined),
                          title: Text(l10n.walletTitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              V2PageRoute(page: const WalletPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.verified_user_outlined),
                            title: Text(l10n.sitterProfileStatus),
                            subtitle: Text(_statusLabel(l10n, profile?.status ?? 'draft')),
                            trailing: profile?.isVerified == true
                                ? Icon(Icons.verified, color: Theme.of(context).colorScheme.primary)
                                : null,
                          ),
                        ),
                        if (_averageRating != null) ...[
                          const SizedBox(height: 8),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.star_outline),
                              title: Text(l10n.earningsAvgRating),
                              subtitle: Text(_averageRating!.toStringAsFixed(1)),
                            ),
                          ),
                        ],
                        if (_badges.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          V2SitterBadgeRow(badges: _badges),
                        ],
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(l10n.sitterProfileAddress),
                            subtitle: Text(
                              profile?.address.isNotEmpty == true
                                  ? profile!.address
                                  : l10n.valueEmpty,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.notes_outlined),
                            title: Text(l10n.sitterProfileBio),
                            subtitle: Text(
                              profile?.bio.isNotEmpty == true ? profile!.bio : l10n.valueEmpty,
                            ),
                            isThreeLine: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.sitterProfileServices, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (_profile?.services.isEmpty ?? true)
                          Text(l10n.valueEmpty)
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _profile!.services.map((code) {
                              return Chip(
                                avatar: const Icon(Icons.pets, size: 16),
                                label: Text(_serviceLabels[code] ?? code),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _editProfile,
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(l10n.actionEditProfile),
                        ),
                      ],
                    ),
                  ),
        context,
      ),
    );
  }
}
