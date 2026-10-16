import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/core/money/money.dart';
import 'package:sme_financial_copilot/core/money/money_format.dart';
import 'package:sme_financial_copilot/core/money/money_parser.dart';

void main() {
  group('parseAmount', () {
    test('parses USD into cents without floats', () {
      expect(parseAmount('12.5', Currency.usd).minor, 1250);
      expect(parseAmount('0.10', Currency.usd).minor, 10);
      expect(parseAmount('1,234.56', Currency.usd).minor, 123456);
      expect(parseAmount('50', Currency.usd).minor, 5000);
    });

    test('parses KHR as whole riel', () {
      expect(parseAmount('20000', Currency.khr).minor, 20000);
      expect(parseAmount('20,000', Currency.khr).minor, 20000);
    });

    test('accepts Khmer digits', () {
      expect(parseAmount('២០០០០', Currency.khr).minor, 20000);
      expect(parseAmount('៥០.២៥', Currency.usd).minor, 5025);
    });

    test('rejects bad input', () {
      expect(parseAmount('', Currency.usd).error, AmountError.empty);
      expect(parseAmount('abc', Currency.usd).error, AmountError.invalid);
      expect(parseAmount('-5', Currency.usd).error, AmountError.invalid);
      expect(parseAmount('1.234', Currency.usd).error, AmountError.tooManyDecimals);
      expect(parseAmount('100.5', Currency.khr).error, AmountError.tooManyDecimals);
      expect(parseAmount('0', Currency.usd).error, AmountError.notPositive);
      expect(parseAmount('0.00', Currency.usd).error, AmountError.notPositive);
      expect(parseAmount('9999999999999', Currency.khr).error, AmountError.tooLarge);
    });

    test('round-trips through the input string', () {
      expect(minorToInputString(1250, Currency.usd), '12.50');
      expect(minorToInputString(5, Currency.usd), '0.05');
      expect(minorToInputString(20000, Currency.khr), '20000');
    });
  });

  group('Money', () {
    test('adds within one currency', () {
      expect(
        const Money(100, Currency.usd) + const Money(250, Currency.usd),
        const Money(350, Currency.usd),
      );
    });

    test('refuses to mix KHR and USD', () {
      expect(
        () => const Money(100, Currency.usd) + const Money(4100, Currency.khr),
        throwsArgumentError,
      );
    });
  });

  group('formatMoney', () {
    test('formats USD and KHR', () {
      expect(formatMoney(const Money(123456, Currency.usd), locale: 'en'),
          r'$1,234.56');
      expect(formatMoney(const Money(20000, Currency.khr), locale: 'en'),
          '20,000 ៛');
    });

    test('shows signs', () {
      expect(formatMoney(const Money(-500, Currency.usd), locale: 'en'),
          r'-$5.00');
      expect(
        formatMoney(const Money(500, Currency.usd), locale: 'en', signed: true),
        r'+$5.00',
      );
      expect(
        formatMoney(const Money(0, Currency.usd), locale: 'en', signed: true),
        r'$0.00',
      );
    });
  });
}
