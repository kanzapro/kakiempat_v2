import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kaki_empat/core/config/app_config.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';

class V2ApiException implements Exception {
  V2ApiException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => message;
}

class V2ApiClient {
  V2ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static final V2ApiClient instance = V2ApiClient();

  final http.Client _client;

  String url(String script, {String? action, Map<String, String>? query}) {
    final params = <String, String>{
      if (action != null && action.isNotEmpty) 'action': action,
      ...?query,
    };
    final base = '${AppConfig.apiBaseUrl}/$script';
    if (params.isEmpty) return base;
    return Uri.parse(base).replace(queryParameters: params).toString();
  }

  Future<Map<String, String>> authHeaders() async {
    final token = await AuthServiceV2.instance.getToken();
    if (token == null || token.isEmpty) {
      throw V2ApiException('token_required', 'Silakan masuk terlebih dahulu.');
    }
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> getPublic(
    String script, {
    String? action,
    Map<String, String>? query,
  }) {
    return _client.get(
      Uri.parse(url(script, action: action, query: query)),
      headers: {'Accept': 'application/json'},
    );
  }

  Future<http.Response> getAuth(
    String script, {
    String? action,
    Map<String, String>? query,
  }) async {
    return _client.get(
      Uri.parse(url(script, action: action, query: query)),
      headers: await authHeaders(),
    );
  }

  Future<http.Response> postAuth(
    String script, {
    String? action,
    Map<String, dynamic>? body,
  }) async {
    return _client.post(
      Uri.parse(url(script, action: action)),
      headers: await authHeaders(),
      body: jsonEncode(body ?? {}),
    );
  }

  Future<T> parse<T>(
    http.Response response,
    T Function(Map<String, dynamic> body) map,
  ) async {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw V2ApiException('parse_error', 'Respons server tidak valid.');
    }
    if (response.statusCode >= 400 || body['ok'] != true) {
      final code = body['error'] as String? ?? 'failed';
      final msg = body['message'] as String? ?? 'Permintaan gagal.';
      throw V2ApiException(code, msg);
    }
    final data = body['data'];
    final payload = data is Map<String, dynamic> ? data : body;
    return map(payload);
  }
}
