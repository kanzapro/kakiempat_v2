/// Non-web: SSO cookie tidak tersedia.
abstract final class SsoCookieStorage {
  static const String tokenCookieName = 'ke_sso_token';
  static const String userCookieName = 'ke_sso_user';

  static bool get isAvailable => false;

  static String? readToken() => null;

  static String? readUserJson() => null;

  static void writeSession({required String token, required String userJson}) {}

  static void clear() {}
}
