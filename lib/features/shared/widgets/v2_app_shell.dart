import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/navigation/v2_page_route.dart';
import 'package:kaki_empat/features/community/presentation/pet_gallery_page.dart';
import 'package:kaki_empat/features/community/presentation/stori_feed_page.dart';
import 'package:kaki_empat/features/help/presentation/tips_articles_page.dart';
import 'package:kaki_empat/features/owner/presentation/owner_profile_page.dart';
import 'package:kaki_empat/features/shared/presentation/booking_history_page.dart';
import 'package:kaki_empat/features/shared/presentation/discover_page.dart';
import 'package:kaki_empat/features/shared/presentation/notifications_page.dart';
import 'package:kaki_empat/features/sitter/presentation/wallet_page.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

enum V2AppShellRole { owner, sitter }

/// Shell navigasi terpadu super-app (fase [LaunchPhase.full]).
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

  @override
  Widget build(BuildContext context) {
    if (!MvpScope.showUnifiedAppShell) {
      return widget.home;
    }

    final l10n = AppLocalizations.of(context)!;
    final destinations = _destinations(l10n);
    final safeIndex = _index.clamp(0, destinations.length - 1);

    return Scaffold(
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
    final discover = _ShellDestination(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: l10n.discoverTitle,
      page: const DiscoverPage(),
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
      if (MvpScope.showPartnerDiscover) items.add(discover);
      return items;
    }

    final items = [home, bookings, messages];
    if (MvpScope.showPartnerDiscover) items.add(discover);
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
  const V2GrowthHubSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (MvpScope.hideCommunityFeatures && MvpScope.hideLoyaltyReferral) {
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
                if (!MvpScope.hideLoyaltyReferral)
                  ActionChip(
                    avatar: const Icon(Icons.stars_outlined, size: 18),
                    label: Text(l10n.loyaltyPointsTitle),
                    onPressed: () {
                      Navigator.of(context).push(
                        V2PageRoute(page: const OwnerProfilePage()),
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
