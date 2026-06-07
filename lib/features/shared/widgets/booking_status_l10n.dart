import 'package:kaki_empat/l10n/app_localizations.dart';

String bookingStatusLocalized(AppLocalizations l10n, String status) {
  return switch (status) {
    'open' => l10n.bookingStatusOpen,
    'matched' => l10n.bookingStatusMatched,
    'pending' => l10n.bookingStatusPending,
    'awaitingPayment' => l10n.bookingStatusAwaitingPayment,
    'PENDING_VERIFICATION' => l10n.bookingStatusPendingVerification,
    'PAID' || 'paid' => l10n.bookingStatusPaid,
    'PAYMENT_REJECTED' => l10n.bookingStatusPaymentRejected,
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
