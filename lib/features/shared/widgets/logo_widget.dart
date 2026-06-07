import 'package:flutter/material.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Logo brand Kaki Empat — gambar asli dari assets/logo.png.
class LogoWidget extends StatelessWidget {
  const LogoWidget({
    super.key,
    this.size = 120,
    this.showTagline = true,
    this.showTitle = true,
    this.centered = true,
  });

  final double size;
  final bool showTagline;
  final bool showTitle;
  final bool centered;

  static const _logoAsset = 'assets/logo.png';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Image.asset(
          _logoAsset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          semanticLabel: l10n.appTitle,
        ),
        if (showTitle) ...[
          const SizedBox(height: 8),
          Text(
            l10n.appTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: size <= 80 ? 24 : null,
              color: AppColors.primaryDark,
            ),
            textAlign: centered ? TextAlign.center : TextAlign.start,
          ),
        ],
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            l10n.tagline,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: centered ? TextAlign.center : TextAlign.start,
          ),
        ],
      ],
    );

    if (centered) {
      return Center(child: content);
    }
    return content;
  }
}
