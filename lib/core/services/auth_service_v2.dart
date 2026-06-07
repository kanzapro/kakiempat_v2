import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kaki_empat/core/config/app_config.dart';
import 'package:kaki_empat/core/models/auth_user_v2.dart';
import 'package:kaki_empat/core/web/credentialed_http_client.dart';
import 'package:kaki_empat/core/web/sso_cookie_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Autentikasi v2 — plaintext password ke server, bcrypt di PHP.
class AuthServiceV2 {
  AuthServiceV2({http.Client? client}) : _client = client ?? http.Client();

  static const String tokenKey = 'auth_v2_token';
  static const String userKey = 'auth_v2_user';
  static final AuthServiceV2 instance = AuthServiceV2();

  final http.Client _client;
  SharedPreferences? _prefs;

  String get _authUrl => '${AppConfig.apiBaseUrl}/auth_v2.php';

  Future<SharedPreferences> _storage() async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Terima 08xx, 62xx, +62xx → 62xxxxxxxx (11–14 digit).
  static String? normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    var n = digits;
    if (n.startsWith('0')) {
      n = '62${n.substring(1)}';
    }
    if (!n.startsWith('62')) return null;
    if (n.length < 11 || n.length > 14) return null;
    return n;
  }

  static bool isValidPassword(String password) => password.length >= 6;

  static String friendlyMessage(String code, [String? serverMessage]) {
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return serverMessage;
    }
    switch (code) {
      case 'invalid_phone':
        return 'Format nomor tidak dikenali. Gunakan 08xx, 62xx, atau +62xx.';
      case 'invalid_password':
        return 'Kata sandi minimal 6 karakter.';
      case 'invalid_name':
        return 'Nama wajib diisi.';
      case 'invalid_role':
        return 'Peran harus pemilik hewan atau pengasuh.';
      case 'already_registered':
      case 'phone_exists':
        return 'Nomor sudah terdaftar. Silakan login.';
      case 'wrong_password':
      case 'invalid_credentials':
        return 'Kata sandi salah. Periksa lagi atau gunakan nomor lain.';
      case 'user_not_found':
        return 'Nomor belum terdaftar. Silakan daftar terlebih dahulu.';
      case 'token_required':
      case 'invalid_token':
      case 'token_expired':
        return 'Sesi berakhir. Silakan masuk lagi.';
      case 'invalid_reset_code':
      case 'reset_code_used':
      case 'reset_code_expired':
        return 'Kode reset tidak valid atau kedaluwarsa. Minta kode baru.';
      case 'reset_unavailable':
        return 'Reset kata sandi belum tersedia. Coba lagi nanti.';
      case 'register_failed':
        return 'Pendaftaran gagal. Coba lagi sebentar.';
      case 'name_mismatch':
        return 'Nama tidak cocok dengan nomor terdaftar. Periksa kembali.';
      case 'reset_failed':
        return 'Reset kata sandi gagal. Coba lagi sebentar.';
      case 'db_unavailable':
      case 'config_missing':
        return 'Layanan sibuk. Coba lagi nanti.';
      default:
        return 'Permintaan gagal. Coba lagi.';
    }
  }

  /// Sinkronkan sesi dari cookie SSO (web lintas subdomain).
  Future<bool> bootstrapSso() async {
    if (!kIsWeb || !SsoCookieStorage.isAvailable) return false;

    if (await _bootstrapFromSharedCookies()) return true;
    return _bootstrapFromRefreshCookie();
  }

  Future<bool> _bootstrapFromSharedCookies() async {
    final cookieToken = SsoCookieStorage.readToken();
    if (cookieToken == null || cookieToken.isEmpty) return false;

    final localToken = await getToken();
    if (localToken == cookieToken) return localToken != null;

    final cookieUser = SsoCookieStorage.readUserJson();
    if (cookieUser != null) {
      try {
        final user = AuthUserV2.fromJson(
          jsonDecode(cookieUser) as Map<String, dynamic>,
        );
        await _persist(AuthSessionV2(token: cookieToken, user: user));
        return true;
      } catch (_) {}
    }

    try {
      final user = await validateToken(token: cookieToken);
      await _persist(AuthSessionV2(token: cookieToken, user: user));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cookie HttpOnly `ke_sso_rt` (.kakiempat.com) → sesi baru via API.
  Future<bool> _bootstrapFromRefreshCookie() async {
    final credentialed = createCredentialedHttpClient();
    try {
      final response = await credentialed.post(
        Uri.parse('$_authUrl?action=sso_bootstrap'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: '{}',
      );
      final session = await _parseAuthResponse(response, withToken: true);
      return session.token.isNotEmpty;
    } on AuthException {
      return false;
    } catch (_) {
      return false;
    } finally {
      credentialed.close();
    }
  }

  Future<String?> getToken() async => (await _storage()).getString(tokenKey);

  Future<AuthUserV2?> getStoredUser() async {
    final raw = (await _storage()).getString(userKey);
    if (raw == null) return null;
    try {
      return AuthUserV2.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    try {
      await validateToken(token: token);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AuthSessionV2> register({
    required String phone,
    required String password,
    required String name,
    required String role,
    String referralCode = '',
  }) async {
    final normalized = normalizePhone(phone);
    if (normalized == null) {
      throw AuthException('invalid_phone', friendlyMessage('invalid_phone'));
    }
    if (!isValidPassword(password)) {
      throw AuthException('invalid_password', friendlyMessage('invalid_password'));
    }
    if (name.trim().isEmpty) {
      throw AuthException('invalid_name', friendlyMessage('invalid_name'));
    }
    final response = await _client.post(
      Uri.parse('$_authUrl?action=register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'phone': normalized,
        'password': password,
        'name': name.trim(),
        'role': role,
        if (referralCode.trim().isNotEmpty) 'referral_code': referralCode.trim(),
      }),
    );
    return _parseAuthResponse(response, withToken: true);
  }

  Future<AuthSessionV2> login({
    required String phone,
    required String password,
  }) async {
    final normalized = normalizePhone(phone);
    if (normalized == null) {
      throw AuthException('invalid_phone', friendlyMessage('invalid_phone'));
    }
    if (password.isEmpty) {
      throw AuthException('invalid_password', 'Kata sandi wajib diisi.');
    }
    final response = await _client.post(
      Uri.parse('$_authUrl?action=login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'phone': normalized, 'password': password}),
    );
    return _parseAuthResponse(response, withToken: true);
  }

  Future<AuthUserV2> validateToken({String? token}) async {
    final t = token ?? await getToken();
    if (t == null || t.isEmpty) {
      throw AuthException('token_required', friendlyMessage('token_required'));
    }
    final response = await _client.get(
      Uri.parse('$_authUrl?action=validate_token'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $t',
      },
    );
    final session = await _parseAuthResponse(response, withToken: false);
    return session.user;
  }

  Future<String> forgotPassword({required String phone}) async {
    final normalized = normalizePhone(phone);
    if (normalized == null) {
      throw AuthException('invalid_phone', friendlyMessage('invalid_phone'));
    }
    final response = await _client.post(
      Uri.parse('$_authUrl?action=forgot_password'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'phone': normalized}),
    );
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException('parse_error', 'Respons server tidak valid.');
    }
    if (body['ok'] != true) {
      final code = body['error'] as String? ?? 'failed';
      final msg = body['message'] as String?;
      throw AuthException(code, friendlyMessage(code, msg));
    }
    return body['message'] as String? ??
        'Jika nomor terdaftar, kode reset dikirim ke notifikasi aplikasi Anda.';
  }

  Future<void> resetPassword({
    required String phone,
    required String resetCode,
    required String newPassword,
  }) async {
    final normalized = normalizePhone(phone);
    if (normalized == null) {
      throw AuthException('invalid_phone', friendlyMessage('invalid_phone'));
    }
    if (!isValidPassword(newPassword)) {
      throw AuthException('invalid_password', friendlyMessage('invalid_password'));
    }
    final response = await _client.post(
      Uri.parse('$_authUrl?action=reset_password'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'phone': normalized,
        'reset_code': resetCode.trim(),
        'new_password': newPassword,
      }),
    );
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException('parse_error', 'Respons server tidak valid.');
    }
    if (body['ok'] != true) {
      final code = body['error'] as String? ?? 'failed';
      final msg = body['message'] as String?;
      throw AuthException(code, friendlyMessage(code, msg));
    }
  }

  Future<void> persistSession(AuthSessionV2 session) => _persist(session);

  Future<void> logout() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await _client.post(
          Uri.parse('$_authUrl?action=logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {}
    }
    await _clearLocal();
    SsoCookieStorage.clear();
  }

  Future<void> _clearLocal() async {
    final prefs = await _storage();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!isValidPassword(newPassword)) {
      throw AuthException(
        'invalid_password',
        friendlyMessage('invalid_password'),
      );
    }
    final response = await _client.post(
      Uri.parse('$_authUrl?action=change_password'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...(await _authHeaders()),
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException('parse_error', 'Respons server tidak valid.');
    }
    if (body['ok'] != true) {
      final code = body['error'] as String? ?? 'failed';
      final msg = body['message'] as String?;
      throw AuthException(code, friendlyMessage(code, msg));
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw AuthException('token_required', friendlyMessage('token_required'));
    }
    return {
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _persist(AuthSessionV2 session) async {
    final prefs = await _storage();
    final userJson = jsonEncode(session.user.toJson());
    await prefs.setString(tokenKey, session.token);
    await prefs.setString(userKey, userJson);
    if (kIsWeb && SsoCookieStorage.isAvailable) {
      SsoCookieStorage.writeSession(
        token: session.token,
        userJson: userJson,
      );
    }
  }

  Future<AuthSessionV2> _parseAuthResponse(
    http.Response response, {
    required bool withToken,
  }) async {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException('parse_error', 'Respons server tidak valid.');
    }

    if (body['ok'] != true) {
      final code = body['error'] as String? ?? 'failed';
      final msg = body['message'] as String?;
      throw AuthException(code, friendlyMessage(code, msg));
    }

    if (withToken) {
      final token = body['token'] as String?;
      final userMap = body['user'];
      if (token == null || userMap is! Map<String, dynamic>) {
        throw AuthException('invalid_response', 'Data masuk tidak lengkap.');
      }
      final session =
          AuthSessionV2(token: token, user: AuthUserV2.fromJson(userMap));
      await _persist(session);
      return session;
    }

    final userMap = body['user'];
    if (userMap is! Map<String, dynamic>) {
      throw AuthException('invalid_response', 'Data pengguna tidak lengkap.');
    }
    final user = AuthUserV2.fromJson(userMap);
    final existing = await getToken() ?? '';
    if (existing.isNotEmpty) {
      await _persist(AuthSessionV2(token: existing, user: user));
    }
    return AuthSessionV2(token: existing, user: user);
  }
}

class AuthSessionV2 {
  const AuthSessionV2({required this.token, required this.user});
  final String token;
  final AuthUserV2 user;
}

class AuthException implements Exception {
  AuthException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'AuthException($code): $message';
}
