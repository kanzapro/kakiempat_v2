import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/models/auth_user_v2.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/core/web/sso_nav.dart';
import 'package:kaki_empat/features/shared/widgets/logo_widget.dart';
import 'package:kaki_empat/features/www/presentation/www_landing_scope.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Navbar domain utama — tautan section + 5 subdomain via SSO.
class WwwNavbar extends StatelessWidget implements PreferredSizeWidget {
  const WwwNavbar({
    super.key,
    this.user,
    this.onLogin,
    this.onRegister,
    this.onLogout,
  });

  final AuthUserV2? user;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;
  final VoidCallback? onLogout;

  static const double _height = 60;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = V2Responsive.isMobile(context);

    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                InkWell(
                  onTap: () => WwwLandingScope.of(context).scrollToTop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          height: 32,
                          width: 32,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.pets,
                            color: AppColors.primary,
                          ),
                        ),
                        if (!isMobile) ...[
                          const SizedBox(width: 8),
                          Text(
                            l10n.wwwNavBrand,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (!isMobile) ...[
                  ..._sectionLinks(context, l10n),
                  const SizedBox(width: 8),
                  _appsMenu(context, l10n),
                  const SizedBox(width: 8),
                  _authActions(context, l10n),
                ] else ...[
                  _authActions(context, l10n, compact: true),
                  IconButton(
                    icon: const Icon(Icons.menu),
                    tooltip: l10n.wwwNavMenu,
                    onPressed: () => _openDrawer(context, l10n),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _sectionLinks(BuildContext context, AppLocalizations l10n) {
    final scope = WwwLandingScope.of(context);
    final links = <(String, WwwSection)>[
      (l10n.wwwNavServices, WwwSection.services),
      (l10n.wwwNavPricing, WwwSection.pricing),
      (l10n.wwwNavSignup, WwwSection.signup),
      if (!MvpScope.hideWwwBlog) (l10n.wwwNavBlog, WwwSection.blog),
      (l10n.wwwNavTestimonials, WwwSection.testimonials),
    ];
    return links
        .map(
          (e) => TextButton(
            onPressed: () => scope.scrollTo(e.$2),
            child: Text(e.$1),
          ),
        )
        .toList();
  }

  Widget _appsMenu(BuildContext context, AppLocalizations l10n) {
    return PopupMenuButton<String>(
      tooltip: l10n.wwwNavApps,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.wwwNavApps),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      onSelected: (value) => SsoNav.openSubdomain(value),
      itemBuilder: (context) => _appMenuItems(l10n),
    );
  }

  List<PopupMenuEntry<String>> _appMenuItems(AppLocalizations l10n) {
    return [
      PopupMenuItem(value: 'owner', child: Text(l10n.wwwOpenOwnerApp)),
      if (!MvpScope.hideWwwSitterAppLink)
        PopupMenuItem(value: 'sitter', child: Text(l10n.wwwOpenSitterApp)),
      if (!MvpScope.hideWwwAdminStagingLinks) ...[
        PopupMenuItem(value: 'admin', child: Text(l10n.wwwOpenAdminApp)),
        PopupMenuItem(value: 'staging', child: Text(l10n.wwwOpenStagingApp)),
      ],
    ];
  }

  Widget _authActions(
    BuildContext context,
    AppLocalizations l10n, {
    bool compact = false,
  }) {
    if (user == null) {
      if (compact) {
        return IconButton(
          icon: const Icon(Icons.login_outlined),
          tooltip: l10n.authLogin,
          onPressed: onLogin,
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(onPressed: onLogin, child: Text(l10n.authLogin)),
          const SizedBox(width: 4),
          FilledButton.tonal(
            onPressed: onRegister,
            child: Text(l10n.authRegister),
          ),
        ],
      );
    }

    return PopupMenuButton<String>(
      tooltip: user!.name,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle_outlined, size: 22),
            if (!compact) ...[
              const SizedBox(width: 6),
              Text(
                user!.name,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      onSelected: (value) async {
        if (value == 'logout') {
          onLogout?.call();
          return;
        }
        await SsoNav.openSubdomain(value);
      },
      itemBuilder: (context) => [
        if (user!.isOwner || user!.isFounder)
          PopupMenuItem(value: 'owner', child: Text(l10n.wwwOpenOwnerApp)),
        if ((user!.isSitter || user!.isFounder) && !MvpScope.hideWwwSitterAppLink)
          PopupMenuItem(value: 'sitter', child: Text(l10n.wwwOpenSitterApp)),
        if (user!.isSitter && MvpScope.hideWwwSitterAppLink)
          PopupMenuItem(value: 'sitter', child: Text(l10n.wwwOpenSitterApp)),
        if (user!.isAdmin && !MvpScope.hideWwwAdminStagingLinks)
          PopupMenuItem(value: 'admin', child: Text(l10n.wwwOpenAdminApp)),
        if (user!.isFounder && !MvpScope.hideWwwAdminStagingLinks)
          PopupMenuItem(value: 'staging', child: Text(l10n.wwwOpenStagingApp)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'logout', child: Text(l10n.authLogout)),
      ],
    );
  }

  void _openDrawer(BuildContext context, AppLocalizations l10n) {
    final scope = WwwLandingScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const LogoWidget(size: 72, showTagline: false),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text(l10n.wwwNavHome),
                onTap: () {
                  Navigator.pop(ctx);
                  scope.scrollToTop();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.grid_view_outlined),
                title: Text(l10n.wwwNavServices),
                onTap: () {
                  Navigator.pop(ctx);
                  scope.scrollTo(WwwSection.services);
                },
              ),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: Text(l10n.wwwNavPricing),
                onTap: () {
                  Navigator.pop(ctx);
                  scope.scrollTo(WwwSection.pricing);
                },
              ),
              ListTile(
                leading: const Icon(Icons.handshake_outlined),
                title: Text(l10n.wwwNavSignup),
                onTap: () {
                  Navigator.pop(ctx);
                  scope.scrollTo(WwwSection.signup);
                },
              ),
              if (!MvpScope.hideWwwBlog)
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: Text(l10n.wwwNavBlog),
                  onTap: () {
                    Navigator.pop(ctx);
                    scope.scrollTo(WwwSection.blog);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text(l10n.wwwNavTestimonials),
                onTap: () {
                  Navigator.pop(ctx);
                  scope.scrollTo(WwwSection.testimonials);
                },
              ),
              const Divider(),
              Text(
                l10n.wwwNavApps,
                style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              ..._appMenuItems(l10n).map((item) {
                if (item is! PopupMenuItem<String>) return const SizedBox.shrink();
                return ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: Text((item.child as Text).data ?? ''),
                  onTap: () {
                    Navigator.pop(ctx);
                    SsoNav.openSubdomain(item.value!);
                  },
                );
              }),
              if (user == null) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.login_outlined),
                  title: Text(l10n.authLogin),
                  onTap: () {
                    Navigator.pop(ctx);
                    onLogin?.call();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_outlined),
                  title: Text(l10n.authRegister),
                  onTap: () {
                    Navigator.pop(ctx);
                    onRegister?.call();
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
