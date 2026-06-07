import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kaki_empat/core/config/app_config.dart';

/// Status pembayaran booking dari `payment_status.php`.
class PaymentStatusSnapshot {
  const PaymentStatusSnapshot({
    required this.bookingId,
    required this.status,
    required this.paymentState,
    required this.displayLabel,
    required this.totalPrice,
    required this.paymentAmount,
    required this.platformFeeOwner,
    required this.ownerPays,
    this.paymentMatchedAt,
  });

  final String bookingId;
  final String status;
  final String paymentState;
  final String displayLabel;
  final int totalPrice;
  final int paymentAmount;
  final int platformFeeOwner;
  final int ownerPays;
  final String? paymentMatchedAt;

  bool get isWaiting => paymentState == 'waiting';
  bool get isReceived => paymentState == 'received';
  bool get isMismatch => paymentState == 'mismatch';
  bool get isPaid => status.toUpperCase() == 'PAID' || isReceived;

  factory PaymentStatusSnapshot.fromJson(Map<String, dynamic> json) {
    final totalPrice = (json['total_price'] as num?)?.toInt() ?? 0;
    final paymentAmount = (json['payment_amount'] as num?)?.toInt() ?? 0;
    final platformFeeOwner = (json['platform_fee_owner'] as num?)?.toInt() ??
        AppConfig.platformFeeOwner(totalPrice);
    final ownerPays = (json['owner_pays'] as num?)?.toInt() ??
        AppConfig.ownerTotalFromRate(totalPrice);

    return PaymentStatusSnapshot(
      bookingId: '${json['booking_id'] ?? ''}',
      status: '${json['status'] ?? ''}',
      paymentState: '${json['payment_state'] ?? 'waiting'}',
      displayLabel: '${json['display_label'] ?? 'Menunggu Pembayaran'}',
      totalPrice: totalPrice,
      paymentAmount: paymentAmount,
      platformFeeOwner: platformFeeOwner,
      ownerPays: ownerPays,
      paymentMatchedAt: json['payment_matched_at'] as String?,
    );
  }
}

class PaymentStatusService {
  PaymentStatusService({http.Client? client}) : _client = client ?? http.Client();

  static final PaymentStatusService instance = PaymentStatusService();

  final http.Client _client;

  String get _statusUrl => '${AppConfig.apiBaseUrl}/payment_status.php';

  Future<PaymentStatusSnapshot> fetchStatus(String bookingId) async {
    final uri = Uri.parse(_statusUrl).replace(
      queryParameters: {'booking_id': bookingId},
    );
    final response = await _client.get(uri);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400 || body['ok'] != true) {
      final message = body['message'] as String? ?? 'Gagal memuat status pembayaran.';
      throw PaymentStatusException(message);
    }
    return PaymentStatusSnapshot.fromJson(body);
  }
}

class PaymentStatusException implements Exception {
  PaymentStatusException(this.message);
  final String message;

  @override
  String toString() => message;
}
