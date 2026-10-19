import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/core/date_only.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/core/money/money.dart';
import 'package:sme_financial_copilot/domain/enums.dart';
import 'package:sme_financial_copilot/finance_core/ledger_math.dart';
import 'package:sme_financial_copilot/finance_core/period_math.dart';
import 'package:sme_financial_copilot/finance_core/reports.dart';

var _id = 0;

LedgerEntry _entry(
  EntryType type,
  int minor,
  String date, {
  String? category,
  String description = '',
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
  final today = DateTime(2026, 10, 16);

  group('ranges', () {
    test('the previous range matches whole months or days', () {
      final quarter = DateRange(DateTime(2026, 8), DateTime(2026, 11));
      final before = previousRange(quarter);
      expect([before.startKey, before.endKey], ['2026-05-01', '2026-08-01']);

      final days = DateRange(DateTime(2026, 10, 5), DateTime(2026, 10, 15));
      final daysBefore = previousRange(days);
      expect([daysBefore.startKey, daysBefore.endKey],
          ['2026-09-25', '2026-10-05']);
    });

    test('months are cut to fit the range', () {
      final months =
          monthsIn(DateRange(DateTime(2026, 9, 20), DateTime(2026, 11, 3)));
      expect(months.map((m) => '${m.startKey}..${m.endKey}'), [
        '2026-09-20..2026-10-01',
        '2026-10-01..2026-11-01',
        '2026-11-01..2026-11-03',
      ]);
    });
  });

  test('income statement lines up categories against the period before', () {
    final s = buildIncomeStatement([
      _entry(EntryType.income, 50000, '2026-09-03', category: 'sales'),
      _entry(EntryType.income, 8000, '2026-09-09', category: 'services'),
      _entry(EntryType.expense, 20000, '2026-09-04', category: 'stock'),
      _entry(EntryType.income, 40000, '2026-08-03', category: 'sales'),
      _entry(EntryType.expense, 5000, '2026-08-10', category: 'rent'),
      _entry(EntryType.ownerWithdrawal, 9000, '2026-09-20'),
      _entry(EntryType.expense, 99999, '2026-09-21',
          category: 'stock', status: EntryStatus.voided),
      _entry(EntryType.income, 700000, '2026-09-03',
          category: 'sales', currency: Currency.khr),
    ], Currency.usd, DateRange.monthOf(DateTime(2026, 9)));

    expect(s.comparison.startKey, '2026-08-01');
    expect(s.income.map((l) => l.categoryId), ['sales', 'services']);
    expect(s.income.first.previous, usd(40000));
    // Rent was only paid before; it still shows, at zero now.
    expect(s.expenses.map((l) => l.categoryId), ['stock', 'rent']);
    expect(s.expenses.last.current, usd(0));
    expect(s.current.profit, usd(38000));
    expect(s.previous.profit, usd(35000));
    expect(s.marginPercent, 66);
    expect(s.current.ownerWithdrawal, usd(9000));
  });

  group('cash flow', () {
    final entries = [
      _entry(EntryType.income, 10000, '2026-08-10', category: 'sales'),
      _entry(EntryType.expense, 3000, '2026-09-02', category: 'rent'),
      _entry(EntryType.income, 6000, '2026-09-15', category: 'sales'),
      _entry(EntryType.ownerContribution, 2000, '2026-10-01'),
      _entry(EntryType.ownerWithdrawal, 1000, '2026-10-05'),
    ];
    final range = DateRange(DateTime(2026, 9), DateTime(2026, 11));

    test('runs from opening cash to closing cash, month by month', () {
      final r = buildCashFlow(entries, Currency.usd, range,
          opening: const OpeningBalance(
              currency: Currency.usd, amountMinor: 5000, asOf: '2026-08-01'));
      expect(r.opening, usd(15000));
      expect(r.cashIn, usd(8000));
      expect(r.cashOut, usd(4000));
      expect(r.months.map((m) => m.net), [usd(3000), usd(1000)]);
      expect(r.months.map((m) => m.closing), [usd(18000), usd(19000)]);
      expect(r.closing, usd(19000));
    });

    test('opening is unknown when the opening cash is dated later', () {
      final r = buildCashFlow(entries, Currency.usd, range,
          opening: const OpeningBalance(
              currency: Currency.usd, amountMinor: 5000, asOf: '2026-10-15'));
      expect(r.opening, isNull);
      expect(r.months.first.closing, isNull);
      // Only entries from the opening cash date on count.
      expect(r.closing, usd(5000));
    });

    test('opening cash on the first day is the cash before that day', () {
      final r = buildCashFlow(entries, Currency.usd, range,
          opening: const OpeningBalance(
              currency: Currency.usd, amountMinor: 5000, asOf: '2026-10-01'));
      expect(r.opening, isNull);
      expect(r.months.map((m) => m.closing), [usd(5000), usd(6000)]);
    });

    test('nothing is known without opening cash', () {
      final r = buildCashFlow(entries, Currency.usd, range);
      expect(r.opening, isNull);
      expect(r.closing, isNull);
      expect(r.cashIn - r.cashOut, usd(4000));
    });
  });

  test('loan summary averages finished months only', () {
    final entries = [
      for (final m in ['06', '07', '08', '09']) ...[
        _entry(EntryType.income, 100000, '2026-$m-10', category: 'sales'),
        _entry(EntryType.expense, 60000, '2026-$m-12', category: 'stock'),
        _entry(EntryType.expense, 15000, '2026-$m-01',
            category: 'rent', description: 'Shop rent'),
        _entry(EntryType.ownerWithdrawal, 10000, '2026-$m-20'),
      ],
      // A bad month.
      _entry(EntryType.expense, 50000, '2026-07-25', category: 'repairs'),
      // October is still in progress and only has a little income so far.
      _entry(EntryType.income, 1000, '2026-10-02', category: 'services'),
      _entry(EntryType.expense, 15000, '2026-10-01',
          category: 'rent', description: 'Shop rent'),
    ];
    final s = buildLoanSummary(
      entries,
      Currency.usd,
      DateRange(DateTime(2026, 6), DateTime(2026, 11)),
      today: today,
      opening: const OpeningBalance(
          currency: Currency.usd, amountMinor: 20000, asOf: '2026-06-01'),
    );

    expect(s.months, hasLength(5));
    expect(s.averagedMonths, 4);
    expect(s.averageIncome, usd(100000));
    expect(s.averageExpenses, usd(87500));
    expect(s.averageProfit, usd(12500));
    expect(s.averageWithdrawals, usd(10000));
    expect(s.averageSurplus, usd(2500));
    expect(s.profitableMonths, 3);
    expect(s.incomeSources.map((e) => e.key), ['sales', 'services']);
    expect(s.commitments.single.description, 'Shop rent');
    expect(s.firstRecord, '2026-06-01');
    // 20,000 + 4 × (100,000 − 75,000 − 10,000) − 50,000 + 1,000 − 15,000.
    expect(s.cash, usd(16000));
    // Only October's rent was spent in the last 30 days: 16,000 × 30 / 15,000.
    expect(s.runwayDays, 32);
  });
}
