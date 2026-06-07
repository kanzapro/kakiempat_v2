import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kaki_empat/core/config/app_config.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';

class PaymentBankConfig {
  const PaymentBankConfig({
    required this.accountNumber,
    required this.accountName,
    required this.bankLabel,
  });

  final String accountNumber;
  final String accountName;
  final String bankLabel;

  factory PaymentBankConfig.fromJson(Map<String, dynamic> json) {
    return PaymentBankConfig(
      accountNumber: '${json['seabank_account_number'] ?? ''}',
      accountName: '${json['seabank_account_name'] ?? ''}',
      bankLabel: '${json['bank_label'] ?? 'SeaBank Indonesia'}',
    );
  }
}

class PaymentProofPendingItem {
  const PaymentProofPendingItem({
    required this.proofId,
    required this.bookingId,
    required this.ownerName,
    required this.paymentAmount,
    required this.referenceCode,
    this.screenshotUrl,
    this.proofCreatedAt,
  });

  final String proofId;
  final String bookingId;
  final String ownerName;
  final int paymentAmount;
  final String referenceCode;
  final String? screenshotUrl;
  final String? proofCreatedAt;

  factory PaymentProofPendingItem.fromJson(Map<String, dynamic> json) {
    return PaymentProofPendingItem(
      proofId: '${json['proof_id'] ?? ''}',
      bookingId: '${json['booking_id'] ?? ''}',
      ownerName: '${json['owner_name'] ?? '—'}',
      paymentAmount: (json['payment_amount'] as num?)?.toInt() ?? 0,
      referenceCode: '${json['reference_code'] ?? ''}',
      screenshotUrl: json['screenshot_url'] as String?,
      proofCreatedAt: json['proof_created_at'] as String?,
    );
  }

  String? screenshotFullUrl() {
    final path = screenshotUrl;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${AppConfig.apiBaseUrl}$path';
  }
}

class PaymentV2Service {
  PaymentV2Service({http.Client? client}) : _client = client ?? http.Client();

  static final PaymentV2Service instance = PaymentV2Service();

  final http.Client _client;

  String get _baseUrl => '${AppConfig.apiBaseUrl}/payment_v2.php';

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthServiceV2.instance.getToken();
    if (token == null || token.isEmpty) {
      throw PaymentV2Exception('token_required', 'Silakan masuk terlebih dahulu.');
    }
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<PaymentBankConfig> fetchBankConfig() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl?action=get_payment_config'),
      headers: {'Accept': 'application/json'},
    );
    return _parse<PaymentBankConfig>(
      response,
      (body) => PaymentBankConfig.fromJson(body),
    );
  }

  Future<SubmitPaymentProofResult> submitPaymentProof({
    required String bookingId,
    required String referenceCode,
    String? screenshotBase64,
    String? screenshotMime,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl?action=submit_proof'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'booking_id': bookingId,
        'reference_code': referenceCode,
        'screenshot_base64': ?screenshotBase64,
        'screenshot_mime': ?screenshotMime,
      }),
    );
    return _parse(
      response,
      (body) => SubmitPaymentProofResult(
        bookingId: '${body['booking_id'] ?? bookingId}',
        status: '${body['status'] ?? 'PENDING_VERIFICATION'}',
        displayLabel: '${body['display_label'] ?? 'Menunggu Verifikasi'}',
      ),
    );
  }

  Future<List<PaymentProofPendingItem>> listPendingVerification() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl?action=list_pending_verification'),
      headers: await _authHeaders(),
    );
    final items = await _parse<List<PaymentProofPendingItem>>(
      response,
      (body) {
        final raw = body['items'];
        if (raw is! List) return <PaymentProofPendingItem>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(PaymentProofPendingItem.fromJson)
            .toList();
      },
    );
    return items;
  }

  Future<void> adminApprovePayment(String bookingId) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl?action=admin_approve_payment'),
      headers: await _authHeaders(),
      body: jsonEncode({'booking_id': bookingId}),
    );
    _parse<void>(response, (_) {});
  }

  Future<void> adminRejectPayment(String bookingId, {String? reason}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl?action=admin_reject_payment'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'booking_id': bookingId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      }),
    );
    _parse<void>(response, (_) {});
  }

  Future<T> _parse<T>(
    http.Response response,
    T Function(Map<String, dynamic> body) map,
  ) async {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw PaymentV2Exception('parse_error', 'Respons server tidak valid.');
    }
    if (response.statusCode >= 400 || body['ok'] != true) {
      final code = body['error'] as String? ?? 'failed';
      final msg = body['message'] as String? ?? 'Permintaan gagal.';
      throw PaymentV2Exception(code, msg);
    }
    return map(body);
  }
}

class SubmitPaymentProofResult {
  const SubmitPaymentProofResult({
    required this.bookingId,
    required this.status,
    required this.displayLabel,
  });

  final String bookingId;
  final String status;
  final String displayLabel;
}

class PaymentV2Exception implements Exception {
  PaymentV2Exception(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => message;
}
