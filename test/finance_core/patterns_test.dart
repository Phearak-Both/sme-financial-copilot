import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/core/money/money.dart';
import 'package:sme_financial_copilot/domain/enums.dart';
import 'package:sme_financial_copilot/finance_core/ledger_math.dart';
import 'package:sme_financial_copilot/finance_core/patterns.dart';

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

LedgerEntry _rent(String date, [int minor = 15000]) => _entry(
    EntryType.expense, minor, date, category: 'rent', description: 'Shop rent');

void main() {
  final today = DateTime(2026, 10, 16);

  group('detectRecurring', () {
    test('finds a monthly bill and when it is next due', () {
      final result = detectRecurring([
        _rent('2026-07-01'),
        _rent('2026-08-02'),
        _rent('2026-09-01'),
      ], Currency.usd, today);
      expect(result, hasLength(1));
      expect(result.single.typical, usd(15000));
      expect(result.single.dayOfMonth, 1);
      expect(result.single.paidThisMonth, isFalse);
      // Not paid in October yet, so it looks overdue.
      expect(result.single.nextDue, DateTime(2026, 10, 1));
      expect(result.single.daysUntil(today), -15);
    });

    test('once paid this month, the next one is next month', () {
      final result = detectRecurring([
        _rent('2026-08-01'),
        _rent('2026-09-01'),
        _rent('2026-10-01'),
      ], Currency.usd, today);
      expect(result.single.paidThisMonth, isTrue);
      expect(result.single.nextDue, DateTime(2026, 11, 1));
    });

    test('ignores weekly costs, changing amounts and too little history', () {
      final weekly = [
        for (final d in ['07-06', '07-13', '08-03', '08-10', '09-07'])
          _entry(EntryType.expense, 15000, '2026-$d',
              category: 'stock', description: 'Restock'),
      ];
      final varying = [
        _entry(EntryType.expense, 1000, '2026-07-05',
            category: 'repairs', description: 'Fix'),
        _entry(EntryType.expense, 5000, '2026-08-05',
            category: 'repairs', description: 'Fix'),
        _entry(EntryType.expense, 1000, '2026-09-05',
            category: 'repairs', description: 'Fix'),
      ];
      final twoMonths = [_rent('2026-08-01'), _rent('2026-09-01')];
      expect(
        detectRecurring([...weekly, ...varying, ...twoMonths], Currency.usd, today),
        isEmpty,
      );
    });

    test('clamps the due day to short months', () {
      final result = detectRecurring([
        for (final m in ['05', '07', '08', '10']) _rent('2026-$m-31'),
      ], Currency.usd, DateTime(2026, 10, 31));
      expect(result.single.nextDue, DateTime(2026, 11, 30));
    });
  });

  group('compareWithUsual', () {
    LedgerEntry fuel(String date, int minor) => _entry(
        EntryType.expense, minor, date,
        category: 'transport', description: 'Fuel');

    test('compares the same days of the last 3 months', () {
      final result = compareWithUsual([
        fuel('2026-07-10', 1000),
        fuel('2026-08-10', 1000),
        fuel('2026-09-10', 1000),
        // After the 16th, so not part of the usual level.
        fuel('2026-09-25', 9000),
        fuel('2026-10-10', 1400),
      ], Currency.usd, today);
      final row = result.single;
      expect(row.current, usd(1400));
      expect(row.usual, usd(1000));
      expect(row.percent, 40);
      expect(row.isAlert(usd(1000)), isTrue);
    });

    test('leaves out regular payments and small jumps', () {
      final entries = [
        for (final m in ['07', '08', '09']) ...[
          _rent('2026-$m-01'),
          fuel('2026-$m-10', 1000),
          _entry(EntryType.expense, 100000, '2026-$m-05', category: 'stock'),
        ],
        _rent('2026-10-01', 18000),
        fuel('2026-10-10', 1400),
        _entry(EntryType.expense, 100000, '2026-10-05', category: 'stock'),
      ];
      final result = compareWithUsual(entries, Currency.usd, today,
          recurringKeys: {'rent|shop rent'});
      expect(result.map((r) => r.categoryId), isNot(contains('rent')));
      final total = usd(result.fold(0, (s, r) => s + r.usual.minor));
      // Fuel rose 40%, but $4 is tiny next to $1,000 of stock.
      expect(result.any((r) => r.isAlert(total)), isFalse);
    });

    test('is empty without earlier months', () {
      expect(compareWithUsual([fuel('2026-10-10', 1400)], Currency.usd, today),
          isEmpty);
    });
  });

  test('seasonality names the busiest and quietest months', () {
    final entries = [
      for (var year = 2024; year <= 2026; year++)
        for (var m = 1; m <= 12; m++)
          _entry(
            EntryType.income,
            switch (m) { 11 || 12 => 90000, 4 || 5 => 10000, _ => 40000 + m },
            '$year-${m.toString().padLeft(2, '0')}-15',
            category: 'sales',
          ),
    ];
    final result = seasonality(entries, Currency.usd, today)!;
    expect(result.years.keys, [2024, 2025, 2026]);
    expect(result.years[2026]![8], usd(40009));
    // October is still in progress.
    expect(result.years[2026]![9], isNull);
    expect(result.peakMonths, [11, 12]);
    expect(result.lowMonths, [4, 5]);

    // Months before the first record are gaps, not zero.
    final short = seasonality(entries.skip(30), Currency.usd, today)!;
    expect(short.years.keys, [2026]);
    expect(short.years[2026]![5], isNull);
    expect(short.years[2026]![6], usd(40007));
  });

  test('seasonality waits for a full year before naming months', () {
    final result = seasonality([
      _entry(EntryType.income, 1000, '2026-03-01', category: 'sales'),
    ], Currency.usd, today)!;
    expect(result.years[2026]![1], isNull);
    expect(result.peakMonths, isEmpty);
  });

  test('seasonality has nothing to show until a month with income is over',
      () {
    // A new account whose only income is this month, still in progress.
    expect(
      seasonality([
        _entry(EntryType.income, 1000, '2026-10-02', category: 'sales'),
      ], Currency.usd, today),
      isNull,
    );
  });

  test('weekday income averages over 12 weeks and compares best to worst', () {
    final entries = [
      for (var d = 0; d < 84; d++)
        () {
          final date = DateTime(2026, 10, 16 - d);
          final amount = date.weekday == DateTime.saturday
              ? 2100
              : date.weekday == DateTime.tuesday
                  ? 1000
                  : 1500;
          return _entry(EntryType.income, amount,
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              category: 'sales');
        }(),
    ];
    final result = weekdayIncome(entries, Currency.usd, today)!;
    expect(result.best, DateTime.saturday);
    expect(result.worst, DateTime.tuesday);
    expect(result.averages[DateTime.saturday - 1], usd(2100));
    expect(result.ratioTenths, 21);
  });

  test('profit vs withdrawals flags months where more was taken out', () {
    final result = profitVsWithdrawals([
      _entry(EntryType.income, 50000, '2026-09-03', category: 'sales'),
      _entry(EntryType.ownerWithdrawal, 10000, '2026-09-20'),
      _entry(EntryType.income, 20000, '2026-10-03', category: 'sales'),
      _entry(EntryType.ownerWithdrawal, 30000, '2026-10-05'),
    ], Currency.usd, today);
    expect(result, hasLength(6));
    expect(result.first.month.start, DateTime(2026, 5));
    expect(result[4].overdrawn, isFalse);
    expect(result.last.profit, usd(20000));
    expect(result.last.withdrawn, usd(30000));
    expect(result.last.overdrawn, isTrue);
  });
}
