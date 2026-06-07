import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/app_config.dart';
import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/core/web/sso_nav.dart';
import 'package:kaki_empat/features/www/presentation/www_landing_scope.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Footer www — tautan section + subdomain (SSO).
class WwwFooter extends StatelessWidget {
  const WwwFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final padding = V2Responsive.pagePadding(context);
    final isMobile = V2Responsive.isMobile(context);
    final scope = WwwLandingScope.maybeOf(context);

    Widget link(String label, VoidCallback onTap) {
      return TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final sectionLinks = [
      if (scope != null) ...[
        link(l10n.wwwNavServices, () => scope.scrollTo(WwwSection.services)),
        link(l10n.wwwNavPricing, () => scope.scrollTo(WwwSection.pricing)),
        link(l10n.wwwNavSignup, () => scope.scrollTo(WwwSection.signup)),
        if (!MvpScope.hideWwwBlog)
          link(l10n.wwwNavBlog, () => scope.scrollTo(WwwSection.blog)),
        link(
          l10n.wwwNavTestimonials,
          () => scope.scrollTo(WwwSection.testimonials),
        ),
      ],
    ];

    final appLinks = [
      link(l10n.wwwOpenOwnerApp, () => SsoNav.openSubdomain('owner')),
      if (!MvpScope.hideWwwSitterAppLink)
        link(l10n.wwwOpenSitterApp, () => SsoNav.openSubdomain('sitter')),
      if (!MvpScope.hideWwwAdminStagingLinks) ...[
        link(l10n.wwwOpenAdminApp, () => SsoNav.openSubdomain('admin')),
        link(l10n.wwwOpenStagingApp, () => SsoNav.openSubdomain('staging')),
      ],
    ];

    return Container(
      width: double.infinity,
      color: AppColors.primaryDark.withValues(alpha: 0.06),
      child: Padding(
        padding: padding.copyWith(top: 28, bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.wwwFooterTagline,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            if (isMobile) ...[
              Text(l10n.wwwFooterSections, style: theme.textTheme.labelMedium),
              Wrap(children: sectionLinks),
              const SizedBox(height: 12),
              Text(l10n.wwwNavApps, style: theme.textTheme.labelMedium),
              Wrap(children: appLinks),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.wwwFooterSections, style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Wrap(children: sectionLinks),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.wwwNavApps, style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Wrap(children: appLinks),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              l10n.wwwFooterCopyright(
                DateTime.now().year,
                AppConfig.appName,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
