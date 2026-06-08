import 'package:flutter/material.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/models/auth_user_v2.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';
import 'package:kaki_empat/core/services/booking_v2_service.dart';
import 'package:kaki_empat/core/services/owner_v2_service.dart';
import 'package:kaki_empat/core/services/review_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/navigation/v2_page_route.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/features/owner/presentation/payment_guide_page.dart';
import 'package:kaki_empat/features/shared/presentation/chat_page.dart';
import 'package:kaki_empat/features/shared/presentation/submit_review_page.dart';
import 'package:kaki_empat/core/utils/v2_feedback.dart';
import 'package:kaki_empat/features/shared/widgets/booking_status_chip.dart';
import 'package:kaki_empat/features/shared/widgets/booking_status_l10n.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class BookingDetailPage extends StatefulWidget {
  const BookingDetailPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  BookingV2? _booking;
  AuthUserV2? _user;
  List<String> _petLabels = [];
  bool _loading = true;
  bool _acting = false;
  bool _hasReview = false;
  String? _error;

  static const _timelineSteps = [
    'created',
    'matched',
    'paid',
    'confirmed',
    'en_route',
    'in_progress',
    'completed',
  ];

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
        BookingV2Service.instance.getBooking(widget.bookingId),
        AuthServiceV2.instance.getStoredUser(),
      ]);
      if (!mounted) return;
      final booking = results[0] as BookingV2;
      final user = results[1] as AuthUserV2?;
      var petLabels = <String>[];
      if (user?.isOwner == true || user?.isFounder == true) {
        try {
          final profile = await OwnerV2Service.instance.getProfile();
          petLabels = booking.petIds
              .map((id) {
                for (final pet in profile.pets) {
                  if (pet.id == id) return pet.name;
                }
                return id;
              })
              .toList();
        } catch (_) {
          petLabels = booking.petIds;
        }
      } else if (booking.petIds.isNotEmpty) {
        petLabels = booking.petIds;
      }
      ReviewV2? review;
      if (booking.status.toLowerCase() == 'completed') {
        review = await ReviewV2Service.instance.getBookingReview(booking.id);
      }
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _user = user;
        _petLabels = petLabels;
        _hasReview = review != null;
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

  int _timelineIndex(String status) {
    final s = status.toLowerCase();
    return switch (s) {
      'open' => 0,
      'matched' || 'pending' => 1,
      'awaitingpayment' => 1,
      'pending_verification' => 2,
      'paid' => 2,
      'confirmed' => 3,
      'en_route' => 4,
      'in_progress' => 5,
      'completed' => 6,
      _ => 0,
    };
  }

  String? _ownerActionLabel(AppLocalizations l10n, BookingV2 booking) {
    if (booking.needsPayment) return l10n.bookingDetailPay;
    return null;
  }

  String? _sitterActionLabel(AppLocalizations l10n, BookingV2 booking) {
    return switch (booking.status.toLowerCase()) {
      'paid' || 'pending' => l10n.bookingDetailConfirm,
      'confirmed' => l10n.bookingDetailEnRoute,
      'en_route' => l10n.bookingDetailStart,
      'in_progress' => l10n.bookingDetailComplete,
      _ => null,
    };
  }

  bool _canCancel(BookingV2 booking) {
    final s = booking.status.toLowerCase();
    return s == 'pending' ||
        s == 'awaitingpayment' ||
        s == 'paid' ||
        s == 'confirmed';
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _acting = true);
    try {
      await action();
      if (!mounted) return;
      V2Feedback.showSuccess(
        context,
        AppLocalizations.of(context)!.bookingDetailActionSuccess,
      );
      await _load();
    } on V2ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _advanceSitter(BookingV2 booking) async {
    final s = booking.status.toLowerCase();
    await _runAction(() async {
      if (s == 'paid' || s == 'pending') {
        await BookingV2Service.instance.sitterConfirm(booking.id);
      } else if (s == 'confirmed') {
        await BookingV2Service.instance.sitterEnRoute(booking.id);
      } else if (s == 'en_route') {
        await BookingV2Service.instance.startBooking(booking.id);
      } else if (s == 'in_progress') {
        await BookingV2Service.instance.completeBooking(booking.id);
      }
    });
  }

  Future<void> _cancelBooking(BookingV2 booking) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await V2Feedback.confirm(
      context,
      message: l10n.bookingDetailCancelConfirm,
      confirmLabel: l10n.bookingDetailCancel,
      destructive: true,
    );
    if (ok != true) return;
    await _runAction(() => BookingV2Service.instance.cancelBooking(booking.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final booking = _booking;
    final user = _user;
    final isOwner = user?.isOwner == true || user?.isFounder == true;
    final isSitter = user?.isSitter == true;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingDetailTitle)),
      body: V2Responsive.constrain(
        _loading
            ? const V2ListSkeleton(itemCount: 4)
            : booking == null
                ? V2ErrorState(message: _error ?? l10n.loadFailed, onRetry: _load)
                : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.serviceCode.isNotEmpty
                                  ? V2Formatters.serviceLabel(booking.serviceCode)
                                  : '#${booking.id}',
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                          BookingStatusChip(status: booking.status),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _InfoTile(
                        icon: Icons.info_outline,
                        label: l10n.bookingDetailStatus,
                        value: bookingStatusLocalized(l10n, booking.status),
                      ),
                      _InfoTile(
                        icon: Icons.calendar_today_outlined,
                        label: l10n.bookingDetailSchedule,
                        value: V2Formatters.dateTime(booking.scheduledAt),
                      ),
                      _InfoTile(
                        icon: Icons.payments_outlined,
                        label: l10n.bookingDetailAmount,
                        value: V2Formatters.money(booking.paymentAmount),
                      ),
                      if (_petLabels.isNotEmpty)
                        _InfoTile(
                          icon: Icons.pets,
                          label: l10n.requestDetailPets,
                          value: _petLabels.join(', '),
                        ),
                      if (booking.notes.isNotEmpty)
                        _InfoTile(
                          icon: Icons.notes_outlined,
                          label: l10n.requestDetailNotes,
                          value: booking.notes,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.bookingDetailTimeline,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ..._buildTimeline(l10n, booking),
                      const SizedBox(height: 24),
                      if (isOwner && _ownerActionLabel(l10n, booking) != null)
                        FilledButton.icon(
                          onPressed: _acting
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    V2PageRoute<void>(
                                      page: PaymentGuidePage(bookingId: booking.id),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.payment_outlined),
                          label: Text(_ownerActionLabel(l10n, booking)!),
                        ),
                      if (isSitter && _sitterActionLabel(l10n, booking) != null) ...[
                        FilledButton(
                          onPressed: _acting ? null : () => _advanceSitter(booking),
                          child: _acting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_sitterActionLabel(l10n, booking)!),
                        ),
                      ],
                      if (isOwner || isSitter) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              V2PageRoute<void>(
                                page: ChatPage(bookingId: booking.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: Text(l10n.bookingDetailChat),
                        ),
                      ],
                      if (isOwner &&
                          booking.status.toLowerCase() == 'completed' &&
                          !_hasReview) ...[
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            final ok = await openSubmitReview(
                              context,
                              bookingId: booking.id,
                            );
                            if (ok == true) await _load();
                          },
                          icon: const Icon(Icons.star_outline),
                          label: Text(l10n.reviewLeaveAction),
                        ),
                      ],
                      if (isOwner && _hasReview) ...[
                        const SizedBox(height: 8),
                        Chip(
                          avatar: const Icon(Icons.check, size: 16),
                          label: Text(l10n.reviewAlreadySubmitted),
                        ),
                      ],
                      if ((isOwner || isSitter) && _canCancel(booking)) ...[
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _acting ? null : () => _cancelBooking(booking),
                          child: Text(l10n.bookingDetailCancel),
                        ),
                      ],
                    ],
                  ),
                ),
        context,
      ),
    );
  }

  List<Widget> _buildTimeline(AppLocalizations l10n, BookingV2 booking) {
    final current = _timelineIndex(booking.status);
    return List.generate(_timelineSteps.length, (index) {
      final step = _timelineSteps[index];
      final done = index <= current;
      final active = index == current;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done
              ? (active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.tertiary)
              : Theme.of(context).colorScheme.outline,
        ),
        title: Text(
          bookingTimelineLocalized(l10n, step),
          style: TextStyle(
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color: done
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    });
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
