import 'currency.dart';

/// An amount of money in a single currency, held as integer minor units.
///
/// Arithmetic between different currencies is a programming error and throws:
/// KHR and USD must never be added together without an explicit exchange rate.
class Money implements Comparable<Money> {
  const Money(this.minor, this.currency);

  const Money.zero(this.currency) : minor = 0;

  final int minor;
  final Currency currency;

  bool get isZero => minor == 0;
  bool get isNegative => minor < 0;

  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money(minor + other.minor, currency);
  }

  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money(minor - other.minor, currency);
  }

  Money operator -() => Money(-minor, currency);

  @override
  int compareTo(Money other) {
    _requireSameCurrency(other);
    return minor.compareTo(other.minor);
  }

  void _requireSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Cannot combine ${currency.code} with ${other.currency.code} '
        'without an exchange rate.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => 'Money($minor ${currency.code})';
}
