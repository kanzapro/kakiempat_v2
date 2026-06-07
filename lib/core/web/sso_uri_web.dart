import 'package:web/web.dart' as web;

String? readSsoCodeFromUri() {
  final code = Uri.base.queryParameters['sso'];
  if (code == null || code.trim().isEmpty) return null;
  return code.trim();
}

void clearSsoFromUri() {
  final uri = Uri.parse(web.window.location.href);
  if (!uri.queryParameters.containsKey('sso')) return;
  final params = Map<String, String>.from(uri.queryParameters)..remove('sso');
  final next = uri.replace(queryParameters: params.isEmpty ? null : params);
  web.window.history.replaceState(null, '', next.toString());
}

String? readReturnTargetFromUri() {
  final target = Uri.base.queryParameters['return'];
  if (target == null || target.trim().isEmpty) return null;
  return target.trim().toLowerCase();
}

String? readAuthActionFromUri() {
  final action = Uri.base.queryParameters['auth'];
  if (action == null || action.trim().isEmpty) return null;
  return action.trim().toLowerCase();
}

void clearAuthParamsFromUri() {
  final uri = Uri.parse(web.window.location.href);
  final params = Map<String, String>.from(uri.queryParameters);
  final changed =
      params.remove('auth') != null || params.remove('return') != null;
  if (!changed) return;
  final next = uri.replace(queryParameters: params.isEmpty ? null : params);
  web.window.history.replaceState(null, '', next.toString());
}
