import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/cloud/auth.dart';

void main() {
  test('local and international forms normalize to the same number', () {
    for (final input in [
      '012 345 678',
      '012-345-678',
      '12345678',
      '+855 12 345 678',
      '+855 012 345 678',
      '855 12 345 678',
      '0085512345678',
    ]) {
      expect(normalizePhone(input), '85512345678', reason: input);
    }
    expect(normalizePhone('097 123 4567'), '855971234567');
    expect(normalizePhone('+66 81 234 5678'), '66812345678');
  });

  test('rejects things that are not phone numbers', () {
    for (final input in ['', 'abc', '012 34', '+855', '12-34-56', '0123456789012']) {
      expect(normalizePhone(input), isNull, reason: input);
    }
  });

  test('login address and display', () {
    expect(phoneLoginEmail('85512345678'), 'phone-85512345678@example.com');
    expect(formatPhone('85512345678'), '+855 12 345 678');
    expect(formatPhone('855971234567'), '+855 97 123 4567');
    expect(formatPhone('66812345678'), '+66812345678');
  });
}
