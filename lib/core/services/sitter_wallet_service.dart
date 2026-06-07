import 'package:kaki_empat/core/services/v2_api_client.dart';

class WalletBalanceSnapshot {
  const WalletBalanceSnapshot({
    required this.balance,
    required this.pendingWithdrawals,
    required this.available,
  });

  final int balance;
  final int pendingWithdrawals;
  final int available;

  factory WalletBalanceSnapshot.fromJson(Map<String, dynamic> json) {
    return WalletBalanceSnapshot(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      pendingWithdrawals: (json['pending_withdrawals'] as num?)?.toInt() ?? 0,
      available: (json['available'] as num?)?.toInt() ?? 0,
    );
  }
}

class WalletLedgerEntry {
  const WalletLedgerEntry({
    required this.id,
    this.bookingId,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String? bookingId;
  final int amount;
  final String type;
  final String description;
  final String createdAt;

  factory WalletLedgerEntry.fromJson(Map<String, dynamic> json) {
    return WalletLedgerEntry(
      id: '${json['id'] ?? ''}',
      bookingId: json['booking_id']?.toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      type: '${json['type'] ?? ''}',
      description: '${json['description'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
    );
  }
}

class SitterWalletSummary {
  const SitterWalletSummary({
    required this.balance,
    required this.available,
    required this.pendingWithdrawals,
    required this.grossIncome,
    required this.platformFees,
    required this.netIncome,
    required this.platformFeeSitterPercent,
    required this.entries,
  });

  final int balance;
  final int available;
  final int pendingWithdrawals;
  final int grossIncome;
  final int platformFees;
  final int netIncome;
  final double platformFeeSitterPercent;
  final List<WalletLedgerEntry> entries;

  List<WalletLedgerEntry> get withdrawalEntries =>
      entries.where((e) => e.type == 'withdrawal').toList();

  factory SitterWalletSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['entries'];
    return SitterWalletSummary(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      available: (json['available'] as num?)?.toInt() ??
          (json['balance'] as num?)?.toInt() ??
          0,
      pendingWithdrawals: (json['pending_withdrawals'] as num?)?.toInt() ?? 0,
      grossIncome: (json['gross_income'] as num?)?.toInt() ?? 0,
      platformFees: (json['platform_fees'] as num?)?.toInt() ?? 0,
      netIncome: (json['net_income'] as num?)?.toInt() ?? 0,
      platformFeeSitterPercent:
          (json['platform_fee_sitter_percent'] as num?)?.toDouble() ?? 0.08,
      entries: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(WalletLedgerEntry.fromJson)
              .toList()
          : const [],
    );
  }
}

class SitterWalletService {
  SitterWalletService({V2ApiClient? client})
      : _api = client ?? V2ApiClient.instance;

  static final SitterWalletService instance = SitterWalletService();

  final V2ApiClient _api;
  static const _script = 'wallet_v2.php';

  Future<WalletBalanceSnapshot> getBalance() async {
    final response = await _api.getAuth(_script, action: 'get_balance');
    return _api.parse(response, WalletBalanceSnapshot.fromJson);
  }

  Future<SitterWalletSummary> getLedger() async {
    final response = await _api.getAuth(_script, action: 'get_ledger');
    return _api.parse(response, SitterWalletSummary.fromJson);
  }

  Future<SitterWalletSummary> getWallet() async {
    final results = await Future.wait([getBalance(), getLedger()]);
    final balance = results[0] as WalletBalanceSnapshot;
    final ledger = results[1] as SitterWalletSummary;
    return SitterWalletSummary(
      balance: balance.balance,
      available: balance.available,
      pendingWithdrawals: balance.pendingWithdrawals,
      grossIncome: ledger.grossIncome,
      platformFees: ledger.platformFees,
      netIncome: ledger.netIncome,
      platformFeeSitterPercent: ledger.platformFeeSitterPercent,
      entries: ledger.entries,
    );
  }

  Future<WithdrawalV2> requestWithdraw(
    int amount, {
    String? method,
    String? destination,
  }) async {
    final response = await _api.postAuth(
      _script,
      action: 'request_withdrawal',
      body: {
        'amount': amount,
        if (method != null && method.isNotEmpty) 'method': method,
        if (destination != null && destination.isNotEmpty)
          'destination': destination,
      },
    );
    return _api.parse(
      response,
      (body) => WithdrawalV2.fromJson(body['withdrawal'] as Map<String, dynamic>),
    );
  }
}

class WithdrawalV2 {
  const WithdrawalV2({
    required this.id,
    required this.amount,
    required this.status,
    this.createdAt = '',
    this.completedAt,
  });

  final String id;
  final int amount;
  final String status;
  final String createdAt;
  final String? completedAt;

  factory WithdrawalV2.fromJson(Map<String, dynamic> json) {
    return WithdrawalV2(
      id: '${json['id'] ?? ''}',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: '${json['status'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
      completedAt: json['completed_at'] as String?,
    );
  }
}
