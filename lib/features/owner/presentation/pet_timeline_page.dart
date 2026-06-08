import 'package:flutter/material.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/navigation/v2_page_route.dart';
import 'package:kaki_empat/core/services/owner_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/features/shared/presentation/booking_detail_page.dart';
import 'package:kaki_empat/features/shared/widgets/v2_empty_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/features/shared/widgets/v2_pet_avatar.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class PetTimelinePage extends StatefulWidget {
  const PetTimelinePage({super.key, required this.petId, this.petName});

  final String petId;
  final String? petName;

  @override
  State<PetTimelinePage> createState() => _PetTimelinePageState();
}

class _PetTimelinePageState extends State<PetTimelinePage> {
  PetTimelineResult? _timeline;
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
      final result = await OwnerV2Service.instance.getPetTimeline(widget.petId);
      if (!mounted) return;
      setState(() {
        _timeline = result;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = widget.petName ?? _timeline?.pet.name ?? l10n.petTimelineTitle;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: V2Responsive.constrain(
        _loading
            ? const V2ListSkeleton()
            : _error != null
                ? V2ErrorState.fromError(
                    context,
                    error: _error,
                    onRetry: _load,
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _timeline == null || _timeline!.events.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: V2Responsive.pagePadding(context),
                            children: [
                              if (_timeline?.pet != null) ...[
                                _PetHeader(pet: _timeline!.pet),
                                const SizedBox(height: 16),
                              ],
                              SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.3,
                                child: V2EmptyState(
                                  message: l10n.petTimelineEmpty,
                                  icon: Icons.timeline_outlined,
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            padding: V2Responsive.pagePadding(context),
                            children: [
                              _PetHeader(pet: _timeline!.pet),
                              const SizedBox(height: 16),
                              Text(
                                l10n.petTimelineSubtitle,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              ..._timeline!.events.map(
                                (event) => _TimelineTile(
                                  event: event,
                                  onOpenBooking: (id) {
                                    Navigator.of(context).push(
                                      V2PageRoute(
                                        page: BookingDetailPage(bookingId: id),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
        context,
      ),
    );
  }
}

class _PetHeader extends StatelessWidget {
  const _PetHeader({required this.pet});

  final PetV2 pet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: V2PetAvatar(petId: pet.id, size: 48),
        title: Text(pet.name, style: theme.textTheme.titleMedium),
        subtitle: Text([pet.species, if (pet.breed.isNotEmpty) pet.breed].join(' · ')),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event, required this.onOpenBooking});

  final PetTimelineEvent event;
  final void Function(String bookingId) onOpenBooking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final bookingId = event.payload['booking_id']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_iconForKind(event.kind)),
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.subtitle),
            if (event.status.isNotEmpty)
              Text(
                event.status,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            if (event.occurredAt.isNotEmpty)
              Text(
                V2Formatters.relativeTime(event.occurredAt, locale: locale),
                style: theme.textTheme.labelSmall,
              ),
          ],
        ),
        isThreeLine: true,
        onTap: bookingId != null && bookingId.isNotEmpty
            ? () => onOpenBooking(bookingId)
            : null,
      ),
    );
  }

  static IconData _iconForKind(String kind) {
    return switch (kind) {
      'booking' => Icons.event_note_outlined,
      'request' => Icons.request_quote_outlined,
      'gallery' => Icons.photo_library_outlined,
      'health_note' => Icons.medical_information_outlined,
      'pet_registered' => Icons.pets_outlined,
      _ => Icons.circle_outlined,
    };
  }
}
