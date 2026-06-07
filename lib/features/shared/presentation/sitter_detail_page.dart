import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/review_v2_service.dart';
import 'package:kaki_empat/core/services/sitter_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/features/shared/widgets/v2_sitter_badge_row.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class SitterDetailPage extends StatefulWidget {
  const SitterDetailPage({
    super.key,
    required this.sitterUserId,
    required this.sitterName,
    this.initialRating,
    this.initialBadges = const [],
    this.isVerified = false,
  });

  final String sitterUserId;
  final String sitterName;
  final double? initialRating;
  final List<SitterBadge> initialBadges;
  final bool isVerified;

  @override
  State<SitterDetailPage> createState() => _SitterDetailPageState();
}

class _SitterDetailPageState extends State<SitterDetailPage> {
  SitterReviewsResult? _reviews;
  List<SitterBadge> _badges = [];
  double? _rating;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _badges = widget.initialBadges;
    _rating = widget.initialRating;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ReviewV2Service.instance.getSitterReviews(widget.sitterUserId),
        SitterV2Service.instance.getBadges(widget.sitterUserId),
      ]);
      if (!mounted) return;
      final reviewResult = results[0] as SitterReviewsResult;
      final badgeData = results[1] as Map<String, dynamic>;
      final rawBadges = badgeData['badges'];
      setState(() {
        _reviews = reviewResult;
        _rating = reviewResult.averageRating ?? _rating;
        _badges = rawBadges is List
            ? rawBadges
                .whereType<Map<String, dynamic>>()
                .map(SitterBadge.fromJson)
                .toList()
            : _badges;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.sitterName)),
      body: V2Responsive.constrain(
        _loading
            ? const V2ListSkeleton()
            : _error != null && _reviews == null
                ? V2ErrorState(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: V2Responsive.pagePadding(context),
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              child: Text(
                                widget.sitterName.isNotEmpty
                                    ? widget.sitterName[0].toUpperCase()
                                    : '?',
                                style: theme.textTheme.headlineSmall,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.sitterName,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  if (_rating != null)
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            size: 18,
                                            color: theme.colorScheme.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_rating!.toStringAsFixed(1)} (${_reviews?.total ?? 0} ulasan)',
                                        ),
                                      ],
                                    ),
                                  if (widget.isVerified)
                                    Row(
                                      children: [
                                        Icon(Icons.verified,
                                            size: 16,
                                            color: theme.colorScheme.primary),
                                        const SizedBox(width: 4),
                                        Text(l10n.badgeVerified),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        V2SitterBadgeRow(badges: _badges),
                        const Divider(height: 32),
                        Text(l10n.sitterReviewsTitle,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        if (_reviews == null || _reviews!.reviews.isEmpty)
                          Text(l10n.sitterReviewsEmpty)
                        else
                          ..._reviews!.reviews.map((r) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < r.rating ? Icons.star : Icons.star_border,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                title: Text(r.ownerName ?? l10n.valueEmpty),
                                subtitle: Text(
                                  r.comment.isNotEmpty
                                      ? r.comment
                                      : l10n.reviewNoComment,
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
