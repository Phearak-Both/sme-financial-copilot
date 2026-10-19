/// Figures for the exported reports: income statement, cash flow and the
/// loan-ready summary.
///
/// Like the rest of `finance_core`, everything is deterministic, per
/// currency and in integer minor units, so a PDF shows exactly what the
/// dashboard does.
library;

import '../core/date_only.dart';
import '../core/money/currency.dart';
import '../core/money/money.dart';
import '../domain/enums.dart';
import 'insights.dart';
import 'ledger_math.dart';
import 'patterns.dart';
import 'period_math.dart';

/// Periods offered for reports. "Last N months" are whole calendar months
/// including the current one, like the dashboard's "last 3 months".
enum ReportRange {
  thisMonth,
  lastMonth,
  last3Months,
  last6Months,
  last12Months,
  thisYear;

  DateRange rangeFor(DateTime today) {
    final t = dateOnly(today);
    DateRange months(int count) => DateRange(
          DateTime(t.year, t.month - (count - 1)),
          DateTime(t.year, t.month + 1),
        );
    return switch (this) {
      thisMonth => months(1),
      lastMonth => DateRange.previousMonthOf(t),
      last3Months => months(3),
      last6Months => months(6),
      last12Months => months(12),
      thisYear => DateRange(DateTime(t.year), DateTime(t.year + 1)),
    };
  }
}

/// The period of the same length just before [range]: the same number of
/// calendar months when [range] is whole months, otherwise the same number
/// of days.
DateRange previousRange(DateRange range) {
  final s = range.start;
  final e = range.end;
  if (s.day == 1 && e.day == 1) {
    final months = (e.year - s.year) * 12 + e.month - s.month;
    return DateRange(DateTime(s.year, s.month - months), s);
  }
  return DateRange(addDays(s, -daysBetween(s, e)), s);
}

/// Calendar months overlapping [range], each cut to fit inside it.
List<DateRange> monthsIn(DateRange range) => [
      for (var m = DateTime(range.start.year, range.start.month);
          m.isBefore(range.end);
          m = DateTime(m.year, m.month + 1))
        DateRange(
          m.isBefore(range.start) ? range.start : m,
          DateTime(m.year, m.month + 1).isAfter(range.end)
              ? range.end
              : DateTime(m.year, m.month + 1),
        ),
    ];

bool _active(LedgerEntry e, Currency currency) =>
    e.currency == currency && e.status == EntryStatus.active;

Map<String?, int> _byCategory(
  Iterable<LedgerEntry> entries,
  Currency currency,
  DateRange range,
  EntryType type,
) {
  final totals = <String?, int>{};
  for (final e in entries) {
    if (!_active(e, currency) ||
        e.type != type ||
        !range.containsKey(e.occurredOn)) {
      continue;
    }
    totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amountMinor;
  }
  return totals;
}

// -------------------------------------------------------- income statement

/// One category's amount in the period and the one before.
class ReportLine {
  const ReportLine(this.categoryId, this.current, this.previous);

  final String? categoryId;
  final Money current;
  final Money previous;
}

/// Income and expenses by category for a period, against the period before.
class IncomeStatement {
  const IncomeStatement({
    required this.currency,
    required this.range,
    required this.comparison,
    required this.income,
    required this.expenses,
    required this.current,
    required this.previous,
  });

  final Currency currency;
  final DateRange range;
  final DateRange comparison;

  /// Largest first in the current period.
  final List<ReportLine> income;
  final List<ReportLine> expenses;
  final CurrencyTotals current;
  final CurrencyTotals previous;

  /// Profit as a share of income; null without income.
  int? get marginPercent => current.income.isZero
      ? null
      : roundedPercent(current.profit.minor, current.income.minor);
}

IncomeStatement buildIncomeStatement(
  Iterable<LedgerEntry> entries,
  Currency currency,
  DateRange range,
) {
  final comparison = previousRange(range);
  List<ReportLine> lines(EntryType type) {
    final now = _byCategory(entries, currency, range, type);
    final before = _byCategory(entries, currency, comparison, type);
    return [
      for (final id in {...now.keys, ...before.keys})
        ReportLine(
          id,
          Money(now[id] ?? 0, currency),
          Money(before[id] ?? 0, currency),
        ),
    ]..sort((a, b) {
        final byNow = b.current.compareTo(a.current);
        return byNow != 0 ? byNow : b.previous.compareTo(a.previous);
      });
  }

  CurrencyTotals totals(DateRange r) =>
      summarize(entries, r).byCurrency[currency] ??
      CurrencyTotals.empty(currency);

  return IncomeStatement(
    currency: currency,
    range: range,
    comparison: comparison,
    income: lines(EntryType.income),
    expenses: lines(EntryType.expense),
    current: totals(range),
    previous: totals(comparison),
  );
}

// ------------------------------------------------------------- cash flow

/// Cash in and out for one month of a cash flow report.
class CashFlowMonth {
  const CashFlowMonth(this.range, this.cashIn, this.cashOut, this.closing);

  final DateRange range;

  /// Income and owner contributions.
  final Money cashIn;

  /// Expenses and owner withdrawals.
  final Money cashOut;

  /// Cash at the end of the month; null when no opening cash is known yet.
  final Money? closing;

  Money get net => cashIn - cashOut;
}

class CashFlowReport {
  const CashFlowReport({
    required this.currency,
    required this.range,
    required this.opening,
    required this.incomeByCategory,
    required this.expensesByCategory,
    required this.totals,
    required this.months,
  });

  final Currency currency;
  final DateRange range;

  /// Cash at the start of [range]; null when the opening cash date is later
  /// or no opening cash is set.
  final Money? opening;
  final List<MapEntry<String?, Money>> incomeByCategory;
  final List<MapEntry<String?, Money>> expensesByCategory;
  final CurrencyTotals totals;
  final List<CashFlowMonth> months;

  Money get cashIn => totals.income + totals.ownerContribution;
  Money get cashOut => totals.expense + totals.ownerWithdrawal;

  /// Cash at the end of [range], if known.
  Money? get closing => months.isEmpty ? opening : months.last.closing;
}

/// Cash at the start of [day] from [opening], or null if it isn't known
/// (no opening cash, or it is dated after [day]).
Money? cashAt(
  Iterable<LedgerEntry> entries,
  OpeningBalance? opening,
  Currency currency,
  DateTime day,
) {
  if (opening == null) return null;
  final key = toDateKey(day);
  if (opening.asOf.compareTo(key) > 0) return null;
  var balance = opening.amountMinor;
  for (final e in entries) {
    if (!_active(e, currency) ||
        e.occurredOn.compareTo(opening.asOf) < 0 ||
        e.occurredOn.compareTo(key) >= 0) {
      continue;
    }
    balance += e.type.isMoneyIn ? e.amountMinor : -e.amountMinor;
  }
  return Money(balance, currency);
}

CashFlowReport buildCashFlow(
  Iterable<LedgerEntry> entries,
  Currency currency,
  DateRange range, {
  OpeningBalance? opening,
}) {
  List<MapEntry<String?, Money>> sorted(Map<String?, int> totals) => [
        for (final MapEntry(:key, :value) in totals.entries)
          MapEntry(key, Money(value, currency)),
      ]..sort((a, b) => b.value.compareTo(a.value));

  final mine = entries.where((e) => e.currency == currency).toList();
  return CashFlowReport(
    currency: currency,
    range: range,
    opening: cashAt(mine, opening, currency, range.start),
    incomeByCategory:
        sorted(_byCategory(mine, currency, range, EntryType.income)),
    expensesByCategory:
        sorted(_byCategory(mine, currency, range, EntryType.expense)),
    totals: summarize(mine, range).byCurrency[currency] ??
        CurrencyTotals.empty(currency),
    months: [
      for (final month in monthsIn(range))
        () {
          final t = summarize(mine, month).byCurrency[currency] ??
              CurrencyTotals.empty(currency);
          return CashFlowMonth(
            month,
            t.income + t.ownerContribution,
            t.expense + t.ownerWithdrawal,
            cashAt(mine, opening, currency, month.end),
          );
        }(),
    ],
  );
}

// ---------------------------------------------------------- loan summary

/// Results for one month of the loan summary.
class MonthResult {
  const MonthResult(this.range, this.totals);

  final DateRange range;
  final CurrencyTotals totals;
}

/// The figures a bank or microfinance lender usually asks for.
class LoanSummary {
  const LoanSummary({
    required this.currency,
    required this.range,
    required this.months,
    required this.averagedMonths,
    required this.current,
    required this.cash,
    required this.runwayDays,
    required this.incomeSources,
    required this.commitments,
    required this.firstRecord,
  });

  final Currency currency;
  final DateRange range;
  final List<MonthResult> months;

  /// Months the averages are taken over: the finished months of [range],
  /// or all of them when none has finished.
  final int averagedMonths;

  /// Totals for the whole range.
  final CurrencyTotals current;

  /// Cash on hand today, if opening cash is set.
  final Money? cash;

  /// How long [cash] lasts at the last 30 days' spending; null when it
  /// can't be worked out.
  final int? runwayDays;
  final List<MapEntry<String?, Money>> incomeSources;

  /// Regular monthly payments, including existing loan repayments.
  final List<RecurringExpense> commitments;

  /// The earliest active entry in this currency, `yyyy-MM-dd`.
  final String? firstRecord;

  Iterable<MonthResult> get _averaged =>
      months.take(averagedMonths);

  Money _average(Money Function(CurrencyTotals) pick) {
    if (averagedMonths == 0) return Money.zero(currency);
    final sum = _averaged.fold(0, (s, m) => s + pick(m.totals).minor);
    // Rounded half away from zero.
    final half = averagedMonths ~/ 2;
    return Money(
      sum >= 0
          ? (sum + half) ~/ averagedMonths
          : -((-sum + half) ~/ averagedMonths),
      currency,
    );
  }

  Money get averageIncome => _average((t) => t.income);
  Money get averageExpenses => _average((t) => t.expense);
  Money get averageProfit => _average((t) => t.profit);
  Money get averageWithdrawals => _average((t) => t.ownerWithdrawal);

  /// Profit left each month after the owner's withdrawals.
  Money get averageSurplus => averageProfit - averageWithdrawals;

  int? get marginPercent => current.income.isZero
      ? null
      : roundedPercent(current.profit.minor, current.income.minor);

  int get profitableMonths =>
      _averaged.where((m) => m.totals.profit.minor > 0).length;

  Money get commitmentsPerMonth =>
      commitments.fold(Money.zero(currency), (s, r) => s + r.typical);
}

LoanSummary buildLoanSummary(
  Iterable<LedgerEntry> entries,
  Currency currency,
  DateRange range, {
  required DateTime today,
  OpeningBalance? opening,
}) {
  final t = dateOnly(today);
  final mine = entries.where((e) => e.currency == currency).toList();
  final tomorrow = addDays(t, 1);
  // Months still in progress would drag the averages down.
  final months = [
    for (final month in monthsIn(range))
      if (month.start.isBefore(tomorrow))
        MonthResult(
          month,
          summarize(mine, month).byCurrency[currency] ??
              CurrencyTotals.empty(currency),
        ),
  ];
  final finished = months.where((m) => !m.range.end.isAfter(tomorrow)).length;

  final cash = cashAt(mine, opening, currency, tomorrow);
  int? runway;
  if (cash != null && cash.minor > 0) {
    final spent = summarize(
          mine,
          DateRange(addDays(tomorrow, -runwayRateDays), tomorrow),
        ).byCurrency[currency]?.expense.minor ??
        0;
    if (spent > 0) runway = cash.minor * runwayRateDays ~/ spent;
  }

  String? first;
  for (final e in mine) {
    if (e.status != EntryStatus.active) continue;
    if (first == null || e.occurredOn.compareTo(first) < 0) first = e.occurredOn;
  }

  return LoanSummary(
    currency: currency,
    range: range,
    months: months,
    averagedMonths: finished > 0 ? finished : months.length,
    current: summarize(mine, range).byCurrency[currency] ??
        CurrencyTotals.empty(currency),
    cash: cash,
    runwayDays: runway,
    incomeSources: [
      for (final MapEntry(:key, :value)
          in _byCategory(mine, currency, range, EntryType.income).entries)
        MapEntry(key, Money(value, currency)),
    ]..sort((a, b) => b.value.compareTo(a.value)),
    commitments: detectRecurring(mine, currency, today),
    firstRecord: first,
  );
}
