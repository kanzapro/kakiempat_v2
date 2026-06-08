import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/navigation/v2_page_route.dart';
import 'package:kaki_empat/core/web/domain_kind.dart';
import 'package:kaki_empat/features/community/presentation/pet_gallery_page.dart';
import 'package:kaki_empat/features/community/presentation/stori_feed_page.dart';
import 'package:kaki_empat/features/help/presentation/tips_articles_page.dart';
import 'package:kaki_empat/features/owner/presentation/owner_profile_page.dart';
import 'package:kaki_empat/features/shared/presentation/booking_history_page.dart';
import 'package:kaki_empat/features/shared/presentation/discover_page.dart';
import 'package:kaki_empat/features/shared/presentation/notifications_page.dart';
import 'package:kaki_empat/features/shared/widgets/notification_badge_button.dart';
import 'package:kaki_empat/features/shared/widgets/v2_app_switcher.dart';
import 'package:kaki_empat/features/sitter/presentation/promotions_page.dart';
import 'package:kaki_empat/features/sitter/presentation/sitter_profile_page.dart';
import 'package:kaki_empat/features/sitter/presentation/wallet_page.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

enum V2AppShellRole { owner, sitter }

/// Shell navigasi terpadu super-app (fase [LaunchPhase.growth]+).
class V2AppShell extends StatefulWidget {
  const V2AppShell({
    super.key,
    required this.role,
    required this.home,
  });

  final V2AppShellRole role;
  final Widget home;

  @override
  State<V2AppShell> createState() => _V2AppShellState();
}

class _V2AppShellState extends State<V2AppShell> {
  int _index = 0;

  WebDomain get _currentDomain =>
      widget.role == V2AppShellRole.sitter ? WebDomain.sitter : WebDomain.owner;

  @override
  Widget build(BuildContext context) {
    if (!MvpScope.showUnifiedAppShell) {
      return widget.home;
    }

    final l10n = AppLocalizations.of(context)!;
    final destinations = _destinations(l10n);
    final safeIndex = _index.clamp(0, destinations.length - 1);
    final current = destinations[safeIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(current.label),
        actions: [
          if (MvpScope.showAppSwitcher) V2AppSwitcher(currentDomain: _currentDomain),
          if (safeIndex != _messagesTabIndex(destinations))
            const NotificationBadgeButton(),
        ],
      ),
      body: IndexedStack(
        index: safeIndex,
        children: destinations.map((d) => d.page).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }

  int _messagesTabIndex(List<_ShellDestination> destinations) {
    final messagesLabel = AppLocalizations.of(context)!.appShellMessages;
    return destinations.indexWhere((d) => d.label == messagesLabel);
  }

  List<_ShellDestination> _destinations(AppLocalizations l10n) {
    final home = _ShellDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: l10n.appShellHome,
      page: widget.home,
    );
    final bookings = _ShellDestination(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: l10n.appShellBookings,
      page: const BookingHistoryPage(),
    );
    final messages = _ShellDestination(
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
      label: l10n.appShellMessages,
      page: const NotificationsPage(),
    );
    final profile = _ShellDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: l10n.appShellProfile,
      page: widget.role == V2AppShellRole.sitter
          ? const SitterProfilePage()
          : const OwnerProfilePage(),
    );

    if (widget.role == V2AppShellRole.sitter) {
      final items = [home, bookings, messages];
      if (!MvpScope.hideSitterWallet) {
        items.add(
          _ShellDestination(
            icon: Icons.account_balance_wallet_outlined,
            selectedIcon: Icons.account_balance_wallet,
            label: l10n.walletTitle,
            page: const WalletPage(),
          ),
        );
      }
      if (MvpScope.showPartnerDiscover) {
        items.add(
          _ShellDestination(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: l10n.discoverTitle,
            page: const DiscoverPage(),
          ),
        );
      }
      items.add(profile);
      return items;
    }

    final items = [home, bookings, messages];
    if (MvpScope.showPartnerDiscover) {
      items.add(
        _ShellDestination(
          icon: Icons.explore_outlined,
          selectedIcon: Icons.explore,
          label: l10n.discoverTitle,
          page: const DiscoverPage(),
        ),
      );
    }
    items.add(profile);
    return items;
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;
}

/// Kartu pintasan ekosistem growth: komunitas, loyalty, tips.
class V2GrowthHubSection extends StatelessWidget {
  const V2GrowthHubSection({
    super.key,
    this.role = V2AppShellRole.owner,
  });

  final V2AppShellRole role;

  @override
  Widget build(BuildContext context) {
    final hideCommunity = MvpScope.hideCommunityFeatures;
    final hideLoyalty = MvpScope.hideLoyaltyReferral;
    final hidePromo = MvpScope.hideSitterPromotions;
    if (hideCommunity && hideLoyalty && (role == V2AppShellRole.owner || hidePromo)) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.growthHubTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.growthHubSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!MvpScope.hideCommunityFeatures) ...[
                  ActionChip(
                    avatar: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(l10n.growthHubGallery),
                    onPressed: () {
                      Navigator.of(context).push(
                        V2PageRoute(page: const PetGalleryPage()),
                      );
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.auto_stories_outlined, size: 18),
                    label: Text(l10n.growthHubStori),
                    onPressed: () {
                      Navigator.of(context).push(
                        V2PageRoute(page: const StoriFeedPage()),
                      );
                    },
                  ),
                ],
                if (!MvpScope.hideLoyaltyReferral && role == V2AppShellRole.owner)
                  ActionChip(
                    avatar: const Icon(Icons.stars_outlined, size: 18),
                    label: Text(l10n.loyaltyPointsTitle),
                    onPressed: () {
                      Navigator.of(context).push(
                        V2PageRoute(page: const OwnerProfilePage()),
                      );
                    },
                  ),
                if (!MvpScope.hideSitterPromotions &&
                    role == V2AppShellRole.sitter)
                  ActionChip(
                    avatar: const Icon(Icons.local_offer_outlined, size: 18),
                    label: Text(l10n.promoTitle),
                    onPressed: () {
                      Navigator.of(context).push(
                        V2PageRoute(page: const PromotionsPage()),
                      );
                    },
                  ),
                if (MvpScope.showPartnerDiscover)
                  ActionChip(
                    avatar: const Icon(Icons.explore_outlined, size: 18),
                    label: Text(l10n.discoverTitle),
                    onPressed: () {
                      Navigator.of(context).push(
                        V2PageRoute(page: const DiscoverPage()),
                      );
                    },
                  ),
                ActionChip(
                  avatar: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text(l10n.growthHubTips),
                  onPressed: () {
                    Navigator.of(context).push(
                      V2PageRoute(page: const TipsArticlesPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
