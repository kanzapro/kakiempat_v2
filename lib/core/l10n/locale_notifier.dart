import 'package:flutter/foundation.dart';

enum AppLocale { id, en }

/// Notifier bahasa untuk layar auth (ID / EN).
final class LocaleNotifier extends ChangeNotifier {
  LocaleNotifier._();
  static final LocaleNotifier instance = LocaleNotifier._();

  AppLocale _locale = AppLocale.id;
  AppLocale get locale => _locale;

  void setLocale(AppLocale value) {
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
  }
}
