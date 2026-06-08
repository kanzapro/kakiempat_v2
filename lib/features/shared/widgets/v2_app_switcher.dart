import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/models/auth_user_v2.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';
import 'package:kaki_empat/core/web/domain_kind.dart';
import 'package:kaki_empat/core/web/domain_router.dart';
import 'package:kaki_empat/core/web/sso_nav.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Switcher ringan antar subdomain Kaki Empat via SSO.
class V2AppSwitcher extends StatelessWidget {
  const V2AppSwitcher({super.key, required this.currentDomain});

  final WebDomain currentDomain;

  @override
  Widget build(BuildContext context) {
    if (!MvpScope.showAppSwitcher) return const SizedBox.shrink();

    return FutureBuilder<AuthUserV2?>(
      future: AuthServiceV2.instance.getStoredUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return PopupMenuButton<String>(
          tooltip: AppLocalizations.of(context)!.appSwitcherTooltip,
          icon: const Icon(Icons.apps_outlined),
          onSelected: (target) {
            if (target == currentDomain.name) return;
            SsoNav.openSubdomain(target);
          },
          itemBuilder: (ctx) => [
            _item(
              ctx,
              target: 'owner',
              icon: Icons.pets_outlined,
              label: AppLocalizations.of(ctx)!.appSwitcherOwner,
              enabled: MvpScope.isTargetReachable('owner', user),
            ),
            _item(
              ctx,
              target: 'sitter',
              icon: Icons.handshake_outlined,
              label: AppLocalizations.of(ctx)!.appSwitcherSitter,
              enabled: MvpScope.isTargetReachable('sitter', user),
            ),
            if (user?.isPartner == true)
              _item(
                ctx,
                target: 'sitter',
                icon: Icons.storefront_outlined,
                label: AppLocalizations.of(ctx)!.appSwitcherPartner,
                enabled: MvpScope.isTargetReachable('sitter', user),
              ),
            if (user?.isAdmin == true || user?.isFounder == true)
              _item(
                ctx,
                target: 'admin',
                icon: Icons.admin_panel_settings_outlined,
                label: AppLocalizations.of(ctx)!.appSwitcherAdmin,
                enabled: MvpScope.isTargetReachable('admin', user),
              ),
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _item(
    BuildContext context, {
    required String target,
    required IconData icon,
    required String label,
    required bool enabled,
  }) {
    final isCurrent = switch (currentDomain) {
      WebDomain.owner || WebDomain.staging => target == 'owner',
      WebDomain.sitter => target == 'sitter',
      WebDomain.admin => target == 'admin',
      _ => false,
    };

    return PopupMenuItem<String>(
      value: target,
      enabled: enabled && !isCurrent,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (isCurrent)
            Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
          if (!enabled)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.lock_outline,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }
}

/// Domain aktif dari hostname browser.
WebDomain currentWebDomain() => DomainRouter.resolve();
