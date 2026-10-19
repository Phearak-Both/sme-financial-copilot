import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/core/date_only.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/core/money/money.dart';
import 'package:sme_financial_copilot/domain/enums.dart';
import 'package:sme_financial_copilot/finance_core/ledger_math.dart';
import 'package:sme_financial_copilot/finance_core/sales.dart';

var _id = 0;

LedgerEntry _sale(
  int minor,
  String date,
  String description, {
  String category = 'sales',
  EntryType type = EntryType.income,
  Currency currency = Currency.usd,
  EntryStatus status = EntryStatus.active,
}) =>
    LedgerEntry(
      id: '${_id++}',
      type: type,
      amountMinor: minor,
      currency: currency,
      occurredOn: date,
      status: status,
      categoryId: category,
      description: description,
    );

Money usd(int minor) => Money(minor, Currency.usd);

void main() {
  final october = DateRange.monthOf(DateTime(2026, 10));
  final september = DateRange.monthOf(DateTime(2026, 9));

  test('groups income by description, highest first, with the change', () {
    final result = topSellers([
      // Matched despite case and spacing; named as last written.
      _sale(3000, '2026-10-02', ' rice  '),
      _sale(2000, '2026-10-03', 'Rice'),
      _sale(4000, '2026-10-04', 'Drinks'),
      _sale(1000, '2026-09-04', 'Rice'),
      _sale(9000, '2026-09-05', 'Drinks'),
    ], Currency.usd, october, september);

    expect(result.map((r) => r.name), ['Rice', 'Drinks']);
    expect(result.first.total, usd(5000));
    expect(result.first.count, 2);
    expect(result.first.previous, usd(1000));
    expect(result.last.previous, usd(9000));
  });

  test('skips expenses, voided entries, other currencies and blank names', () {
    final result = topSellers([
      _sale(3000, '2026-10-02', 'Rice'),
      _sale(5000, '2026-10-02', 'Rice', status: EntryStatus.voided),
      _sale(5000, '2026-10-02', 'Rice',
          type: EntryType.expense, category: 'stock'),
      _sale(500000, '2026-10-02', 'Rice', currency: Currency.khr),
      _sale(7000, '2026-10-02', '   '),
    ], Currency.usd, october, september);

    expect(result.single.total, usd(3000));
    expect(result.single.count, 1);
  });

  test('an item takes the category most of its income came from', () {
    final result = topSellers([
      _sale(1000, '2026-10-02', 'Rice', category: 'crop_sales'),
      _sale(4000, '2026-10-03', 'Rice'),
    ], Currency.usd, october, september);
    expect(result.single.categoryId, 'sales');
  });
}
