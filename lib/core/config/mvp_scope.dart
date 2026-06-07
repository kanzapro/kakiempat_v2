import 'package:kaki_empat/core/models/auth_user_v2.dart';
import 'package:kaki_empat/core/web/domain_kind.dart';

/// Fase peluncuran subdomain — owner = mesin uang (fase 1).
enum LaunchPhase {
  /// www + owner publik; sitter hanya akun verified; admin internal.
  ownerFirst,

  /// + promosi aplikasi sitter di www.
  marketplace,

  /// + komunitas, wallet, loyalty, blog www.
  growth,

  /// + link staging di www, semua subdomain terbuka.
  full,
}

/// Batas fitur & akses subdomain saat rollout bertahap.
abstract final class MvpScope {
  /// Ubah ke [LaunchPhase.marketplace] saat siap buka sitter ke publik.
  static const phase = LaunchPhase.ownerFirst;

  /// Subdomain yang menghasilkan pendapatan — prioritas UX & stabilitas.
  static const WebDomain moneyEngine = WebDomain.owner;

  static bool get hideCommunityFeatures =>
      phase.index < LaunchPhase.growth.index;

  static bool get hideOwnerFavorites =>
      phase.index < LaunchPhase.growth.index;

  static bool get hideLoyaltyReferral =>
      phase.index < LaunchPhase.growth.index;

  static bool get hideSitterWallet =>
      phase.index < LaunchPhase.growth.index;

  static bool get hideSitterPromotions =>
      phase.index < LaunchPhase.growth.index;

  static bool get hideWwwBlog => phase.index < LaunchPhase.growth.index;

  static bool get hideWwwAdminStagingLinks =>
      phase.index < LaunchPhase.full.index;

  /// Sembunyikan link langsung ke app sitter di www (CTA daftar sitter tetap ada).
  static bool get hideWwwSitterAppLink =>
      phase.index < LaunchPhase.marketplace.index;

  /// App switcher antar subdomain (fase marketplace+).
  static bool get showAppSwitcher =>
      phase.index >= LaunchPhase.marketplace.index;

  /// Rekomendasi rule-based di home owner (fase growth+).
  static bool get showPersonalizedRecommendations =>
      phase.index >= LaunchPhase.growth.index;

  /// Shell navigasi terpadu + discover partner (fase full).
  static bool get showUnifiedAppShell => phase.index >= LaunchPhase.full.index;

  static bool get showPartnerDiscover =>
      phase.index >= LaunchPhase.full.index;

  static bool isPublicSubdomain(WebDomain domain) {
    return switch (domain) {
      WebDomain.www => true,
      WebDomain.owner => true,
      WebDomain.sitter => phase.index >= LaunchPhase.marketplace.index,
      WebDomain.admin => false,
      WebDomain.staging => phase.index >= LaunchPhase.full.index,
      _ => false,
    };
  }

  static WebDomain? domainFromTarget(String target) {
    return switch (target.trim().toLowerCase()) {
      'owner' => WebDomain.owner,
      'sitter' => WebDomain.sitter,
      'admin' => WebDomain.admin,
      'staging' => WebDomain.staging,
      _ => null,
    };
  }

  /// Akses subdomain: publik, atau peran internal (sitter tetap bisa di fase 1).
  static bool canAccessSubdomain(WebDomain domain, AuthUserV2? user) {
    if (isPublicSubdomain(domain)) return true;
    if (user == null) return false;
    if (user.isFounder) return true;
    return switch (domain) {
      WebDomain.sitter => user.isSitter,
      WebDomain.admin => user.isAdmin,
      WebDomain.staging => user.isFounder,
      _ => false,
    };
  }

  static bool isTargetReachable(String target, AuthUserV2? user) {
    final domain = domainFromTarget(target);
    if (domain == null) return true;
    return canAccessSubdomain(domain, user);
  }
}
