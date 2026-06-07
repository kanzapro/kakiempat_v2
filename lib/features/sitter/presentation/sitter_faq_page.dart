import 'package:flutter/material.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// FAQ sederhana untuk pengasuh — tips harga, profil, dan pendapatan.
class SitterFaqPage extends StatelessWidget {
  const SitterFaqPage({super.key});

  static const _entries = [
    _FaqEntry('sitterFaqQ1', 'sitterFaqA1'),
    _FaqEntry('sitterFaqQ2', 'sitterFaqA2'),
    _FaqEntry('sitterFaqQ3', 'sitterFaqA3'),
    _FaqEntry('sitterFaqQ4', 'sitterFaqA4'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String text(String key) => switch (key) {
          'sitterFaqQ1' => l10n.sitterFaqQ1,
          'sitterFaqA1' => l10n.sitterFaqA1,
          'sitterFaqQ2' => l10n.sitterFaqQ2,
          'sitterFaqA2' => l10n.sitterFaqA2,
          'sitterFaqQ3' => l10n.sitterFaqQ3,
          'sitterFaqA3' => l10n.sitterFaqA3,
          'sitterFaqQ4' => l10n.sitterFaqQ4,
          'sitterFaqA4' => l10n.sitterFaqA4,
          _ => '',
        };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sitterFaqTitle)),
      body: V2Responsive.constrain(
        ListView(
          padding: V2Responsive.pagePadding(context),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.sitterFaqIntro,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._entries.map(
              (e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(text(e.qKey), style: const TextStyle(fontWeight: FontWeight.w600)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(text(e.aKey)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        context,
      ),
    );
  }
}

class _FaqEntry {
  const _FaqEntry(this.qKey, this.aKey);
  final String qKey;
  final String aKey;
}
