import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

/// Sanitasi pesan error — jangan tampilkan detail teknis ke pengguna.
abstract final class V2UserError {
  static String message(BuildContext context, [Object? error]) {
    final l10n = AppLocalizations.of(context)!;
    if (error is V2ApiException) {
      final text = error.message.trim();
      if (text.isNotEmpty && !_looksTechnical(text)) {
        return text;
      }
    }
    return l10n.errorStateBody;
  }

  static bool _looksTechnical(String text) {
    final lower = text.toLowerCase();
    const markers = [
      'exception',
      'stack',
      'sql',
      'pdo',
      'fatal',
      'undefined',
      'null pointer',
      'http ',
      'curl',
      'json',
      'syntax',
      '500',
      '503',
      '404',
    ];
    return markers.any(lower.contains);
  }
}
