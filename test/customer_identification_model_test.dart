import 'package:appcaixaauto/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta qrPayload, expiresAt e serverTime do backend', () {
    final token = CustomerIdentificationToken.fromJson(const {
      'qrPayload': 'app247://customer-link/opaque-value',
      'expiresAt': '2026-09-30T13:02:00Z',
      'serverTime': '2026-09-30T13:00:00Z',
    });

    expect(token.qrPayload, 'app247://customer-link/opaque-value');
    expect(token.expiresAt, DateTime.parse('2026-09-30T13:02:00Z'));
    expect(token.serverTime, DateTime.parse('2026-09-30T13:00:00Z'));
  });

  test('rejeita resposta sem payload ou datas válidas', () {
    expect(
      () => CustomerIdentificationToken.fromJson(const {
        'qrPayload': '',
        'expiresAt': 'invalid',
      }),
      throwsFormatException,
    );
  });
}
