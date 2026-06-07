import 'package:flutter/material.dart';
import 'package:kaki_empat/features/shared/widgets/v2_count_up_stat.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Baris statistik hidup dengan ikon dan animasi count-up.
class V2LiveStatsBar extends StatelessWidget {
  const V2LiveStatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            Row(
              children: [
                V2CountUpStat(
                  icon: '🐾',
                  targetValue: 150,
                  suffix: '+',
                  label: l10n.statsBookingsLabel,
                ),
                V2CountUpStat(
                  icon: '⭐',
                  targetValue: 4.9,
                  decimals: 1,
                  label: l10n.statsRatingLabel,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                V2CountUpStat(
                  icon: '📍',
                  textLabel: l10n.statsCitiesValue,
                  label: l10n.statsCitiesLabel,
                ),
                V2CountUpStat(
                  icon: '💰',
                  prefix: 'Rp ',
                  targetValue: 50,
                  suffix: ' jt+',
                  label: l10n.statsPayoutLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
