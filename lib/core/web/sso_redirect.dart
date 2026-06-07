import 'package:flutter/foundation.dart';
import 'package:kaki_empat/core/config/app_config.dart';
import 'package:kaki_empat/core/models/auth_user_v2.dart';
import 'package:kaki_empat/core/services/sso_service_v2.dart';
import 'package:kaki_empat/core/web/domain_kind.dart';
import 'package:kaki_empat/core/web/web_nav.dart';

/// SSO pusat di www — redirect login & setelah auth.
abstract final class SsoRedirect {
  static String loginUrl({WebDomain? redirect}) {
    final target = redirect ?? WebDomain.owner;
    return '${AppConfig.wwwUrl}?auth=login&redirect=${target.name}';
  }

  static String registerUrl({
    WebDomain? redirect,
    String role = 'owner',
  }) {
    final target = redirect ?? WebDomain.owner;
    return '${AppConfig.wwwUrl}?auth=register&redirect=${target.name}&role=$role';
  }

  static String forgotPasswordUrl({WebDomain? redirect}) {
    final target = redirect ?? WebDomain.owner;
    return '${AppConfig.wwwUrl}?auth=forgot&redirect=${target.name}';
  }

  static String resetPasswordUrl({WebDomain? redirect}) {
    final target = redirect ?? WebDomain.owner;
    return '${AppConfig.wwwUrl}?auth=reset&redirect=${target.name}';
  }

  static String? parseAuthMode(Uri uri) {
    final mode = uri.queryParameters['auth']?.trim().toLowerCase();
    return switch (mode) {
      'login' || 'register' || 'forgot' || 'reset' => mode,
      _ => null,
    };
  }

  static WebDomain? parseRedirect(Uri uri) {
    final raw = uri.queryParameters['redirect']?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;
    return switch (raw) {
      'owner' => WebDomain.owner,
      'sitter' => WebDomain.sitter,
      'admin' => WebDomain.admin,
      'staging' => WebDomain.staging,
      'www' => WebDomain.www,
      _ => null,
    };
  }

  static String parseRole(Uri uri) {
    final role = uri.queryParameters['role']?.trim().toLowerCase();
    return role == 'sitter' ? 'sitter' : 'owner';
  }

  /// Alihkan ke subdomain aplikasi setelah login/register di www (dengan kode SSO).
  static Future<void> navigateToApp(
    AuthUserV2 user, {
    WebDomain? redirect,
  }) async {
    if (!kIsWeb) return;
    final target = _resolveTarget(user, redirect);
    final targetName = target.name;

    if (!SsoServiceV2.allowedTargets.contains(targetName)) {
      navigateToUrl(_urlForDomain(target));
      return;
    }

    try {
      final handoff =
          await SsoServiceV2.instance.createRedirect(target: targetName);
      navigateToUrl(handoff.targetUrl);
    } catch (_) {
      navigateToUrl(_urlForDomain(target));
    }
  }

  static WebDomain _resolveTarget(AuthUserV2 user, WebDomain? redirect) {
    if (redirect == WebDomain.admin && user.isAdmin) {
      return WebDomain.admin;
    }
    if (redirect == WebDomain.sitter && (user.isSitter || user.isFounder)) {
      return WebDomain.sitter;
    }
    if (redirect == WebDomain.owner) {
      return WebDomain.owner;
    }
    if (redirect == WebDomain.staging) {
      return WebDomain.staging;
    }
    if (user.isFounder || user.isAdmin) {
      return WebDomain.admin;
    }
    if (user.isSitter) return WebDomain.sitter;
    if (user.isOwner) return WebDomain.owner;
    return WebDomain.owner;
  }

  static String _urlForDomain(WebDomain domain) {
    return switch (domain) {
      WebDomain.owner => AppConfig.ownerUrl,
      WebDomain.sitter => AppConfig.sitterUrl,
      WebDomain.admin => AppConfig.adminUrl,
      WebDomain.staging => AppConfig.stagingUrl,
      WebDomain.www => AppConfig.wwwUrl,
      WebDomain.api || WebDomain.unknown => AppConfig.wwwUrl,
    };
  }

  /// Subdomain terproteksi → login terpusat di www.
  static void toWwwLogin({required WebDomain redirect}) {
    if (!kIsWeb) return;
    navigateToUrl(loginUrl(redirect: redirect));
  }
}
