import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/core/date_only.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/core/money/money.dart';
import 'package:sme_financial_copilot/domain/enums.dart';
import 'package:sme_financial_copilot/finance_core/ledger_math.dart';

LedgerEntry _entry(
  EntryType type,
  int minor,
  Currency currency, {
  String date = '2026-10-10',
  EntryStatus status = EntryStatus.active,
  String? category,
}) =>
    LedgerEntry(
      id: '$type-$minor-$date',
      type: type,
      amountMinor: minor,
      currency: currency,
      occurredOn: date,
      status: status,
      categoryId: category,
    );

void main() {
  final october = DateRange.monthOf(DateTime(2026, 10, 16));

  final ledger = [
    _entry(EntryType.income, 50000, Currency.usd), // $500 sales
    _entry(EntryType.expense, 12000, Currency.usd, category: 'stock'),
    _entry(EntryType.expense, 3000, Currency.usd, category: 'transport'),
    _entry(EntryType.ownerWithdrawal, 10000, Currency.usd), // $100 personal
    _entry(EntryType.ownerContribution, 2000, Currency.usd),
    _entry(EntryType.income, 400000, Currency.khr), // 400,000 riel
    _entry(EntryType.expense, 80000, Currency.khr, category: 'farm_inputs'),
    // Excluded: voided, and outside the month.
    _entry(EntryType.expense, 99900, Currency.usd, status: EntryStatus.voided),
    _entry(EntryType.income, 77700, Currency.usd, date: '2026-09-30'),
    _entry(EntryType.income, 77700, Currency.usd, date: '2026-11-01'),
  ];

  test('summarises each currency separately', () {
    final summary = summarize(ledger, october);
    expect(summary.byCurrency.keys, [Currency.usd, Currency.khr]);

    final usd = summary.byCurrency[Currency.usd]!;
    expect(usd.income, const Money(50000, Currency.usd));
    expect(usd.expense, const Money(15000, Currency.usd));
    expect(usd.profit, const Money(35000, Currency.usd));
    // Cash: 500 + 20 - 150 - 100 = 270
    expect(usd.netCashFlow, const Money(27000, Currency.usd));
    expect(usd.entryCount, 5);

    final khr = summary.byCurrency[Currency.khr]!;
    expect(khr.profit, const Money(320000, Currency.khr));
    expect(khr.entryCount, 2);
    expect(summary.entryCount, 7);
  });

  test('owner withdrawals reduce cash but not profit', () {
    final summary = summarize([
      _entry(EntryType.income, 1000, Currency.usd),
      _entry(EntryType.ownerWithdrawal, 400, Currency.usd),
    ], october);
    final usd = summary.byCurrency[Currency.usd]!;
    expect(usd.profit, const Money(1000, Currency.usd));
    expect(usd.netCashFlow, const Money(600, Currency.usd));
  });

  test('empty period has no currencies', () {
    final summary = summarize(ledger, DateRange.monthOf(DateTime(2025, 1)));
    expect(summary.isEmpty, isTrue);
  });

  test('month ranges cover the whole month including year end', () {
    final december = DateRange.monthOf(DateTime(2026, 12, 5));
    expect(december.containsKey('2026-12-31'), isTrue);
    expect(december.containsKey('2027-01-01'), isFalse);
    final previous = DateRange.previousMonthOf(DateTime(2027, 1, 3));
    expect(previous.startKey, '2026-12-01');
    expect(previous.endKey, '2027-01-01');
  });

  test('expenses by category, largest first, per currency', () {
    final result = expensesByCategory(ledger, october);
    expect(result[Currency.usd]!.map((e) => e.key), ['stock', 'transport']);
    expect(result[Currency.usd]!.first.value, const Money(12000, Currency.usd));
    expect(result[Currency.khr]!.single.key, 'farm_inputs');
  });
}
