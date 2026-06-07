import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/models/launch_metrics_v2.dart';
import 'package:kaki_empat/core/services/admin_v2_service.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Panel admin: metrik exit criteria fase [LaunchPhase.ownerFirst].
class AdminLaunchMetricsPanel extends StatefulWidget {
  const AdminLaunchMetricsPanel({super.key});

  @override
  State<AdminLaunchMetricsPanel> createState() =>
      _AdminLaunchMetricsPanelState();
}

class _AdminLaunchMetricsPanelState extends State<AdminLaunchMetricsPanel> {
  LaunchMetricsV2? _metrics;
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
      final metrics = await AdminV2Service.instance.getLaunchMetrics();
      if (!mounted) return;
      setState(() {
        _metrics = metrics;
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

  String _formatCheckValue(LaunchMetricCheck check, AppLocalizations l10n) {
    return switch (check.unit) {
      'ratio' => '${(check.current * 100).toStringAsFixed(1)}%',
      'hours' => '${check.current.toStringAsFixed(1)} ${l10n.launchMetricUnitHours}',
      _ => check.current.toStringAsFixed(0),
    };
  }

  String _formatTarget(LaunchMetricCheck check, AppLocalizations l10n) {
    return switch (check.unit) {
      'ratio' => '≥ ${(check.target * 100).toStringAsFixed(0)}%',
      'hours' => '≤ ${check.target.toStringAsFixed(0)} ${l10n.launchMetricUnitHours}',
      _ => '≥ ${check.target.toStringAsFixed(0)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: V2ListSkeleton(),
      );
    }
    if (_error != null && _metrics == null) {
      return V2ErrorState.fromError(
        context,
        error: _error,
        onRetry: _load,
      );
    }

    final metrics = _metrics!;
    final ready = metrics.readyToAdvance;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: ready
                ? AppColors.primary.withValues(alpha: 0.12)
                : theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.launchMetricsPhaseTitle(
                      MvpScope.phase.name,
                      metrics.nextPhase ?? '—',
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ready
                        ? l10n.launchMetricsReadyBody
                        : l10n.launchMetricsNotReadyBody,
                  ),
                  if (metrics.pendingPaymentProofs > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.launchMetricsPendingPayments(
                        metrics.pendingPaymentProofs,
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.launchMetricsChecksTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...metrics.checks.map(
            (check) => Card(
              child: ListTile(
                leading: Icon(
                  check.passed ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: check.passed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                title: Text(check.label),
                subtitle: Text(
                  '${_formatCheckValue(check, l10n)} · ${_formatTarget(check, l10n)}',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.launchMetricsSnapshot(
              metrics.completedBookings30d,
              metrics.verifiedSitters,
              metrics.totalBookings30d,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
