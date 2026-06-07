import 'package:flutter/material.dart';
import 'package:kaki_empat/core/utils/user_friendly_error.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class V2ErrorState extends StatelessWidget {
  const V2ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  factory V2ErrorState.fromError(
    BuildContext context, {
    Object? error,
    VoidCallback? onRetry,
  }) {
    return V2ErrorState(
      message: V2UserError.message(context, error),
      onRetry: onRetry,
    );
  }

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              l10n.errorStateTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.errorStateRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
