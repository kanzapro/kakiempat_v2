/// Rekening SeaBank & label — override via dart-define saat build web.
abstract final class PaymentConfig {
  static const String seabankAccountNumber = String.fromEnvironment(
    'SEABANK_ACCOUNT_NUMBER',
    defaultValue: '1234567890',
  );

  static const String seabankAccountName = String.fromEnvironment(
    'SEABANK_ACCOUNT_NAME',
    defaultValue: 'Kaki Empat',
  );

  static const String bankLabel = String.fromEnvironment(
    'SEABANK_BANK_LABEL',
    defaultValue: 'SeaBank Indonesia',
  );
}
