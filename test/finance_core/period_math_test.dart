import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/core/money/money.dart';
import 'package:sme_financial_copilot/domain/enums.dart';
import 'package:sme_financial_copilot/finance_core/ledger_math.dart';
import 'package:sme_financial_copilot/finance_core/period_math.dart';

LedgerEntry _entry(
  EntryType type,
  int minor,
  String date, {
  Currency currency = Currency.usd,
  EntryStatus status = EntryStatus.active,
}) =>
    LedgerEntry(
      id: '$type-$minor-$date',
      type: type,
      amountMinor: minor,
      currency: currency,
      occurredOn: date,
      status: status,
    );

void main() {
  final today = DateTime(2026, 10, 16);

  group('ranges', () {
    test('period ranges', () {
      expect(rangeFor(ReportPeriod.thisMonth, today).startKey, '2026-10-01');
      expect(rangeFor(ReportPeriod.lastMonth, today).startKey, '2026-09-01');
      final q = rangeFor(ReportPeriod.last3Months, today);
      expect([q.startKey, q.endKey], ['2026-08-01', '2026-11-01']);
      final y = rangeFor(ReportPeriod.thisYear, today);
      expect([y.startKey, y.endKey], ['2026-01-01', '2027-01-01']);
    });

    test('in-progress month compares with the same elapsed days', () {
      final c = comparisonRangeFor(ReportPeriod.thisMonth, today);
      // Oct 1–16 (16 days) vs Sep 1–16.
      expect([c.startKey, c.endKey], ['2026-09-01', '2026-09-17']);
    });

    test('a finished month compares with the whole previous month', () {
      final c = comparisonRangeFor(ReportPeriod.lastMonth, today);
      expect([c.startKey, c.endKey], ['2026-08-01', '2026-09-01']);
    });

    test('comparison is capped at the previous period end', () {
      // Mar 31 elapsed = 31 days, but February only has 28.
      final c = comparisonRangeFor(ReportPeriod.thisMonth, DateTime(2026, 3, 31));
      expect([c.startKey, c.endKey], ['2026-02-01', '2026-03-01']);
    });

    test('year to date compares with the same days last year', () {
      final c = comparisonRangeFor(ReportPeriod.thisYear, today);
      expect(c.startKey, '2025-01-01');
      expect(c.endKey, '2025-10-17');
    });
  });

  group('percentChange', () {
    Money usd(int v) => Money(v, Currency.usd);

    test('rounds to whole percent', () {
      expect(percentChange(usd(150), usd(100)), 50);
      expect(percentChange(usd(50), usd(100)), -50);
      expect(percentChange(usd(1005), usd(1000)), 1); // 0.5% rounds up
      expect(percentChange(usd(100), usd(300)), -67);
    });

    test('null when there is nothing to compare with', () {
      expect(percentChange(usd(100), usd(0)), isNull);
    });
  });

  test('monthly trend includes empty months and one currency only', () {
    final trend = monthlyTrend(
      [
        _entry(EntryType.income, 1000, '2026-10-02'),
        _entry(EntryType.expense, 400, '2026-10-05'),
        _entry(EntryType.income, 700, '2026-08-20'),
        _entry(EntryType.income, 999999, '2026-10-02', currency: Currency.khr),
        _entry(EntryType.expense, 50, '2026-10-03', status: EntryStatus.voided),
      ],
      Currency.usd,
      lastMonth: today,
      months: 3,
    );
    expect(trend.map((m) => m.month.month), [8, 9, 10]);
    expect(trend.map((m) => m.income.minor), [700, 0, 1000]);
    expect(trend.map((m) => m.expense.minor), [0, 0, 400]);
  });

  test('cash balance starts from the opening date', () {
    final balances = cashBalances(
      [
        const OpeningBalance(
            currency: Currency.usd, amountMinor: 10000, asOf: '2026-10-01'),
      ],
      [
        _entry(EntryType.income, 5000, '2026-09-30'), // before opening: ignored
        _entry(EntryType.income, 3000, '2026-10-01'),
        _entry(EntryType.expense, 2000, '2026-10-02'),
        _entry(EntryType.ownerWithdrawal, 1500, '2026-10-03'),
        _entry(EntryType.ownerContribution, 500, '2026-10-04'),
        _entry(EntryType.expense, 9999, '2026-10-05', status: EntryStatus.voided),
        _entry(EntryType.income, 400000, '2026-10-05', currency: Currency.khr),
      ],
    );
    // 100 + 30 - 20 - 15 + 5 = 100.00
    expect(balances, {Currency.usd: const Money(10000, Currency.usd)});
  });

  test('no opening balance means no balance', () {
    expect(cashBalances([], [_entry(EntryType.income, 1, '2026-10-01')]), isEmpty);
  });
}
