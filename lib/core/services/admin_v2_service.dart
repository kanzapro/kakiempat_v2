import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/models/launch_metrics_v2.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';

class AdminV2Service {
  AdminV2Service({V2ApiClient? client}) : _api = client ?? V2ApiClient.instance;

  static final AdminV2Service instance = AdminV2Service();

  final V2ApiClient _api;
  static const _script = 'admin_v2.php';

  Future<List<AdminOwnerV2>> listOwners() async {
    final response = await _api.getAuth(_script, action: 'list_owners');
    return _api.parse(
      response,
      (body) {
        final raw = body['owners'];
        if (raw is! List) return <AdminOwnerV2>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(AdminOwnerV2.fromJson)
            .toList();
      },
    );
  }

  Future<int> countSitters() async {
    final response = await _api.getAuth(_script, action: 'list_sitters');
    return _api.parse(
      response,
      (body) => (body['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<PendingSitterV2>> listPendingSitters() async {
    final response =
        await _api.getAuth(_script, action: 'list_pending_sitters');
    return _api.parse(
      response,
      (body) {
        final raw = body['sitters'];
        if (raw is! List) return <PendingSitterV2>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(PendingSitterV2.fromJson)
            .toList();
      },
    );
  }

  Future<void> approveSitter(String userId) async {
    final response = await _api.postAuth(
      _script,
      action: 'approve_sitter',
      body: {'user_id': userId},
    );
    await _api.parse<void>(response, (_) {});
  }

  Future<void> rejectSitter(String userId) async {
    final response = await _api.postAuth(
      _script,
      action: 'reject_sitter',
      body: {'user_id': userId},
    );
    await _api.parse<void>(response, (_) {});
  }

  Future<List<AdminBookingV2>> listBookings({String? status}) async {
    final response = await _api.getAuth(
      _script,
      action: 'list_bookings',
      query: {if (status != null && status.isNotEmpty) 'status': status},
    );
    return _api.parse(
      response,
      (body) {
        final raw = body['bookings'];
        if (raw is! List) return <AdminBookingV2>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(AdminBookingV2.fromJson)
            .toList();
      },
    );
  }

  Future<List<AdminWithdrawalV2>> listPendingWithdrawals() async {
    final response =
        await _api.getAuth(_script, action: 'list_pending_withdrawals');
    return _api.parse(
      response,
      (body) {
        final raw = body['withdrawals'];
        if (raw is! List) return <AdminWithdrawalV2>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(AdminWithdrawalV2.fromJson)
            .toList();
      },
    );
  }

  Future<void> approveWithdrawal(String withdrawalId) async {
    final response = await _api.postAuth(
      _script,
      action: 'approve_withdrawal',
      body: {'withdrawal_id': withdrawalId},
    );
    await _api.parse<void>(response, (_) {});
  }

  Future<void> rejectWithdrawal(String withdrawalId) async {
    final response = await _api.postAuth(
      _script,
      action: 'reject_withdrawal',
      body: {'withdrawal_id': withdrawalId},
    );
    await _api.parse<void>(response, (_) {});
  }

  Future<LaunchMetricsV2> getLaunchMetrics() async {
    final response =
        await _api.getAuth(_script, action: 'get_launch_metrics');
    return _api.parse(response, LaunchMetricsV2.fromJson);
  }
}

class AdminOwnerV2 {
  const AdminOwnerV2({
    required this.userId,
    required this.name,
    required this.phone,
    required this.isActive,
    this.address = '',
    this.createdAt = '',
  });

  final String userId;
  final String name;
  final String phone;
  final bool isActive;
  final String address;
  final String createdAt;

  factory AdminOwnerV2.fromJson(Map<String, dynamic> json) {
    return AdminOwnerV2(
      userId: '${json['user_id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      isActive: json['is_active'] == true,
      address: '${json['address'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
    );
  }
}

class AdminBookingV2 {
  const AdminBookingV2({
    required this.id,
    required this.status,
    this.ownerName = '',
    this.sitterName = '',
    this.totalPrice = 0,
    this.paymentAmount = 0,
    this.createdAt = '',
  });

  final String id;
  final String status;
  final String ownerName;
  final String sitterName;
  final int totalPrice;
  final int paymentAmount;
  final String createdAt;

  factory AdminBookingV2.fromJson(Map<String, dynamic> json) {
    return AdminBookingV2(
      id: '${json['id'] ?? ''}',
      status: '${json['status'] ?? ''}',
      ownerName: '${json['owner_name'] ?? ''}',
      sitterName: '${json['sitter_name'] ?? ''}',
      totalPrice: (json['total_price'] as num?)?.toInt() ?? 0,
      paymentAmount: (json['payment_amount'] as num?)?.toInt() ?? 0,
      createdAt: '${json['created_at'] ?? ''}',
    );
  }
}

class AdminWithdrawalV2 {
  const AdminWithdrawalV2({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    this.userName = '',
    this.phone = '',
    this.createdAt = '',
  });

  final String id;
  final String userId;
  final int amount;
  final String status;
  final String userName;
  final String phone;
  final String createdAt;

  factory AdminWithdrawalV2.fromJson(Map<String, dynamic> json) {
    return AdminWithdrawalV2(
      id: '${json['id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: '${json['status'] ?? ''}',
      userName: '${json['user_name'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
    );
  }
}
