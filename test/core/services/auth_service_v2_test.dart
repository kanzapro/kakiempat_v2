import 'package:flutter_test/flutter_test.dart';
import 'package:kaki_empat/core/services/auth_service_v2.dart';

void main() {
  test('normalizePhone', () {
    expect(AuthServiceV2.normalizePhone('081234567890'), '6281234567890');
  });
  test('isValidPassword', () {
    expect(AuthServiceV2.isValidPassword('abcdef'), isTrue);
    expect(AuthServiceV2.isValidPassword('abc'), isFalse);
  });
}
