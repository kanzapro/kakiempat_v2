// Konfigurasi global v2 (6 domain).

abstract final class AppConfig {

  static const String appName = 'Kaki Empat';



  static const String apiBaseUrl = String.fromEnvironment(

    'API_BASE_URL',

    defaultValue: 'https://www.api.kakiempat.com',

  );



  static const String ownerUrl = 'https://owner.kakiempat.com';

  static const String sitterUrl = 'https://sitter.kakiempat.com';

  static const String adminUrl = 'https://admin.kakiempat.com';

  static const String wwwUrl = 'https://www.kakiempat.com';

  static const String stagingUrl = 'https://staging.kakiempat.com';



  static const String seabankAccountNumber = String.fromEnvironment(

    'SEABANK_ACCOUNT_NUMBER',

    defaultValue: '901198073671',

  );



  static const String seabankAccountName = String.fromEnvironment(

    'SEABANK_ACCOUNT_NAME',

    defaultValue: 'Posman Tua Lamsihar Silaban',

  );



  /// Kode bank SeaBank untuk transfer internasional (Revolut/Wise).

  static const String seabankBankCode = '535';



  /// Biaya platform dari owner (5%).

  static const double platformFeeOwnerPercent = 0.05;



  /// Biaya platform dari sitter (8%).

  static const double platformFeeSitterPercent = 0.08;



  static int platformFeeOwner(int rate) {

    if (rate <= 0) return 0;

    return (rate * platformFeeOwnerPercent).round();

  }



  static int platformFeeSitter(int rate) {

    if (rate <= 0) return 0;

    return (rate * platformFeeSitterPercent).round();

  }



  static int ownerTotalFromRate(int rate) {

    if (rate <= 0) return 0;

    return rate + platformFeeOwner(rate);

  }



  static int sitterNetFromRate(int rate) {

    if (rate <= 0) return 0;

    return rate - platformFeeSitter(rate);

  }

}

