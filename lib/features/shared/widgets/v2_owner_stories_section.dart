import 'package:flutter/material.dart';
import 'package:kaki_empat/core/data/dummy_content.dart';
import 'package:kaki_empat/features/shared/widgets/v2_initial_avatar.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Section cerita pemilik hewan dengan kartu kutipan dan avatar profil.
class V2OwnerStoriesSection extends StatelessWidget {
  const V2OwnerStoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stories = DummyContent.ownerStories(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.ownerStoriesTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...stories.map((story) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OwnerStoryCard(story: story),
            )),
      ],
    );
  }
}

class _OwnerStoryCard extends StatelessWidget {
  const _OwnerStoryCard({required this.story});

  final DummyOwnerStory story;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            V2InitialAvatar(
              initials: story.initials,
              size: 44,
              backgroundColor: story.avatarColor.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(story.name, style: theme.textTheme.titleSmall),
                  Text(
                    story.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${story.quote}"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
