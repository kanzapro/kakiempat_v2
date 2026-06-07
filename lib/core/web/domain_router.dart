import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kaki_empat/core/models/auth_user_v2.dart';
import 'package:kaki_empat/core/web/domain_kind.dart';
import 'package:kaki_empat/core/web/host_reader.dart';
import 'package:kaki_empat/features/admin/presentation/admin_dashboard_page.dart';
import 'package:kaki_empat/features/auth/presentation/auth_gate.dart';
import 'package:kaki_empat/features/owner/presentation/owner_shell.dart';
import 'package:kaki_empat/features/sitter/presentation/sitter_shell.dart';
import 'package:kaki_empat/core/web/post_auth_router.dart';
import 'package:kaki_empat/features/www/presentation/www_auth_shell.dart';

/// Multi-domain: www, owner (AuthGate), sitter, admin (AuthGate), staging, api.
class DomainRouter extends StatelessWidget {
  const DomainRouter({super.key, this.hostOverride});

  /// Untuk tes/widget — override hostname tanpa mengubah Uri web.
  final String? hostOverride;

  @override
  Widget build(BuildContext context) {
    return homeFor(resolve(hostOverride: hostOverride));
  }

  static WebDomain resolve({String? hostOverride}) {
    final host = _normalize(hostOverride ?? _host());
    return switch (host) {
      'kakiempat.com' || 'www.kakiempat.com' => WebDomain.www,
      'owner.kakiempat.com' => WebDomain.owner,
      'sitter.kakiempat.com' => WebDomain.sitter,
      'admin.kakiempat.com' => WebDomain.admin,
      'staging.kakiempat.com' => WebDomain.staging,
      'api.kakiempat.com' || 'www.api.kakiempat.com' => WebDomain.api,
      'localhost' || '127.0.0.1' => WebDomain.owner,
      _ => WebDomain.unknown,
    };
  }

  static Widget homeFor(WebDomain domain) {
    return switch (domain) {
      WebDomain.www => const WwwAuthShell(),
      WebDomain.owner => AuthGate(
          domain: domain,
          child: const OwnerShell(),
        ),
      WebDomain.sitter => AuthGate(
          domain: domain,
          child: const SitterShell(),
        ),
      WebDomain.admin => AuthGate(
          domain: domain,
          child: const AdminDashboardPage(),
        ),
      WebDomain.staging => AuthGate(
          domain: WebDomain.owner,
          child: const OwnerShell(),
        ),
      WebDomain.api => const _ApiNote(),
      WebDomain.unknown => const WwwAuthShell(),
    };
  }

  static bool requiresLogin(WebDomain domain) =>
      domain == WebDomain.owner ||
      domain == WebDomain.admin ||
      domain == WebDomain.staging;

  static String? accessDenied(WebDomain domain, AuthUserV2 user) {
    if (domain == WebDomain.admin && !user.isAdmin) {
      return 'Panel admin hanya untuk admin atau founder.';
    }
    if (domain == WebDomain.owner && !user.isOwner && !user.isFounder) {
      return 'Akun ini tidak dapat mengakses aplikasi pemilik.';
    }
    if (domain == WebDomain.sitter && !user.isSitter && !user.isFounder) {
      return 'Akun ini tidak dapat mengakses aplikasi pengasuh.';
    }
    return null;
  }

  static void navigateAfterAuth(BuildContext context, AuthUserV2 user) {
    PostAuthRouter.navigate(context, user);
  }

  static String? bookingIdFromUri() => _bookingIdFromUri();

  static String _host() {
    if (kIsWeb) {
      return readWebHostname();
    }
    return 'owner.kakiempat.com';
  }

  static String? _bookingIdFromUri() {
    if (!kIsWeb) return null;
    final id = Uri.base.queryParameters['booking_id'];
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  static String _normalize(String host) {
    final h = host.trim().toLowerCase();
    if (h.startsWith('www.') && h != 'www.kakiempat.com') {
      return h.substring(4);
    }
    return h;
  }
}

class _ApiNote extends StatelessWidget {
  const _ApiNote();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('www.api.kakiempat.com — auth_v2.php')),
    );
  }
}
