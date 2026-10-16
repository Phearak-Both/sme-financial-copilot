/// Currencies supported by the ledger.
///
/// Amounts are always stored as integer minor units. [exponent] is the number
/// of decimal places a minor unit represents (USD cents = 2, KHR riel = 0).
enum Currency {
  usd(code: 'USD', exponent: 2, symbol: r'$'),
  khr(code: 'KHR', exponent: 0, symbol: '៛');

  const Currency({
    required this.code,
    required this.exponent,
    required this.symbol,
  });

  final String code;
  final int exponent;
  final String symbol;

  static Currency fromCode(String code) =>
      Currency.values.firstWhere((c) => c.code == code);
}
