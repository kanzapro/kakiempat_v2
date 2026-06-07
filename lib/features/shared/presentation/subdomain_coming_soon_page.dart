import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/app_config.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/core/web/domain_kind.dart';
import 'package:kaki_empat/core/web/web_nav.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Halaman saat subdomain belum diluncurkan ke publik.
class SubdomainComingSoonPage extends StatelessWidget {
  const SubdomainComingSoonPage({super.key, required this.domain});

  final WebDomain domain;

  String _domainLabel(AppLocalizations l10n) => switch (domain) {
        WebDomain.sitter => l10n.wwwOpenSitterApp,
        WebDomain.admin => l10n.wwwOpenAdminApp,
        WebDomain.staging => l10n.wwwOpenStagingApp,
        _ => domain.name,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final padding = V2Responsive.pagePadding(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: padding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 64,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.subdomainComingSoonTitle(_domainLabel(l10n)),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.subdomainComingSoonBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () => navigateToUrl(AppConfig.ownerUrl),
                    icon: const Text('🐕', style: TextStyle(fontSize: 18)),
                    label: Text(l10n.subdomainComingSoonOwnerCta),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => navigateToUrl(AppConfig.wwwUrl),
                    child: Text(l10n.wwwNavHome),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
