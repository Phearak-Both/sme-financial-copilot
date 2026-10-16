import 'package:intl/intl.dart';

import 'currency.dart';
import 'money.dart';

/// Formats [money] for display, e.g. `$1,250.00` or `20,000 ៛`.
///
/// Formatting works on the integer parts directly so no floating-point value
/// is ever created from a stored amount.
String formatMoney(Money money, {String? locale, bool signed = false}) {
  final currency = money.currency;
  final absMinor = money.minor.abs();

  var factor = 1;
  for (var i = 0; i < currency.exponent; i++) {
    factor *= 10;
  }
  final whole = absMinor ~/ factor;
  final grouped = NumberFormat.decimalPattern(locale).format(whole);
  final number = currency.exponent == 0
      ? grouped
      : '$grouped.${(absMinor % factor).toString().padLeft(currency.exponent, '0')}';

  final sign = money.isNegative
      ? '-'
      : (signed && money.minor > 0 ? '+' : '');

  return switch (currency) {
    Currency.usd => '$sign${currency.symbol}$number',
    Currency.khr => '$sign$number ${currency.symbol}',
  };
}
