import 'package:kaki_empat/core/l10n/locale_notifier.dart';

export 'package:kaki_empat/core/l10n/locale_notifier.dart' show AppLocale;

/// Teks auth bilingual (ID / EN).
abstract final class AuthStrings {
  static AppLocale get locale => LocaleNotifier.instance.locale;

  static String t(String idText, String enText) =>
      locale == AppLocale.id ? idText : enText;

  static String get appTitle => t('Kaki Empat', 'Kaki Empat');

  static String get loginTitle => t('Masuk', 'Sign in');
  static String get registerTitle => t('Daftar', 'Register');
  static String get phoneLabel => t('Nomor WhatsApp', 'WhatsApp number');
  static String get phoneHint => t('08xx atau 628xx', '08xx or 628xx');
  static String get passwordLabel => t('Kata sandi', 'Password');
  static String get passwordHint => t('Min. 6 karakter', 'Min. 6 characters');
  static String get nameLabel => t('Nama lengkap', 'Full name');
  static String get roleLabel => t('Peran', 'Role');
  static String get roleOwner => t('Pemilik hewan', 'Pet owner');
  static String get roleSitter => t('Pengasuh', 'Pet sitter');
  static String get loginButton => t('Masuk', 'Sign in');
  static String get registerButton => t('Buat akun', 'Create account');
  static String get noAccount => t('Belum punya akun?', "Don't have an account?");
  static String get hasAccount => t('Sudah punya akun?', 'Already have an account?');
  static String get goRegister => t('Daftar', 'Register');
  static String get goLogin => t('Masuk', 'Sign in');
  static String get logout => t('Keluar', 'Log out');
  static String get language => t('Bahasa', 'Language');
  static String get loading => t('Memuat…', 'Loading…');
  static String get accessDenied =>
      t('Akses ditolak untuk domain ini.', 'Access denied for this domain.');

  static String phoneValidationError(String digits) => t(
        'Nomor harus $digits digit (setelah dinormalisasi).',
        'Number must be $digits digits (after normalization).',
      );

  static String passwordValidationError() => t(
        'Kata sandi minimal 6 karakter.',
        'Password must be at least 6 characters.',
      );

  static String nameValidationError() =>
      t('Nama wajib diisi.', 'Name is required.');

  static String genericError(String message) => message;
}
