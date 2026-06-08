import 'package:flutter/material.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/features/shared/widgets/booking_status_l10n.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status});

  final String status;

  Color _color(ColorScheme scheme) {
    final normalized = status.toLowerCase().replaceAll('_', '');
    return switch (normalized) {
      'paid' => AppColors.statusSuccess(scheme),
      'awaitingpayment' => AppColors.statusWarning(scheme),
      'pendingverification' => AppColors.statusInfo(scheme),
      'paymentrejected' => AppColors.statusError(scheme),
      'open' => AppColors.statusSuccess(scheme),
      'matched' || 'pending' => AppColors.statusInfo(scheme),
      'confirmed' => AppColors.statusInfo(scheme),
      'en_route' || 'in_progress' => AppColors.statusProgress(scheme),
      'completed' => AppColors.statusSuccess(scheme),
      'cancelled' => AppColors.statusNeutral(scheme),
      _ => AppColors.statusNeutral(scheme),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _color(scheme);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        bookingStatusLocalized(l10n, status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
