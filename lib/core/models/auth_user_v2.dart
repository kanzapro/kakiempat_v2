class AuthUserV2 {
  const AuthUserV2({
    required this.id,
    required this.phone,
    required this.role,
    required this.name,
    this.roles = const [],
  });

  final int id;
  final String phone;
  final String role;
  final String name;
  final List<String> roles;

  List<String> get effectiveRoles =>
      roles.isNotEmpty ? roles : (role.isEmpty ? const [] : [role]);

  bool get isFounder =>
      role == 'founder' || effectiveRoles.contains('founder');
  bool get isAdmin =>
      role == 'admin' || isFounder || effectiveRoles.contains('admin');
  bool get isOwner =>
      role == 'owner' || effectiveRoles.contains('owner');
  bool get isSitter =>
      role == 'sitter' || effectiveRoles.contains('sitter');

  factory AuthUserV2.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    final parsedRoles = rawRoles is List
        ? rawRoles.map((e) => '$e').where((r) => r.isNotEmpty).toList()
        : const <String>[];

    return AuthUserV2(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'owner',
      name: json['name'] as String? ?? '',
      roles: parsedRoles,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'role': role,
        'roles': effectiveRoles,
        'name': name,
      };
}
