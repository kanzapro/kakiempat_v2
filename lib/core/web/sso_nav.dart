import 'package:flutter/foundation.dart';
import 'package:kaki_empat/core/config/app_config.dart';
import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';
import 'package:kaki_empat/core/services/sso_service_v2.dart';
import 'package:kaki_empat/core/web/web_nav.dart';

abstract final class SsoNav {
  static String urlForTarget(String target) {
    switch (target) {
      case 'owner':
        return AppConfig.ownerUrl;
      case 'sitter':
        return AppConfig.sitterUrl;
      case 'admin':
        return AppConfig.adminUrl;
      case 'staging':
        return AppConfig.stagingUrl;
      default:
        return AppConfig.wwwUrl;
    }
  }

  static String loginUrlOnWww({String? returnTarget, String auth = 'login'}) {
    final base = Uri.parse(AppConfig.wwwUrl);
    final params = <String, String>{'auth': auth};
    if (returnTarget != null && returnTarget.isNotEmpty) {
      params['return'] = returnTarget;
    }
    return base.replace(queryParameters: params).toString();
  }

  static Future<void> openSubdomain(String target) async {
    if (!kIsWeb) return;
    final normalized = target.trim().toLowerCase();
    final user = await AuthServiceV2.instance.getStoredUser();
    if (!MvpScope.isTargetReachable(normalized, user)) {
      navigateToUrl(
        '${urlForTarget(normalized)}?preview=1',
      );
      return;
    }
    if (!SsoServiceV2.allowedTargets.contains(normalized)) {
      navigateToUrl(urlForTarget(normalized));
      return;
    }
    final loggedIn = await AuthServiceV2.instance.isLoggedIn();
    if (!loggedIn) {
      navigateToUrl(loginUrlOnWww(returnTarget: normalized));
      return;
    }
    try {
      final redirect = await SsoServiceV2.instance.createRedirect(target: normalized);
      navigateToUrl(redirect.targetUrl);
    } on AuthException {
      navigateToUrl(loginUrlOnWww(returnTarget: normalized));
    } catch (_) {
      navigateToUrl(urlForTarget(normalized));
    }
  }

  static void redirectToWwwLogin({required String returnTarget}) {
    if (!kIsWeb) return;
    navigateToUrl(loginUrlOnWww(returnTarget: returnTarget));
  }
}
