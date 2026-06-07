import 'package:flutter/material.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/services/business_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class EarningsReportPage extends StatefulWidget {
  const EarningsReportPage({super.key});

  @override
  State<EarningsReportPage> createState() => _EarningsReportPageState();
}

class _EarningsReportPageState extends State<EarningsReportPage> {
  EarningsReport? _report;
  List<SitterAchievement> _achievements = [];
  bool _loading = true;
  String? _error;
  bool _showMonthly = true;

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
        BusinessV2Service.instance.getEarningsReport(),
        BusinessV2Service.instance.getAchievements(),
      ]);
      if (!mounted) return;
      setState(() {
        _report = results[0] as EarningsReport;
        _achievements = results[1] as List<SitterAchievement>;
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
    final report = _report;
    final periods = _showMonthly ? report?.monthly ?? [] : report?.weekly ?? [];
    final maxNet = periods.isEmpty
        ? 1
        : periods.map((p) => p.net).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.earningsReportTitle)),
      body: V2Responsive.constrain(
        _loading
            ? const V2ListSkeleton()
            : _error != null && report == null
                ? V2ErrorState(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: V2Responsive.pagePadding(context),
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _StatCard(
                              label: l10n.earningsTotalBookings,
                              value: '${report?.totalBookings ?? 0}',
                              icon: Icons.event_note,
                            ),
                            _StatCard(
                              label: l10n.earningsAvgRating,
                              value: report?.averageRating?.toStringAsFixed(1) ?? '-',
                              icon: Icons.star,
                            ),
                            _StatCard(
                              label: l10n.earningsNetIncome,
                              value: V2Formatters.money(report?.totalNetIncome ?? 0),
                              icon: Icons.account_balance_wallet,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(value: false, label: Text(l10n.earningsWeekly)),
                            ButtonSegment(value: true, label: Text(l10n.earningsMonthly)),
                          ],
                          selected: {_showMonthly},
                          onSelectionChanged: (s) =>
                              setState(() => _showMonthly = s.first),
                        ),
                        const SizedBox(height: 16),
                        if (periods.isEmpty)
                          Text(l10n.earningsNoData)
                        else
                          ...periods.map((p) {
                            final frac = p.net / maxNet;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(p.period),
                                      Text(V2Formatters.money(p.net)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(value: frac),
                                ],
                              ),
                            );
                          }),
                        const Divider(height: 32),
                        Text(l10n.achievementsTitle,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (_achievements.isEmpty)
                          Text(l10n.achievementsEmpty)
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _achievements
                                .map(
                                  (a) => Chip(
                                    avatar: const Icon(Icons.emoji_events),
                                    label: Text(a.label),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
        context,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.titleLarge),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
