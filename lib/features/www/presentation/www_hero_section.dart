import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/core/web/sso_nav.dart';
import 'package:kaki_empat/features/shared/widgets/logo_widget.dart';
import 'package:kaki_empat/features/shared/widgets/www_hero_illustration.dart';
import 'package:kaki_empat/features/www/presentation/www_landing_scope.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Hero landing — responsif, CTA jelas, tanpa rebuild seluruh halaman saat scroll.
class WwwHeroSection extends StatelessWidget {
  const WwwHeroSection({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final padding = V2Responsive.pagePadding(context);
    final isMobile = V2Responsive.isMobile(context);
    final isDesktop = V2Responsive.of(context) == V2ScreenSize.desktop;
    final titleSize = V2Responsive.heroTitleSize(context);

    final textBlock = Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        if (!isMobile)
          LogoWidget(
            size: isDesktop ? 100 : 88,
            showTagline: false,
            centered: !isDesktop,
          ),
        if (!isMobile) const SizedBox(height: 16),
        Text(
          l10n.wwwHeroTitle,
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.wwwHeroSubtitle,
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _ValueChips(l10n: l10n, alignStart: isDesktop),
        const SizedBox(height: 24),
        _HeroCtas(l10n: l10n, stacked: isMobile || V2Responsive.isNarrowMobile(context)),
      ],
    );

    final illustration = RepaintBoundary(
      child: AnimatedBuilder(
        animation: scrollController,
        builder: (context, child) {
          return WwwHeroIllustration(
            parallaxOffset: scrollController.hasClients
                ? scrollController.offset
                : 0,
            height: V2Responsive.heroIllustrationHeight(context),
          );
        },
      ),
    );

    return Padding(
      padding: padding.copyWith(top: isMobile ? 12 : 20, bottom: 28),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: textBlock),
                const SizedBox(width: 24),
                Expanded(flex: 4, child: illustration),
              ],
            )
          : Column(
              children: [
                if (isMobile) illustration,
                if (isMobile) const SizedBox(height: 20),
                textBlock,
                if (!isMobile) ...[
                  const SizedBox(height: 20),
                  illustration,
                ],
              ],
            ),
    );
  }
}

class _ValueChips extends StatelessWidget {
  const _ValueChips({required this.l10n, this.alignStart = false});

  final AppLocalizations l10n;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.verified_outlined, l10n.wwwValueVerified),
      (Icons.receipt_long_outlined, l10n.wwwValueTransparent),
      (Icons.shield_outlined, l10n.wwwValueSecure),
    ];
    return Wrap(
      alignment: alignStart ? WrapAlignment.start : WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (e) => Chip(
              avatar: Icon(e.$1, size: 18, color: AppColors.primary),
              label: Text(e.$2),
              backgroundColor: Colors.white.withValues(alpha: 0.85),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          )
          .toList(),
    );
  }
}

class _HeroCtas extends StatelessWidget {
  const _HeroCtas({required this.l10n, required this.stacked});

  final AppLocalizations l10n;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final ownerBtn = FilledButton.icon(
      onPressed: () => SsoNav.openSubdomain('owner'),
      icon: const Text('🐕', style: TextStyle(fontSize: 18)),
      label: Text(l10n.wwwOwnerCta),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        minimumSize: stacked ? const Size(double.infinity, 48) : null,
      ),
    );
    final sitterBtn = OutlinedButton.icon(
      onPressed: () {
        if (MvpScope.hideWwwSitterAppLink) {
          WwwLandingScope.maybeOf(context)?.scrollTo(WwwSection.signup);
          return;
        }
        SsoNav.openSubdomain('sitter');
      },
      icon: const Text('🤝', style: TextStyle(fontSize: 18)),
      label: Text(l10n.wwwPartnerCta),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        backgroundColor: Colors.white.withValues(alpha: 0.75),
        minimumSize: stacked ? const Size(double.infinity, 48) : null,
      ),
    );

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [ownerBtn, const SizedBox(height: 12), sitterBtn],
      );
    }
    return Row(
      children: [
        Expanded(child: ownerBtn),
        const SizedBox(width: 12),
        Expanded(child: sitterBtn),
      ],
    );
  }
}
