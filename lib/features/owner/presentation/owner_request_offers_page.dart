import 'package:flutter/material.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/navigation/v2_page_route.dart';
import 'package:kaki_empat/core/services/favorites_service.dart';
import 'package:kaki_empat/core/services/marketplace_v2_service.dart';
import 'package:kaki_empat/core/services/review_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/core/utils/v2_feedback.dart';
import 'package:kaki_empat/features/owner/presentation/payment_guide_page.dart';
import 'package:kaki_empat/features/shared/widgets/booking_status_chip.dart';
import 'package:kaki_empat/features/shared/widgets/v2_empty_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/presentation/sitter_detail_page.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/features/shared/widgets/v2_sitter_badge_row.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

enum _OfferSort { priceLow, priceHigh, rating }

class OwnerRequestOffersPage extends StatefulWidget {
  const OwnerRequestOffersPage({super.key, required this.request});

  final BookingRequestV2 request;

  @override
  State<OwnerRequestOffersPage> createState() => _OwnerRequestOffersPageState();
}

class _OwnerRequestOffersPageState extends State<OwnerRequestOffersPage> {
  List<MarketplaceOfferV2> _offers = [];
  Map<String, double> _ratings = {};
  Set<String> _favorites = {};
  _OfferSort _sort = _OfferSort.priceLow;
  bool _loading = true;
  bool _accepting = false;
  String? _error;
  String? _acceptingOfferId;

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
        MarketplaceV2Service.instance.listOffers(widget.request.id),
        FavoritesService.instance.getFavoriteSitterIds(),
      ]);
      if (!mounted) return;
      final offers = results[0] as List<MarketplaceOfferV2>;
      final ratings = await _loadRatings(offers);
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _favorites = results[1] as Set<String>;
        _ratings = ratings;
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

  Future<Map<String, double>> _loadRatings(List<MarketplaceOfferV2> offers) async {
    final ids = offers.map((o) => o.sitterUserId).toSet();
    final map = <String, double>{};
    await Future.wait(ids.map((id) async {
      try {
        final r = await ReviewV2Service.instance.getSitterReviews(id, limit: 1);
        if (r.averageRating != null) map[id] = r.averageRating!;
      } catch (_) {}
    }));
    return map;
  }

  List<MarketplaceOfferV2> get _sortedOffers {
    final list = List<MarketplaceOfferV2>.from(_offers);
    list.sort((a, b) {
      return switch (_sort) {
        _OfferSort.priceLow => a.price.compareTo(b.price),
        _OfferSort.priceHigh => b.price.compareTo(a.price),
        _OfferSort.rating => (_ratings[b.sitterUserId] ?? 0)
            .compareTo(_ratings[a.sitterUserId] ?? 0),
      };
    });
    return list;
  }

  String? get _bestValueOfferId {
    if (_offers.isEmpty) return null;
    final sorted = List<MarketplaceOfferV2>.from(_offers)
      ..sort((a, b) => a.price.compareTo(b.price));
    return sorted.first.id;
  }

  Future<void> _toggleFavorite(String sitterId) async {
    await FavoritesService.instance.toggleFavorite(sitterId);
    final ids = await FavoritesService.instance.getFavoriteSitterIds();
    if (!mounted) return;
    setState(() => _favorites = ids);
  }

  String _serviceLabel() {
    if (widget.request.serviceLabel.isNotEmpty) {
      return widget.request.serviceLabel;
    }
    return V2Formatters.serviceLabel(widget.request.serviceCode);
  }

  String _scheduleLabel() {
    if (widget.request.dateLabel.isNotEmpty &&
        widget.request.timeRange.isNotEmpty) {
      return '${widget.request.dateLabel} · ${widget.request.timeRange}';
    }
    if (widget.request.dateLabel.isNotEmpty) return widget.request.dateLabel;
    return V2Formatters.dateTime(widget.request.scheduledAt);
  }

  Future<void> _acceptOffer(MarketplaceOfferV2 offer) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.ownerAcceptOfferTitle),
        content: Text(
          l10n.ownerAcceptOfferConfirm(
            offer.sitterName.isNotEmpty ? offer.sitterName : l10n.valueEmpty,
            V2Formatters.money(offer.price),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.ownerAcceptOfferAction),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _accepting = true;
      _acceptingOfferId = offer.id;
      _error = null;
    });

    try {
      final result = await MarketplaceV2Service.instance.acceptOffer(offer.id);
      if (!mounted) return;
      V2Feedback.showSuccess(context, l10n.ownerAcceptOfferSuccess);
      if (result.bookingId.isNotEmpty && result.status == 'awaitingPayment') {
        await Navigator.of(context).pushReplacement(
          V2PageRoute<void>(
            page: PaymentGuidePage(bookingId: result.bookingId),
          ),
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _accepting = false;
        _acceptingOfferId = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = l10n.saveFailed;
        _accepting = false;
        _acceptingOfferId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final request = widget.request;
    final offers = _sortedOffers;
    final padding = V2Responsive.pagePadding(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ownerRequestOffersTitle)),
      body: V2Responsive.constrain(
        _loading
            ? const V2ListSkeleton()
            : _error != null && _offers.isEmpty && !_loading
                ? V2ErrorState(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: padding,
                      children: [
                        Text(_serviceLabel(), style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        BookingStatusChip(status: request.status),
                        const SizedBox(height: 8),
                        Text(_scheduleLabel()),
                        if (request.location?.address.isNotEmpty == true)
                          Text(request.location!.address),
                        Text('${l10n.requestDetailPrice}: ${V2Formatters.money(request.totalPrice)}'),
                        const Divider(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.ownerRequestOffersHeading,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            DropdownButton<_OfferSort>(
                              value: _sort,
                              underline: const SizedBox.shrink(),
                              items: [
                                DropdownMenuItem(
                                  value: _OfferSort.priceLow,
                                  child: Text(l10n.sortPriceLow),
                                ),
                                DropdownMenuItem(
                                  value: _OfferSort.priceHigh,
                                  child: Text(l10n.sortPriceHigh),
                                ),
                                DropdownMenuItem(
                                  value: _OfferSort.rating,
                                  child: Text(l10n.sortRating),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _sort = v);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _error!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        if (offers.isEmpty)
                          V2EmptyState(
                            message: l10n.ownerRequestOffersEmpty,
                            icon: Icons.local_offer_outlined,
                          )
                        else
                          ...offers.map((offer) {
                            final busy =
                                _accepting && _acceptingOfferId == offer.id;
                            final rating =
                                offer.averageRating ?? _ratings[offer.sitterUserId];
                            final fav = _favorites.contains(offer.sitterUserId);
                            final isBestValue = offer.id == _bestValueOfferId;
                            final badges = offer.badges
                                .map(SitterBadge.fromJson)
                                .toList();
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          V2PageRoute<void>(
                                            page: SitterDetailPage(
                                              sitterUserId: offer.sitterUserId,
                                              sitterName: offer.sitterName,
                                              initialRating: rating,
                                              initialBadges: badges,
                                              isVerified: offer.isVerified,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              offer.sitterName.isNotEmpty
                                                  ? offer.sitterName
                                                  : l10n.valueEmpty,
                                              style: theme.textTheme.titleMedium,
                                            ),
                                          ),
                                          if (offer.isVerified)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 4),
                                              child: Icon(
                                                Icons.verified,
                                                size: 18,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          if (offer.hasPromo)
                                            Chip(
                                              label: Text(l10n.promoActive),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          if (isBestValue)
                                            Chip(
                                              label: Text(l10n.offerBestValue),
                                              visualDensity: VisualDensity.compact,
                                              backgroundColor: theme
                                                  .colorScheme.primaryContainer,
                                            ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Spacer(),
                                        IconButton(
                                          tooltip: fav
                                              ? l10n.favoriteRemove
                                              : l10n.favoriteAdd,
                                          onPressed: () =>
                                              _toggleFavorite(offer.sitterUserId),
                                          icon: Icon(
                                            fav ? Icons.favorite : Icons.favorite_border,
                                            color: fav ? theme.colorScheme.primary : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(V2Formatters.money(offer.price)),
                                    if (rating != null)
                                      Row(
                                        children: [
                                          Icon(Icons.star,
                                              size: 16, color: theme.colorScheme.primary),
                                          const SizedBox(width: 4),
                                          Text(rating.toStringAsFixed(1)),
                                        ],
                                      ),
                                    if (badges.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      V2SitterBadgeRow(badges: badges, compact: true),
                                    ],
                                    if (offer.message.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(offer.message),
                                    ],
                                    const SizedBox(height: 12),
                                    if (offer.isPending && request.status == 'open')
                                      FilledButton(
                                        onPressed:
                                            _accepting ? null : () => _acceptOffer(offer),
                                        child: busy
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(l10n.ownerAcceptOfferAction),
                                      )
                                    else
                                      Chip(label: Text(offer.status)),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
        context,
      ),
    );
  }
}
