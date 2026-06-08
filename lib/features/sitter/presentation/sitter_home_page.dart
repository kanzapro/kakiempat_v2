import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/navigation/v2_page_route.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';
import 'package:kaki_empat/core/services/booking_v2_service.dart';
import 'package:kaki_empat/core/services/marketplace_v2_service.dart';
import 'package:kaki_empat/core/services/service_catalog_v2_service.dart';
import 'package:kaki_empat/core/services/sitter_v2_service.dart';
import 'package:kaki_empat/core/services/sitter_wallet_service.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/utils/debounce.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/features/auth/presentation/auth_logout.dart';
import 'package:kaki_empat/features/shared/presentation/booking_detail_page.dart';
import 'package:kaki_empat/features/shared/presentation/booking_history_page.dart';
import 'package:kaki_empat/features/shared/widgets/notification_badge_button.dart';
import 'package:kaki_empat/features/shared/widgets/sitter_pulse_dot.dart';
import 'package:kaki_empat/features/shared/widgets/booking_status_chip.dart';
import 'package:kaki_empat/features/shared/widgets/v2_empty_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_infinite_scroll.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/features/shared/widgets/v2_onboarding.dart';
import 'package:kaki_empat/features/shared/widgets/v2_pet_avatar.dart';
import 'package:kaki_empat/features/sitter/presentation/request_detail_page.dart';
import 'package:kaki_empat/features/help/presentation/faq_page.dart';
import 'package:kaki_empat/features/sitter/presentation/earnings_report_page.dart';
import 'package:kaki_empat/features/sitter/presentation/promotions_page.dart';
import 'package:kaki_empat/features/sitter/presentation/sitter_faq_page.dart';
import 'package:kaki_empat/features/sitter/presentation/sitter_profile_page.dart';
import 'package:kaki_empat/features/shared/widgets/v2_app_shell.dart';
import 'package:kaki_empat/features/shared/widgets/v2_app_switcher.dart';
import 'package:kaki_empat/core/web/domain_kind.dart';
import 'package:kaki_empat/features/sitter/presentation/wallet_page.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class SitterHomePage extends StatefulWidget {
  const SitterHomePage({super.key});

  @override
  State<SitterHomePage> createState() => _SitterHomePageState();
}

class _SitterHomePageState extends State<SitterHomePage> {
  static const _pageSize = 8;

  final _filterDebouncer = Debouncer(duration: const Duration(milliseconds: 400));
  final _searchController = TextEditingController();

  SitterProfileResult? _profile;
  List<ServiceCatalogItem> _services = [];
  List<BookingRequestV2> _requests = [];
  List<BookingV2> _bookings = [];
  String? _filterService;
  String _searchQuery = '';
  bool _loading = true;
  Object? _error;
  int _visibleRequests = _pageSize;
  int _visibleBookings = _pageSize;
  Timer? _pollTimer;
  bool _isPolling = false;
  int _newRequestCount = 0;
  final Set<String> _knownRequestIds = {};
  String _userName = '';
  int _monthlyEarnings = 0;
  bool _isAvailable = true;
  bool _togglingAvailability = false;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      _filterDebouncer.run(() {
        if (!mounted) return;
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
          _visibleRequests = _pageSize;
        });
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) V2Onboarding.maybeShowSitter(context);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _filterDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _pollRequests(),
    );
  }

  Future<void> _pollRequests() async {
    if (_profile?.profile?.isApproved != true || !_isAvailable) return;
    setState(() {
      _isPolling = true;
      _newRequestCount = 0;
    });
    try {
      final requests = await MarketplaceV2Service.instance.listRequests(
        serviceType: _filterService,
      );
      if (!mounted) return;
      final newCount = requests
          .where((r) => !_knownRequestIds.contains(r.id))
          .length;
      _knownRequestIds.addAll(requests.map((r) => r.id));
      setState(() {
        _requests = requests;
        _newRequestCount = newCount;
        _isPolling = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPolling = false);
    }
  }

  bool _isFreshRequest(BookingRequestV2 request) {
    if (request.createdAt.isEmpty) return false;
    try {
      final created = DateTime.parse(request.createdAt).toLocal();
      return DateTime.now().difference(created) < const Duration(minutes: 5);
    } catch (_) {
      return false;
    }
  }

  Widget _buildPollingStatus(AppLocalizations l10n, ThemeData theme) {
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Row(
      children: [
        SitterPulseDot(isActive: _isPolling),
        const SizedBox(width: 8),
        Expanded(
          child: _isPolling
              ? Text(l10n.sitterPollingSearching, style: style)
              : Text(
                  _profile?.profile?.kecamatan != null
                      ? '${_requests.length} permintaan di ${_profile!.profile!.kecamatan}'
                      : l10n.sitterRequestsInRadius(_requests.length),
                  style: style,
                ),
        ),
        if (!_isPolling && _newRequestCount > 0)
          Badge(
            label: Text('$_newRequestCount'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.sitterNewRequestsBadge(_newRequestCount),
                style: style?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await SitterV2Service.instance.getProfile();
      final user = await AuthServiceV2.instance.getStoredUser();
      final catalog = await ServiceCatalogV2Service.instance.getCatalogItems();
      List<BookingRequestV2> requests = [];
      List<BookingV2> bookings = [];

      final isApproved = profile.profile?.isApproved == true;
      final isAvailable = profile.profile?.isAvailable ?? true;
      if (isApproved) {
        final futures = <Future<Object?>>[
          BookingV2Service.instance.listMyBookings(),
        ];
        if (isAvailable) {
          futures.insert(
            0,
            MarketplaceV2Service.instance.listRequests(
              serviceType: _filterService,
            ),
          );
        }
        if (!MvpScope.hideSitterWallet) {
          futures.add(SitterWalletService.instance.getWallet());
        }
        final both = await Future.wait(futures);
        var idx = 0;
        if (isAvailable) {
          requests = both[idx++] as List<BookingRequestV2>;
        }
        bookings = both[idx++] as List<BookingV2>;
        if (!MvpScope.hideSitterWallet && both.length > idx) {
          final wallet = both[idx] as SitterWalletSummary;
          _monthlyEarnings = _computeMonthlyEarnings(wallet.entries);
        }
      }

      if (!mounted) return;
      _knownRequestIds
        ..clear()
        ..addAll(requests.map((r) => r.id));
      setState(() {
        _profile = profile;
        _isAvailable = profile.profile?.isAvailable ?? true;
        _userName = user?.name.trim() ?? '';
        _services = catalog.where((s) => profile.services.contains(s.code)).toList();
        _requests = requests;
        _bookings = bookings;
        _loading = false;
        _visibleRequests = _pageSize;
        _visibleBookings = _pageSize;
        _newRequestCount = 0;
        _isPolling = false;
      });
      if (isApproved && isAvailable) {
        _startPolling();
      } else {
        _pollTimer?.cancel();
      }
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

  List<BookingRequestV2> get _filteredRequests {
    if (_searchQuery.isEmpty) return _requests;
    return _requests.where((req) {
      final label = req.serviceLabel.isNotEmpty
          ? req.serviceLabel
          : V2Formatters.serviceLabel(req.serviceCode);
      final addr = req.location?.address ?? '';
      return label.toLowerCase().contains(_searchQuery) ||
          addr.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  String _serviceLabel(BookingRequestV2 request) {
    if (request.serviceLabel.isNotEmpty) return request.serviceLabel;
    return V2Formatters.serviceLabel(request.serviceCode);
  }

  String _scheduleLabel(BookingRequestV2 request) {
    if (request.dateLabel.isNotEmpty) {
      return request.timeRange.isNotEmpty
          ? '${request.dateLabel} · ${request.timeRange}'
          : request.dateLabel;
    }
    return V2Formatters.dateTime(request.scheduledAt);
  }

  void _openRequest(BookingRequestV2 request) {
    Navigator.of(context)
        .push<bool>(V2PageRoute(page: RequestDetailPage(request: request)))
        .then((ok) {
      if (ok == true) _load();
    });
  }

  int _computeMonthlyEarnings(List<WalletLedgerEntry> entries) {
    final now = DateTime.now();
    return entries
        .where((e) {
          if (e.amount <= 0 || e.type == 'withdrawal') return false;
          try {
            final dt = DateTime.parse(e.createdAt).toLocal();
            return dt.year == now.year && dt.month == now.month;
          } catch (_) {
            return false;
          }
        })
        .fold(0, (sum, e) => sum + e.amount);
  }

  String _petLabel(BookingRequestV2 req) {
    if (req.petNames.isNotEmpty) {
      final labels = <String>[];
      for (var i = 0; i < req.petNames.length; i++) {
        final species = i < req.petSpecies.length ? req.petSpecies[i] : '';
        labels.add(
          V2Formatters.petDisplayLabel(name: req.petNames[i], species: species),
        );
      }
      return labels.join(', ');
    }
    if (req.petIds.isNotEmpty) return 'Hewan #${req.petIds.first}';
    return req.ownerName.isNotEmpty ? req.ownerName : 'Hewan peliharaan';
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _togglingAvailability = true);
    try {
      final updated = await SitterV2Service.instance.setAvailability(isAvailable: value);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _isAvailable = value;
        _togglingAvailability = false;
        if (!value) {
          _requests = [];
          _newRequestCount = 0;
        }
      });
      if (value) {
        _startPolling();
        await _load();
      } else {
        _pollTimer?.cancel();
      }
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() => _togglingAvailability = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _togglingAvailability = false);
    }
  }

  String _displayName() {
    final name = _userName.trim();
    return name.isNotEmpty ? name : 'Sitter';
  }

  int get _freshRequestCount =>
      _requests.where(_isFreshRequest).length;

  List<BookingV2> get _activeBookings => _bookings.where((b) {
        final s = b.status.toLowerCase();
        return s != 'completed' && s != 'cancelled';
      }).toList();

  void _loadMoreIfNeeded() {
    var changed = false;
    if (_visibleRequests < _filteredRequests.length) {
      _visibleRequests =
          (_visibleRequests + _pageSize).clamp(0, _filteredRequests.length);
      changed = true;
    }
    if (_visibleBookings < _bookings.length) {
      _visibleBookings =
          (_visibleBookings + _pageSize).clamp(0, _bookings.length);
      changed = true;
    }
    if (changed) setState(() {});
  }

  void _openBooking(BookingV2 booking) {
    Navigator.of(context)
        .push(V2PageRoute<void>(page: BookingDetailPage(bookingId: booking.id)))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final approved = _profile?.profile?.isApproved == true;
    final padding = V2Responsive.pagePadding(context);
    final filtered = _filteredRequests;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sitterHomeTitle),
        bottom: approved
            ? PreferredSize(
                preferredSize: const Size.fromHeight(32),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _buildPollingStatus(l10n, theme),
                  ),
                ),
              )
            : null,
        actions: [
          if (MvpScope.showAppSwitcher)
            const V2AppSwitcher(currentDomain: WebDomain.sitter),
          Tooltip(
            message: l10n.tooltipNotifications,
            child: const NotificationBadgeButton(),
          ),
          if (!MvpScope.hideSitterWallet)
            Tooltip(
              message: l10n.walletTitle,
              child: IconButton(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                onPressed: () {
                  Navigator.of(context).push(V2PageRoute(page: const WalletPage()));
                },
              ),
            ),
          Tooltip(
            message: l10n.tooltipProfile,
            child: IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.of(context).push(
                  V2PageRoute(page: const SitterProfilePage()),
                );
              },
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              final page = switch (value) {
                'earnings' => const EarningsReportPage(),
                'promo' => const PromotionsPage(),
                'faq' => const FaqPage(isOwner: false),
                'tips' => const SitterFaqPage(),
                _ => const SitterFaqPage(),
              };
              Navigator.of(context).push(V2PageRoute(page: page));
            },
            itemBuilder: (ctx) => [
              if (!MvpScope.hideSitterWallet)
                PopupMenuItem(value: 'earnings', child: Text(l10n.earningsReportTitle)),
              if (!MvpScope.hideSitterPromotions)
                PopupMenuItem(value: 'promo', child: Text(l10n.promoTitle)),
              PopupMenuItem(value: 'faq', child: Text(l10n.helpFaqTitle)),
              PopupMenuItem(value: 'tips', child: Text(l10n.sitterFaqTitle)),
            ],
          ),
          Tooltip(
            message: l10n.tooltipBookingHistory,
            child: IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                V2PageRoute(page: const BookingHistoryPage()),
              );
            },
          ),
          ),
          Tooltip(
            message: l10n.tooltipLogout,
            child: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => performAuthLogout(context),
          ),
          ),
        ],
      ),
      body: V2Responsive.constrain(
        _loading
            ? const V2ListSkeleton()
            : _error != null && _profile == null
                ? V2ErrorState.fromError(context, error: _error, onRetry: _load)
                : V2InfiniteScroll(
                    onLoadMore: _loadMoreIfNeeded,
                    enabled: _visibleRequests < filtered.length ||
                        _visibleBookings < _activeBookings.length,
                    child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: padding,
                      children: [
                        if (approved) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SitterPulseDot(),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _freshRequestCount > 0
                                          ? l10n.sitterGreeting(
                                              _displayName(),
                                              _freshRequestCount,
                                            )
                                          : l10n.sitterGreetingNoRequests(_displayName()),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        height: 1.25,
                                      ),
                                    ),
                                    if (!MvpScope.hideSitterPromotions && _monthlyEarnings > 0) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.sitterMonthlyEarnings(
                                          V2Formatters.money(_monthlyEarnings),
                                        ),
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const V2GrowthHubSection(),
                          Card(
                            child: SwitchListTile(
                              title: Text(l10n.sitterAvailabilityTitle),
                              subtitle: !_isAvailable
                                  ? Text(l10n.sitterAvailabilityOffHint)
                                  : null,
                              value: _isAvailable,
                              onChanged: _togglingAvailability ? null : _toggleAvailability,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (!approved)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified_user_outlined),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(l10n.sitterVerificationRequired)),
                                ],
                              ),
                            ),
                          ),
                        if (approved) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.sitterRequestsTitle,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  _profile?.profile?.kecamatan?.isNotEmpty == true
                                      ? _profile!.profile!.kecamatan!
                                      : l10n.sitterBroadcastRadiusBadge,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: l10n.searchHint,
                              prefixIcon: const Icon(Icons.search),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String?>(
                            initialValue: _filterService,
                            decoration: InputDecoration(
                              labelText: l10n.sitterFilterService,
                              isDense: true,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(l10n.sitterFilterAllServices),
                              ),
                              ..._services.map(
                                (s) => DropdownMenuItem(
                                  value: s.code,
                                  child: Text(s.label),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _filterService = v);
                              _filterDebouncer.run(_load);
                            },
                          ),
                          const SizedBox(height: 16),
                          if (filtered.isEmpty)
                            V2EmptyState(
                              message: l10n.sitterRequestsEmpty,
                              emoji: '☕',
                            )
                          else ...[
                            ...filtered.take(_visibleRequests).map((req) {
                              return _SitterRequestCard(
                                request: req,
                                petLabel: _petLabel(req),
                                serviceLabel: _serviceLabel(req),
                                scheduleLabel: _scheduleLabel(req),
                                isFresh: _isFreshRequest(req),
                                onOffer: () => _openRequest(req),
                              );
                            }),
                            if (_visibleRequests < filtered.length)
                              OutlinedButton(
                                onPressed: () => setState(
                                  () => _visibleRequests += _pageSize,
                                ),
                                child: Text(l10n.loadMore),
                              ),
                          ],
                          const Divider(height: 32),
                          Text(l10n.sitterActiveBookingsTitle, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          if (_activeBookings.isEmpty)
                            V2EmptyState(
                              message: l10n.sitterActiveBookingsEmpty,
                              icon: Icons.event_available_outlined,
                            )
                          else ...[
                            ..._activeBookings.take(_visibleBookings).map((b) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.event_available_outlined),
                                  title: Text(
                                    b.serviceCode.isNotEmpty
                                        ? V2Formatters.serviceLabel(b.serviceCode)
                                        : '#${b.id}',
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      BookingStatusChip(status: b.status),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${V2Formatters.dateTime(b.scheduledAt)} · ${V2Formatters.money(b.paymentAmount)}',
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _openBooking(b),
                                ),
                              );
                            }),
                            if (_visibleBookings < _activeBookings.length)
                              OutlinedButton(
                                onPressed: () => setState(
                                  () => _visibleBookings += _pageSize,
                                ),
                                child: Text(l10n.loadMore),
                              ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  ),
        context,
      ),
    );
  }
}

class _SitterRequestCard extends StatelessWidget {
  const _SitterRequestCard({
    required this.request,
    required this.petLabel,
    required this.serviceLabel,
    required this.scheduleLabel,
    required this.isFresh,
    required this.onOffer,
  });

  final BookingRequestV2 request;
  final String petLabel;
  final String serviceLabel;
  final String scheduleLabel;
  final bool isFresh;
  final VoidCallback onOffer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                V2PetAvatar(
                  petId: request.petIds.isNotEmpty ? request.petIds.first : request.id,
                  size: 56,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              petLabel,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (isFresh) const SitterPulseDot(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('$serviceLabel · $scheduleLabel'),
                      if (request.distanceKm != null)
                        Text(
                          l10n.sitterRequestDistanceFromYou(
                            request.distanceKm!.toStringAsFixed(1),
                          ),
                        ),
                      Text('💰 ${V2Formatters.money(request.totalPrice)}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOffer,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.offerGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.sitterOfferPrice),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
