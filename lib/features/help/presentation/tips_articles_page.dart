import 'package:flutter/material.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class TipsArticlesPage extends StatelessWidget {
  const TipsArticlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final articles = [
      (l10n.tipsArticle1Title, l10n.tipsArticle1Summary, Icons.restaurant),
      (l10n.tipsArticle2Title, l10n.tipsArticle2Summary, Icons.directions_walk),
      (l10n.tipsArticle3Title, l10n.tipsArticle3Summary, Icons.content_cut),
      (l10n.tipsArticle4Title, l10n.tipsArticle4Summary, Icons.health_and_safety),
      (l10n.tipsArticle5Title, l10n.tipsArticle5Summary, Icons.psychology),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tipsArticlesTitle)),
      body: V2Responsive.constrain(
        ListView(
          padding: V2Responsive.pagePadding(context),
          children: [
            Text(
              l10n.tipsArticlesSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...articles.map((a) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(a.$3),
                  ),
                  title: Text(a.$1, style: theme.textTheme.titleMedium),
                  subtitle: Text(a.$2),
                  isThreeLine: true,
                ),
              );
            }),
          ],
        ),
        context,
      ),
    );
  }
}
