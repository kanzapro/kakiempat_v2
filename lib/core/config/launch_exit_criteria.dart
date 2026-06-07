import 'package:kaki_empat/core/config/mvp_scope.dart';

/// Ambang batas untuk naik fase peluncuran super-app.
///
/// Nilai default konservatif; founder dapat menyesuaikan setelah validasi pasar.
abstract final class LaunchExitCriteria {
  /// Persentase booking selesai dari total booking non-batal (30 hari).
  static const double bookingCompletionRateMin = 0.65;

  /// Maksimum jam rata-rata admin menyetujui bukti bayar (30 hari).
  static const double paymentApprovalHoursMax = 24.0;

  /// Persentase request open yang dapat respons sitter (offer/accept/reject) ≤ 4 jam.
  static const double sitterResponseRateMin = 0.70;

  /// Minimum booking selesai dalam 30 hari agar metrik statistik bermakna.
  static const int minCompletedBookings = 10;

  /// Minimum sitter terverifikasi aktif.
  static const int minVerifiedSitters = 3;

  /// SLA respons sitter (jam).
  static const int sitterResponseSlaHours = 4;

  static LaunchPhase get currentPhase => MvpScope.phase;

  static LaunchPhase? get nextPhase => switch (currentPhase) {
        LaunchPhase.ownerFirst => LaunchPhase.marketplace,
        LaunchPhase.marketplace => LaunchPhase.growth,
        LaunchPhase.growth => LaunchPhase.full,
        LaunchPhase.full => null,
      };

  static bool evaluateAll({
    required double bookingCompletionRate,
    required double paymentApprovalHoursAvg,
    required double sitterResponseRate,
    required int completedBookings30d,
    required int verifiedSitters,
  }) {
    if (completedBookings30d < minCompletedBookings) return false;
    if (verifiedSitters < minVerifiedSitters) return false;
    if (bookingCompletionRate < bookingCompletionRateMin) return false;
    if (paymentApprovalHoursAvg > paymentApprovalHoursMax) return false;
    if (sitterResponseRate < sitterResponseRateMin) return false;
    return true;
  }
}
