import 'currency.dart';

/// Largest amount accepted from user input, in major units (e.g. dollars).
/// Guards against typos such as an extra row of zeros.
const int maxMajorAmount = 999999999999;

const _khmerDigits = '០១២៣៤៥៦៧៨៩';

/// Replaces Khmer digits (០–៩) with ASCII digits.
String normalizeDigits(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final index = _khmerDigits.indexOf(char);
    buffer.write(index >= 0 ? index.toString() : char);
  }
  return buffer.toString();
}

/// Why an amount could not be parsed.
enum AmountError { empty, invalid, tooManyDecimals, notPositive, tooLarge }

class AmountParseResult {
  const AmountParseResult.ok(this.minor) : error = null;
  const AmountParseResult.fail(this.error) : minor = null;

  final int? minor;
  final AmountError? error;

  bool get isOk => minor != null;
}

/// Parses a user-typed amount into integer minor units without using floats.
///
/// Accepts Khmer or ASCII digits, thousands separators (`,`, space, `_`) and
/// at most [Currency.exponent] decimal places. The amount must be positive.
AmountParseResult parseAmount(String input, Currency currency) {
  final cleaned = normalizeDigits(input).replaceAll(RegExp(r'[,\s_]'), '');
  if (cleaned.isEmpty) return const AmountParseResult.fail(AmountError.empty);

  final match = RegExp(r'^(\d+)(?:\.(\d*))?$').firstMatch(cleaned);
  if (match == null) return const AmountParseResult.fail(AmountError.invalid);

  final whole = match.group(1)!;
  final fraction = match.group(2) ?? '';
  if (fraction.length > currency.exponent) {
    return const AmountParseResult.fail(AmountError.tooManyDecimals);
  }

  final wholeValue = int.tryParse(whole);
  if (wholeValue == null || wholeValue > maxMajorAmount) {
    return const AmountParseResult.fail(AmountError.tooLarge);
  }

  final paddedFraction = fraction.padRight(currency.exponent, '0');
  final minor = wholeValue * _pow10(currency.exponent) +
      (paddedFraction.isEmpty ? 0 : int.parse(paddedFraction));

  if (minor <= 0) return const AmountParseResult.fail(AmountError.notPositive);
  return AmountParseResult.ok(minor);
}

/// Converts minor units back into the plain string shown in an input field,
/// e.g. 1250 USD -> "12.50", 20000 KHR -> "20000".
String minorToInputString(int minor, Currency currency) {
  if (currency.exponent == 0) return minor.toString();
  final factor = _pow10(currency.exponent);
  final whole = minor ~/ factor;
  final fraction = (minor % factor).toString().padLeft(currency.exponent, '0');
  return '$whole.$fraction';
}

int _pow10(int exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}
