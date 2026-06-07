import 'package:flutter/material.dart';
import 'package:kaki_empat/core/data/dummy_content.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Feed cerita harian komunitas mitra pengasuh (data dummy).
class StoriFeedPage extends StatelessWidget {
  const StoriFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final posts = DummyContent.storiPosts(l10n);
    final padding = V2Responsive.pagePadding(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storiFeedTitle)),
      body: V2Responsive.constrain(
        ListView(
          padding: padding,
          children: [
            Text(
              l10n.storiFeedSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...posts.map((post) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _StoriPostCard(post: post),
                )),
          ],
        ),
        context,
      ),
    );
  }
}

class _StoriPostCard extends StatelessWidget {
  const _StoriPostCard({required this.post});

  final DummyStoriPost post;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: post.gradientColors,
              ),
            ),
            child: Center(
              child: Icon(
                post.icon,
                size: 64,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        post.authorName.substring(0, 1),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.authorName, style: theme.textTheme.titleSmall),
                          Text(
                            post.timeAgo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(post.caption, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.favorite_border, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(l10n.storiLikes(post.likes), style: theme.textTheme.bodySmall),
                    const SizedBox(width: 16),
                    Icon(Icons.chat_bubble_outline, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(l10n.storiComments(post.comments), style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
