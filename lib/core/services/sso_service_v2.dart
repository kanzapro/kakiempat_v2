import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kaki_empat/core/config/app_config.dart';
import 'package:kaki_empat/core/models/auth_user_v2.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';

/// SSO lintas subdomain — kode sekali pakai dari domain utama.
class SsoServiceV2 {
  SsoServiceV2({http.Client? client}) : _client = client ?? http.Client();

  static final SsoServiceV2 instance = SsoServiceV2();

  static const List<String> allowedTargets = [
    'owner',
    'sitter',
    'admin',
    'staging',
  ];

  final http.Client _client;

  String get _authUrl => '${AppConfig.apiBaseUrl}/auth_v2.php';

  Future<SsoRedirectV2> createRedirect({required String target}) async {
    final normalized = target.trim().toLowerCase();
    if (!allowedTargets.contains(normalized)) {
      throw AuthException('invalid_target', 'Target SSO tidak valid.');
    }

    final token = await AuthServiceV2.instance.getToken();
    if (token == null || token.isEmpty) {
      throw AuthException('token_required', AuthServiceV2.friendlyMessage('token_required'));
    }

    final response = await _client.post(
      Uri.parse('$_authUrl?action=sso_create'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'target': normalized}),
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
      throw AuthException(code, _ssoMessage(code, msg));
    }

    final targetUrl = body['target_url'] as String?;
    if (targetUrl == null || targetUrl.isEmpty) {
      throw AuthException('invalid_response', 'URL SSO tidak tersedia.');
    }

    return SsoRedirectV2(
      code: body['code'] as String? ?? '',
      target: normalized,
      targetUrl: targetUrl,
      expiresIn: body['expires_in'] as int? ?? 120,
    );
  }

  Future<AuthSessionV2> exchangeCode(String code) async {
    if (code.isEmpty || !code.startsWith('sso_')) {
      throw AuthException('invalid_sso_code', 'Kode SSO tidak valid.');
    }

    final response = await _client.post(
      Uri.parse('$_authUrl?action=sso_exchange'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'code': code}),
    );

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException('parse_error', 'Respons server tidak valid.');
    }

    if (body['ok'] != true) {
      final err = body['error'] as String? ?? 'failed';
      final msg = body['message'] as String?;
      throw AuthException(err, _ssoMessage(err, msg));
    }

    final token = body['token'] as String?;
    final userMap = body['user'];
    if (token == null || userMap is! Map<String, dynamic>) {
      throw AuthException('invalid_response', 'Data SSO tidak lengkap.');
    }

    final session = AuthSessionV2(
      token: token,
      user: AuthUserV2.fromJson(userMap),
    );
    await AuthServiceV2.instance.persistSession(session);
    return session;
  }

  static String _ssoMessage(String code, String? serverMessage) {
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return serverMessage;
    }
    switch (code) {
      case 'invalid_sso_code':
      case 'sso_code_used':
      case 'sso_code_expired':
        return 'Kode SSO tidak valid atau kedaluwarsa. Silakan masuk lagi.';
      case 'sso_unavailable':
        return 'SSO belum aktif. Silakan masuk langsung di subdomain ini.';
      default:
        return 'Gagal SSO. Coba lagi.';
    }
  }
}

class SsoRedirectV2 {
  const SsoRedirectV2({
    required this.code,
    required this.target,
    required this.targetUrl,
    required this.expiresIn,
  });

  final String code;
  final String target;
  final String targetUrl;
  final int expiresIn;
}
