import 'package:flutter_test/flutter_test.dart';
import 'package:kaki_empat/core/models/auth_user_v2.dart';

void main() {
  test('effectiveRoles falls back to primary role', () {
    const user = AuthUserV2(
      id: 1,
      phone: '6281234567890',
      role: 'owner',
      name: 'Budi',
    );
    expect(user.effectiveRoles, ['owner']);
    expect(user.isOwner, isTrue);
    expect(user.isSitter, isFalse);
  });

  test('multi-role user can access owner and sitter', () {
    const user = AuthUserV2(
      id: 2,
      phone: '6281234567891',
      role: 'owner',
      name: 'Ani',
      roles: ['owner', 'sitter'],
    );
    expect(user.isOwner, isTrue);
    expect(user.isSitter, isTrue);
  });

  test('fromJson parses roles array', () {
    final user = AuthUserV2.fromJson({
      'id': 3,
      'phone': '6281234567892',
      'role': 'sitter',
      'roles': ['sitter'],
      'name': 'Cici',
    });
    expect(user.effectiveRoles, ['sitter']);
    expect(user.isSitter, isTrue);
  });
}
