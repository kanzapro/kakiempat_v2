import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/navigation/v2_page_route.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/core/services/owner_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/features/auth/presentation/auth_logout.dart';
import 'package:kaki_empat/features/owner/presentation/add_pet_page.dart';
import 'package:kaki_empat/features/owner/presentation/create_request_page.dart';
import 'package:kaki_empat/features/owner/presentation/owner_profile_page.dart';
import 'package:kaki_empat/features/owner/presentation/owner_profile_setup_page.dart';
import 'package:kaki_empat/features/owner/presentation/owner_request_offers_page.dart';
import 'package:kaki_empat/features/owner/presentation/payment_guide_page.dart';
import 'package:kaki_empat/features/shared/presentation/booking_detail_page.dart';
import 'package:kaki_empat/features/shared/presentation/booking_history_page.dart';
import 'package:kaki_empat/features/shared/widgets/notification_badge_button.dart';
import 'package:kaki_empat/features/shared/widgets/v2_app_switcher.dart';
import 'package:kaki_empat/features/shared/widgets/v2_app_shell.dart';
import 'package:kaki_empat/core/web/domain_kind.dart';
import 'package:kaki_empat/features/shared/widgets/booking_status_chip.dart';
import 'package:kaki_empat/features/shared/widgets/service_category_icon.dart';
import 'package:kaki_empat/features/shared/widgets/v2_empty_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_infinite_scroll.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/features/shared/widgets/v2_onboarding.dart';
import 'package:kaki_empat/features/community/presentation/pet_gallery_page.dart';
import 'package:kaki_empat/features/community/presentation/stori_feed_page.dart';
import 'package:kaki_empat/features/help/presentation/faq_page.dart';
import 'package:kaki_empat/features/help/presentation/tips_articles_page.dart';
import 'package:kaki_empat/features/shared/widgets/v2_owner_stories_section.dart';
import 'package:kaki_empat/features/shared/widgets/v2_pet_avatar.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key, this.awaitingPaymentBookingId});

  final String? awaitingPaymentBookingId;

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  static const _pageSize = 5;

  OwnerProfileResult? _profile;
  List<ServiceCategoryGroup> _categories = [];
  List<BookingRequestV2> _openRequests = [];
  List<BookingV2> _bookings = [];
  List<OwnerRecommendationV2> _recommendations = [];
  bool _loading = true;
  Object? _error;
  int _visibleRequests = _pageSize;
  int _visibleBookings = _pageSize;
  String _ownerName = '';

  @override
  void initState() {
    super.initState();
    _load();
    _maybeOpenPayment();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) V2Onboarding.maybeShowOwner(context);
    });
  }

  Future<void> _maybeOpenPayment() async {
    final id = widget.awaitingPaymentBookingId?.trim();
    if (id == null || id.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        V2PageRoute<void>(page: PaymentGuidePage(bookingId: id)),
      );
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dashboard = await OwnerV2Service.instance.getDashboard();
      if (!mounted) return;
      setState(() {
        _profile = dashboard.owner;
        _categories = dashboard.catalog.categories;
        _bookings = dashboard.bookings;
        _openRequests = dashboard.requests;
        _recommendations = dashboard.recommendations;
        _ownerName = dashboard.userName;
        _loading = false;
        _visibleRequests = _pageSize;
        _visibleBookings = _pageSize;
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

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      V2PageRoute(page: const OwnerProfilePage()),
    );
    await _load();
  }

  Future<void> _openProfileSetup() async {
    final ok = await Navigator.of(context).push<bool>(
      V2PageRoute(
        page: OwnerProfileSetupPage(
          initialAddress: _profile?.profile?.address ?? '',
        ),
      ),
    );
    if (ok == true) await _load();
  }

  Future<void> _openAddPet() async {
    final ok = await Navigator.of(context).push<bool>(
      V2PageRoute(page: const AddPetPage()),
    );
    if (ok == true) await _load();
  }

  Future<void> _openCategory(ServiceCategoryGroup category) async {
    final pets = _profile?.pets ?? [];
    if (_profile?.needsOnboarding == true || pets.isEmpty) return;
    final refreshed = await Navigator.of(context).push<bool>(
      V2PageRoute<bool>(
        page: _OwnerCategoryServicesPage(
          category: category,
          pets: pets,
          profile: _profile?.profile,
        ),
      ),
    );
    if (refreshed == true) await _load();
  }

  Future<void> _openRequestOffers(BookingRequestV2 request) async {
    final ok = await Navigator.of(context).push<bool>(
      V2PageRoute<bool>(page: OwnerRequestOffersPage(request: request)),
    );
    if (ok == true) await _load();
  }

  String _requestSchedule(BookingRequestV2 request) {
    if (request.dateLabel.isNotEmpty && request.timeRange.isNotEmpty) {
      return '${request.dateLabel} · ${request.timeRange}';
    }
    if (request.dateLabel.isNotEmpty) return request.dateLabel;
    return V2Formatters.dateTime(request.scheduledAt);
  }

  String _serviceLabelForRequest(BookingRequestV2 request) {
    if (request.serviceLabel.isNotEmpty) return request.serviceLabel;
    return V2Formatters.serviceLabel(request.serviceCode);
  }

  Future<void> _openBooking(BookingV2 booking) async {
    await Navigator.of(context).push<void>(
      V2PageRoute<void>(page: BookingDetailPage(bookingId: booking.id)),
    );
    await _load();
  }

  Future<void> _openFirstCategoryWithService() async {
    for (final cat in _categories) {
      if (cat.services.isNotEmpty) {
        await _openCategory(cat);
        return;
      }
    }
  }

  List<BookingV2> get _activeBookings => _bookings.where((b) {
        final s = b.status.toLowerCase();
        return s != 'completed' && s != 'cancelled';
      }).toList();

  List<BookingRequestV2> get _requestsWithOffers => _openRequests
      .where((r) => r.pendingOfferCount > 0)
      .toList();

  void _loadMoreIfNeeded() {
    if (_visibleRequests < _openRequests.length) {
      setState(() => _visibleRequests += _pageSize);
    } else if (_visibleBookings < _bookings.length) {
      setState(() => _visibleBookings += _pageSize);
    }
  }

  String _ownerDisplayName() {
    if (_ownerName.isNotEmpty) return _ownerName;
    final name = _profile?.profile?.fullName.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Owner';
  }

  static const _popularCategoryCodes = ['sports', 'boarding', 'grooming', 'health'];

  List<ServiceCategoryGroup> get _popularCategories {
    final popular = <ServiceCategoryGroup>[];
    for (final code in _popularCategoryCodes) {
      for (final cat in _categories) {
        if (cat.code == code) {
          popular.add(cat);
          break;
        }
      }
    }
    if (popular.isNotEmpty) return popular;
    return _categories.take(4).toList();
  }

  ServiceCategoryGroup? _categoryByCode(String code) {
    for (final cat in _categories) {
      if (cat.code == code) return cat;
    }
    return null;
  }

  Future<void> _openCategoryByCode(String code) async {
    final cat = _categoryByCode(code);
    if (cat != null) await _openCategory(cat);
  }

  Future<void> _handleRecommendation(OwnerRecommendationV2 item) async {
    switch (item.action) {
      case 'open_catalog':
        await _openFirstCategoryWithService();
      case 'open_service':
        final code = item.payload['service_code'];
        if (code != null && code.isNotEmpty) {
          await _openCategoryByCode(code);
        }
      case 'open_tips':
        if (!mounted) return;
        await Navigator.of(context).push(
          V2PageRoute(page: const TipsArticlesPage()),
        );
      default:
        await _openFirstCategoryWithService();
    }
  }

  String _popularEmoji(String code) => switch (code) {
        'sports' => '🐕',
        'boarding' => '🏠',
        'grooming' => '✂️',
        'health' => '🩺',
        _ => '🐾',
      };

  void _showAllServicesSheet() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(l10n.ownerViewAllServices, style: theme.textTheme.titleLarge),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Text(_popularEmoji(cat.code), style: const TextStyle(fontSize: 24)),
                          title: Text(cat.label),
                          subtitle: Text(l10n.ownerCategoryServiceCount(cat.serviceCount)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(ctx);
                            _openCategory(cat);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canBook = _profile?.onboardingComplete == true;
    final pets = _profile?.pets ?? [];
    final padding = V2Responsive.pagePadding(context);
    final columns = V2Responsive.gridColumns(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ownerHomeTitle),
        actions: [
          if (MvpScope.showAppSwitcher)
            const V2AppSwitcher(currentDomain: WebDomain.owner),
          Tooltip(
            message: l10n.tooltipNotifications,
            child: const NotificationBadgeButton(),
          ),
          Tooltip(
            message: l10n.tooltipProfile,
            child: IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: _openProfile,
            ),
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
      floatingActionButton: canBook
          ? FloatingActionButton.extended(
              onPressed: _openFirstCategoryWithService,
              tooltip: l10n.ownerCreateRequestFabHint,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(l10n.ownerCreateRequestFab),
            )
          : null,
      body: V2Responsive.constrain(
        _loading
            ? V2GridSkeleton(columns: columns)
            : _error != null && _profile == null
                ? V2ErrorState.fromError(context, error: _error, onRetry: _load)
                : V2InfiniteScroll(
                    onLoadMore: _loadMoreIfNeeded,
                    enabled: _visibleRequests < _openRequests.length ||
                        _visibleBookings < _bookings.length,
                    child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: padding,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              child: Text(
                                _ownerDisplayName().isNotEmpty
                                    ? _ownerDisplayName()[0].toUpperCase()
                                    : '🐾',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                l10n.ownerGreeting(_ownerDisplayName()),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const V2GrowthHubSection(),
                        if (MvpScope.showPersonalizedRecommendations &&
                            _recommendations.isNotEmpty) ...[
                          Text(
                            l10n.ownerRecommendationsTitle,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._recommendations.map(
                            (rec) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.auto_awesome_outlined),
                                title: Text(rec.title),
                                subtitle: rec.subtitle.isNotEmpty
                                    ? Text(rec.subtitle)
                                    : null,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _handleRecommendation(rec),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_profile?.needsOnboarding == true)
                          Card(
                            color: theme.colorScheme.primaryContainer,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.ownerOnboardingBannerTitle,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(l10n.ownerOnboardingBannerBody),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      FilledButton(
                                        onPressed: _openProfileSetup,
                                        child: Text(l10n.ownerFillAddress),
                                      ),
                                      OutlinedButton(
                                        onPressed: _openAddPet,
                                        child: Text(l10n.ownerAddPet),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_requestsWithOffers.isNotEmpty) ...[
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_offer_outlined,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          l10n.ownerActionOffersBanner(
                                            _requestsWithOffers.length,
                                          ),
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.ownerActionOffersBannerBody,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._requestsWithOffers.map(
                                    (request) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openRequestOffers(request),
                                        icon: const Icon(Icons.local_offer_outlined),
                                        label: Text(
                                          l10n.ownerOffersForRequest(
                                            _serviceLabelForRequest(request),
                                            request.pendingOfferCount,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        Text(l10n.ownerPetsTitle, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (pets.isEmpty)
                          V2EmptyState(
                            message: l10n.ownerAddFirstPetCta,
                            icon: Icons.pets_outlined,
                            actionLabel: l10n.ownerAddPet,
                            onAction: _openAddPet,
                          )
                        else
                          SizedBox(
                            height: 148,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: pets.length + 1,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                if (index == pets.length) {
                                  return InkWell(
                                    onTap: _openAddPet,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: 140,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: theme.colorScheme.outlineVariant),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add, color: theme.colorScheme.primary),
                                          const SizedBox(height: 4),
                                          Text(l10n.ownerAddPet, style: theme.textTheme.labelSmall),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                final pet = pets[index];
                                return Container(
                                  width: 168,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          V2PetAvatar(petId: pet.id, size: 40),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              pet.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: [
                                          _PetQuickChip(
                                            label: l10n.ownerPetQuickWalk,
                                            onTap: canBook
                                                ? () => _openCategoryByCode('sports')
                                                : null,
                                          ),
                                          _PetQuickChip(
                                            label: l10n.ownerPetQuickBath,
                                            onTap: canBook
                                                ? () => _openCategoryByCode('grooming')
                                                : null,
                                          ),
                                          _PetQuickChip(
                                            label: l10n.ownerPetQuickCheckup,
                                            onTap: canBook
                                                ? () => _openCategoryByCode('health')
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                        Text(l10n.ownerHomeSubtitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        _PopularServicesGrid(
                          categories: _popularCategories,
                          enabled: canBook,
                          emojiFor: _popularEmoji,
                          onTap: _openCategory,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: _categories.isEmpty ? null : _showAllServicesSheet,
                            icon: const Icon(Icons.grid_view_rounded),
                            label: Text(l10n.ownerViewAllServices),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(l10n.ownerActiveBookings, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        if (_activeBookings.isEmpty)
                          V2EmptyState(
                            message: l10n.ownerActiveBookingsEmpty,
                            emoji: '📅',
                          )
                        else
                          ..._activeBookings.take(3).map((b) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                              child: ListTile(
                                leading: Icon(
                                  Icons.event_available_outlined,
                                  color: theme.colorScheme.primary,
                                ),
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
                                    Text(V2Formatters.dateTime(b.scheduledAt)),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openBooking(b),
                              ),
                            );
                          }),
                        if (!MvpScope.hideOwnerFavorites) ...[
                          const SizedBox(height: 24),
                          Text(l10n.ownerFavoriteSittersTitle, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          V2EmptyState(
                            message: l10n.ownerFavoriteSittersEmpty,
                            icon: Icons.favorite_border,
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(l10n.ownerOpenRequestsTitle, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (_openRequests.isEmpty)
                          V2EmptyState(
                            message: l10n.ownerOpenRequestsEmpty,
                            icon: Icons.campaign_outlined,
                          )
                        else ...[
                          ..._openRequests.take(_visibleRequests).map((req) {
                            final serviceLabel = req.serviceLabel.isNotEmpty
                                ? req.serviceLabel
                                : V2Formatters.serviceLabel(req.serviceCode);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.campaign_outlined),
                                title: Text(serviceLabel),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    BookingStatusChip(status: req.status),
                                    const SizedBox(height: 6),
                                    Text(_requestSchedule(req)),
                                    Text(l10n.ownerPendingOffers(req.pendingOfferCount)),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openRequestOffers(req),
                              ),
                            );
                          }),
                          if (_visibleRequests < _openRequests.length)
                            OutlinedButton(
                              onPressed: () => setState(
                                () => _visibleRequests += _pageSize,
                              ),
                              child: Text(l10n.loadMore),
                            ),
                        ],
                        const SizedBox(height: 24),
                        Text(l10n.ownerMyBookings, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (_bookings.isEmpty)
                          V2EmptyState(
                            message: l10n.ownerBookingsEmpty,
                            icon: Icons.event_note_outlined,
                            actionLabel: canBook ? l10n.ownerCreateRequestFab : null,
                            onAction: canBook ? _openFirstCategoryWithService : null,
                          )
                        else ...[
                          ..._bookings.take(_visibleBookings).map((b) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.event_note_outlined),
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
                          if (_visibleBookings < _bookings.length)
                            OutlinedButton(
                              onPressed: () => setState(
                                () => _visibleBookings += _pageSize,
                              ),
                              child: Text(l10n.loadMore),
                            ),
                        ],
                        if (!MvpScope.hideCommunityFeatures) ...[
                          const SizedBox(height: 24),
                          const V2OwnerStoriesSection(),
                          const SizedBox(height: 12),
                          Text(l10n.ownerMenuCommunity, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.auto_stories_outlined, size: 18),
                                label: Text(l10n.storiViewFeed),
                                onPressed: () => Navigator.of(context).push(
                                  V2PageRoute(page: const StoriFeedPage()),
                                ),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.article_outlined, size: 18),
                                label: Text(l10n.tipsArticlesTitle),
                                onPressed: () => Navigator.of(context).push(
                                  V2PageRoute(page: const TipsArticlesPage()),
                                ),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.photo_library_outlined, size: 18),
                                label: Text(l10n.petGalleryTitle),
                                onPressed: () => Navigator.of(context).push(
                                  V2PageRoute(page: const PetGalleryPage()),
                                ),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.help_outline, size: 18),
                                label: Text(l10n.ownerMenuHelp),
                                onPressed: () => Navigator.of(context).push(
                                  V2PageRoute(page: const FaqPage(isOwner: true)),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                V2PageRoute(page: const FaqPage(isOwner: true)),
                              ),
                              icon: const Icon(Icons.help_outline),
                              label: Text(l10n.ownerMenuHelp),
                            ),
                          ),
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

class _PopularServicesGrid extends StatelessWidget {
  const _PopularServicesGrid({
    required this.categories,
    required this.enabled,
    required this.emojiFor,
    required this.onTap,
  });

  final List<ServiceCategoryGroup> categories;
  final bool enabled;
  final String Function(String code) emojiFor;
  final Future<void> Function(ServiceCategoryGroup category) onTap;

  @override
  Widget build(BuildContext context) {
    final crossCount = V2Responsive.isMobile(context)
        ? 2
        : V2Responsive.of(context) == V2ScreenSize.tablet
            ? 2
            : 4;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount.clamp(1, categories.length.clamp(1, 4)),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: crossCount <= 2 ? 1.05 : 0.95,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _PopularServiceTile(
          emoji: emojiFor(cat.code),
          label: cat.label,
          enabled: enabled,
          onTap: () => onTap(cat),
        );
      },
    );
  }
}

class _PetQuickChip extends StatelessWidget {
  const _PetQuickChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _PopularServiceTile extends StatelessWidget {
  const _PopularServiceTile({
    required this.emoji,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: enabled ? null : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerCategoryServicesPage extends StatelessWidget {
  const _OwnerCategoryServicesPage({
    required this.category,
    required this.pets,
    this.profile,
  });

  final ServiceCategoryGroup category;
  final List<PetV2> pets;
  final OwnerProfileV2? profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.label)),
      body: ListView.separated(
        padding: V2Responsive.pagePadding(context),
        itemCount: category.services.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final service = category.services[index];
          return Card(
            child: ListTile(
              leading: Icon(serviceCategoryIcon(category.code)),
              title: Text(service.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final ok = await Navigator.of(context).push<bool>(
                  V2PageRoute<bool>(
                    page: CreateRequestPage(
                      service: service,
                      pets: pets,
                      defaultLocation: profile,
                    ),
                  ),
                );
                if (ok == true && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
