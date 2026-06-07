import 'package:web/web.dart' as web;

/// Cookie SSO lintas subdomain (*.kakiempat.com).
abstract final class SsoCookieStorage {
  static const String tokenCookieName = 'ke_sso_token';
  static const String userCookieName = 'ke_sso_user';
  static const int _maxAgeSeconds = 60 * 60 * 24 * 30;

  static bool get isAvailable {
    final host = web.window.location.hostname.toLowerCase();
    return host.endsWith('.kakiempat.com') || host == 'kakiempat.com';
  }

  static String? readToken() => _read(tokenCookieName);

  static String? readUserJson() {
    final raw = _read(userCookieName);
    if (raw == null) return null;
    return Uri.decodeComponent(raw);
  }

  static void writeSession({
    required String token,
    required String userJson,
  }) {
    if (!isAvailable) return;
    _write(tokenCookieName, token);
    _write(userCookieName, userJson);
  }

  static void clear() {
    if (!isAvailable) return;
    _expire(tokenCookieName);
    _expire(userCookieName);
  }

  static String? _read(String name) {
    final prefix = '$name=';
    for (final part in web.document.cookie.split(';')) {
      final trimmed = part.trim();
      if (trimmed.startsWith(prefix)) {
        final value = trimmed.substring(prefix.length);
        if (value.isEmpty) return null;
        return Uri.decodeComponent(value);
      }
    }
    return null;
  }

  static void _write(String name, String value) {
    final encoded = Uri.encodeComponent(value);
    web.document.cookie =
        '$name=$encoded; path=/; domain=.kakiempat.com; max-age=$_maxAgeSeconds; SameSite=Lax; Secure';
  }

  static void _expire(String name) {
    web.document.cookie =
        '$name=; path=/; domain=.kakiempat.com; max-age=0; SameSite=Lax; Secure';
  }
}
