import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/core/money/money.dart';
import 'package:sme_financial_copilot/domain/enums.dart';
import 'package:sme_financial_copilot/finance_core/insights.dart';
import 'package:sme_financial_copilot/finance_core/ledger_math.dart';
import 'package:sme_financial_copilot/finance_core/period_math.dart';

var _id = 0;

LedgerEntry _entry(
  EntryType type,
  int minor,
  String date, {
  String? category,
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
    );

Money usd(int minor) => Money(minor, Currency.usd);

void main() {
  final today = DateTime(2026, 10, 16);
  final range = rangeFor(ReportPeriod.thisMonth, today);
  final comparison = comparisonRangeFor(ReportPeriod.thisMonth, today);

  List<Insight> insights(List<LedgerEntry> entries, {Money? cash}) =>
      buildInsights(
        entries: entries,
        currency: Currency.usd,
        range: range,
        comparison: comparison,
        today: today,
        cash: cash,
      );

  T only<T extends Insight>(List<Insight> list) =>
      list.whereType<T>().single;

  test('margin is profit as a share of income', () {
    final result = insights([
      _entry(EntryType.income, 10000, '2026-10-02', category: 'sales'),
      _entry(EntryType.expense, 7500, '2026-10-03', category: 'stock'),
    ]);
    expect(only<MarginInsight>(result).percent, 25);
    expect(only<MarginInsight>(result).tone, InsightTone.good);
    expect(result.whereType<LossInsight>(), isEmpty);
  });

  test('a loss replaces the margin', () {
    final result = insights([
      _entry(EntryType.income, 5000, '2026-10-02'),
      _entry(EntryType.expense, 8000, '2026-10-03'),
    ]);
    expect(only<LossInsight>(result).loss, usd(3000));
    expect(result.whereType<MarginInsight>(), isEmpty);
  });

  test('withdrawals beyond profit are flagged', () {
    final result = insights([
      _entry(EntryType.income, 10000, '2026-10-02'),
      _entry(EntryType.expense, 8000, '2026-10-03'),
      _entry(EntryType.ownerWithdrawal, 5000, '2026-10-04'),
    ]);
    final w = only<WithdrawalInsight>(result);
    expect(w.withdrawn, usd(5000));
    expect(w.profit, usd(2000));

    final fine = insights([
      _entry(EntryType.income, 10000, '2026-10-02'),
      _entry(EntryType.ownerWithdrawal, 5000, '2026-10-04'),
    ]);
    expect(fine.whereType<WithdrawalInsight>(), isEmpty);
  });

  test('runway uses the last 30 days of spending', () {
    final entries = [
      _entry(EntryType.income, 1000, '2026-10-02'),
      // 30 days up to today: Sep 17 - Oct 16. Sep 10 is outside.
      _entry(EntryType.expense, 30000, '2026-09-20'),
      _entry(EntryType.expense, 99999, '2026-09-10'),
    ];
    // $300 over 30 days = $10 a day; $200 lasts 20 days.
    final r = only<RunwayInsight>(insights(entries, cash: usd(20000)));
    expect(r.days, 20);
    expect(r.tone, InsightTone.warning);
    expect(
      only<RunwayStatusInsight>(insights(entries)).status,
      RunwayStatus.needsOpeningCash,
    );
    expect(only<RunwayInsight>(insights(entries, cash: usd(-500))).days, 0);
    expect(
      only<RunwayStatusInsight>(insights(entries, cash: usd(10000000))).status,
      RunwayStatus.overAYear,
    );
  });

  test('forecast scales profit so far to the whole period', () {
    // 16 of 31 days elapsed.
    final result = insights([
      _entry(EntryType.income, 16000, '2026-10-05'),
    ]);
    expect(only<ForecastInsight>(result).profit, usd(31000));

    final finished = buildInsights(
      entries: [_entry(EntryType.income, 16000, '2026-09-05')],
      currency: Currency.usd,
      range: rangeFor(ReportPeriod.lastMonth, today),
      comparison: comparisonRangeFor(ReportPeriod.lastMonth, today),
      today: today,
    );
    expect(
      only<ForecastStatusInsight>(finished).status,
      ForecastStatus.periodFinished,
    );
  });

  test('biggest category increase ignores small categories', () {
    final result = insights([
      // Compared with Sep 1-16.
      _entry(EntryType.expense, 10000, '2026-09-05', category: 'feed'),
      _entry(EntryType.expense, 15000, '2026-10-05', category: 'feed'),
      _entry(EntryType.expense, 100, '2026-09-05', category: 'tea'),
      _entry(EntryType.expense, 400, '2026-10-05', category: 'tea'),
      // After Sep 16: outside the comparison range.
      _entry(EntryType.expense, 50000, '2026-09-25', category: 'feed'),
    ]);
    final c = only<CategoryIncreaseInsight>(result);
    expect(c.categoryId, 'feed');
    expect(c.percent, 50);
    expect(c.increase, usd(5000));
  });

  test('top income source and concentration', () {
    final result = insights([
      _entry(EntryType.income, 8000, '2026-10-02', category: 'rice'),
      _entry(EntryType.income, 2000, '2026-10-03', category: 'eggs'),
      _entry(EntryType.income, 9000, '2026-10-03',
          category: 'eggs', status: EntryStatus.voided),
      _entry(EntryType.income, 50000, '2026-10-03',
          category: 'eggs', currency: Currency.khr),
    ]);
    final t = only<TopIncomeInsight>(result);
    expect(t.categoryId, 'rice');
    expect(t.percent, 80);
    expect(t.concentrated, isTrue);
  });

  test('every topic is always present, saying why when it has no figure',
      () {
    final result = buildInsights(
      entries: const [],
      currency: Currency.usd,
      range: range,
      comparison: comparison,
      today: DateTime(2026, 10, 3),
    );
    expect(result, hasLength(6));
    expect(result[0], isA<NoIncomeInsight>());
    expect(result[1], isA<WithdrawalOkInsight>());
    expect(
      (result[2] as RunwayStatusInsight).status,
      RunwayStatus.needsOpeningCash,
    );
    expect(
      (result[3] as ForecastStatusInsight).status,
      ForecastStatus.tooEarly,
    );
    expect(result[4], isA<NoCategoryIncreaseInsight>());
    expect((result[5] as NoIncomeInsight).forSource, isTrue);
  });

  test('rounded percent', () {
    expect(roundedPercent(1, 3), 33);
    expect(roundedPercent(2, 3), 67);
    expect(roundedPercent(-1, 8), -13);
  });
}
