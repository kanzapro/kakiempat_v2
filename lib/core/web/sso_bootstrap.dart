import 'package:flutter/foundation.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';
import 'package:kaki_empat/core/services/sso_service_v2.dart';
import 'package:kaki_empat/core/web/sso_uri.dart';

/// Menukar ?sso= dari URL subdomain menjadi sesi lokal.
abstract final class SsoBootstrap {
  static Future<bool> tryConsumeUriCode() async {
    if (!kIsWeb) return false;

    final code = readSsoCodeFromUri();
    if (code == null || code.isEmpty) return false;

    try {
      await SsoServiceV2.instance.exchangeCode(code);
      clearSsoFromUri();
      return true;
    } on AuthException {
      clearSsoFromUri();
      return false;
    } catch (_) {
      clearSsoFromUri();
      return false;
    }
  }
}
