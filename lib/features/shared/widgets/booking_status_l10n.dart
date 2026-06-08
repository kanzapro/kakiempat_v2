import 'package:kaki_empat/l10n/app_localizations.dart';

String bookingStatusLocalized(AppLocalizations l10n, String status) {
  final normalized = status.toLowerCase().replaceAll('_', '');
  return switch (normalized) {
    'open' => l10n.bookingStatusOpen,
    'matched' => l10n.bookingStatusMatched,
    'pending' => l10n.bookingStatusPending,
    'awaitingpayment' => l10n.bookingStatusAwaitingPayment,
    'pendingverification' => l10n.bookingStatusPendingVerification,
    'paid' => l10n.bookingStatusPaid,
    'paymentrejected' => l10n.bookingStatusPaymentRejected,
    'cancelled' => l10n.bookingStatusCancelled,
    'confirmed' => l10n.bookingStatusConfirmed,
    'en_route' => l10n.bookingStatusEnRoute,
    'in_progress' => l10n.bookingStatusInProgress,
    'completed' => l10n.bookingStatusCompleted,
    _ => status,
  };
}

String bookingTimelineLocalized(AppLocalizations l10n, String step) {
  return switch (step) {
    'created' => l10n.bookingTimelineCreated,
    'matched' => l10n.bookingTimelineMatched,
    'paid' => l10n.bookingTimelinePaid,
    'confirmed' => l10n.bookingTimelineConfirmed,
    'en_route' => l10n.bookingTimelineEnRoute,
    'in_progress' => l10n.bookingTimelineInProgress,
    'completed' => l10n.bookingTimelineCompleted,
    _ => step,
  };
}
