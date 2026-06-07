import 'package:kaki_empat/core/config/launch_exit_criteria.dart';

class LaunchMetricCheck {
  const LaunchMetricCheck({
    required this.key,
    required this.label,
    required this.current,
    required this.target,
    required this.passed,
    required this.unit,
  });

  final String key;
  final String label;
  final double current;
  final double target;
  final bool passed;
  final String unit;

  factory LaunchMetricCheck.fromJson(Map<String, dynamic> json) {
    return LaunchMetricCheck(
      key: '${json['key'] ?? ''}',
      label: '${json['label'] ?? ''}',
      current: (json['current'] as num?)?.toDouble() ?? 0,
      target: (json['target'] as num?)?.toDouble() ?? 0,
      passed: json['passed'] == true,
      unit: '${json['unit'] ?? ''}',
    );
  }
}

class LaunchMetricsV2 {
  const LaunchMetricsV2({
    required this.phase,
    required this.nextPhase,
    required this.readyToAdvance,
    required this.checks,
    required this.completedBookings30d,
    required this.verifiedSitters,
    required this.totalBookings30d,
    required this.pendingPaymentProofs,
  });

  final String phase;
  final String? nextPhase;
  final bool readyToAdvance;
  final List<LaunchMetricCheck> checks;
  final int completedBookings30d;
  final int verifiedSitters;
  final int totalBookings30d;
  final int pendingPaymentProofs;

  factory LaunchMetricsV2.fromJson(Map<String, dynamic> json) {
    final rawChecks = json['checks'];
    return LaunchMetricsV2(
      phase: '${json['phase'] ?? LaunchExitCriteria.currentPhase.name}',
      nextPhase: json['next_phase']?.toString(),
      readyToAdvance: json['ready_to_advance'] == true,
      checks: rawChecks is List
          ? rawChecks
              .whereType<Map<String, dynamic>>()
              .map(LaunchMetricCheck.fromJson)
              .toList()
          : const [],
      completedBookings30d:
          (json['completed_bookings_30d'] as num?)?.toInt() ?? 0,
      verifiedSitters: (json['verified_sitters'] as num?)?.toInt() ?? 0,
      totalBookings30d: (json['total_bookings_30d'] as num?)?.toInt() ?? 0,
      pendingPaymentProofs:
          (json['pending_payment_proofs'] as num?)?.toInt() ?? 0,
    );
  }
}
