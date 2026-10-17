/// Period comparison, monthly trends and cash balances.
///
/// Like `ledger_math.dart`, everything here is deterministic and per
/// currency, so the dashboard, Home and later the AI assistant agree.
library;

import '../core/date_only.dart';
import '../core/money/currency.dart';
import '../core/money/money.dart';
import '../domain/enums.dart';
import 'ledger_math.dart';

/// Reporting periods offered on the dashboard.
enum ReportPeriod { thisMonth, lastMonth, last3Months, thisYear }

/// The calendar range a [ReportPeriod] covers, relative to [today].
DateRange rangeFor(ReportPeriod period, DateTime today) {
  final t = dateOnly(today);
  return switch (period) {
    ReportPeriod.thisMonth => DateRange.monthOf(t),
    ReportPeriod.lastMonth => DateRange.previousMonthOf(t),
    ReportPeriod.last3Months =>
      DateRange(DateTime(t.year, t.month - 2), DateTime(t.year, t.month + 1)),
    ReportPeriod.thisYear => DateRange(DateTime(t.year), DateTime(t.year + 1)),
  };
}

/// The part of [range] that has already happened (it ends after [today]).
DateRange elapsedPart(DateRange range, DateTime today) {
  final tomorrow = addDays(dateOnly(today), 1);
  return tomorrow.isBefore(range.end) ? DateRange(range.start, tomorrow) : range;
}

/// The earlier range to compare [period] against.
///
/// For a period still in progress, the comparison covers the same number of
/// elapsed days at the start of the previous period, so 16 days of this month
/// are compared with the first 16 days of last month, not all of it.
DateRange comparisonRangeFor(ReportPeriod period, DateTime today) {
  final current = rangeFor(period, today);
  final elapsed = elapsedPart(current, today);

  final previous = switch (period) {
    ReportPeriod.thisMonth ||
    ReportPeriod.lastMonth =>
      DateRange.previousMonthOf(current.start),
    ReportPeriod.last3Months => DateRange(
        DateTime(current.start.year, current.start.month - 3),
        current.start,
      ),
    ReportPeriod.thisYear =>
      DateRange(DateTime(current.start.year - 1), current.start),
  };

  // A finished period is compared with the whole previous period.
  if (elapsed == current) return previous;

  final cappedEnd =
      addDays(previous.start, daysBetween(current.start, elapsed.end));
  return cappedEnd.isBefore(previous.end)
      ? DateRange(previous.start, cappedEnd)
      : previous;
}

/// Whole-number percentage change from [previous] to [current], rounded
/// half away from zero. Null when [previous] is zero, because a change from
/// nothing has no meaningful percentage.
int? percentChange(Money current, Money previous) {
  if (previous.isZero) return null;
  final diff = (current - previous).minor * 100;
  final base = previous.minor.abs();
  final rounded = (diff.abs() * 2 + base) ~/ (base * 2);
  return diff.isNegative ? -rounded : rounded;
}

/// Income and expense for one calendar month.
class MonthTotals {
  const MonthTotals(this.month, this.income, this.expense);

  /// First day of the month.
  final DateTime month;
  final Money income;
  final Money expense;
}

/// Income and expense per month for the [months] months ending with the
/// month that contains [lastMonth], oldest first. Months with no entries are
/// included as zero so gaps are visible.
List<MonthTotals> monthlyTrend(
  Iterable<LedgerEntry> entries,
  Currency currency, {
  required DateTime lastMonth,
  int months = 6,
}) {
  final ranges = [
    for (var i = months - 1; i >= 0; i--)
      DateRange.monthOf(DateTime(lastMonth.year, lastMonth.month - i)),
  ];
  final relevant = entries.where((e) => e.currency == currency).toList();
  return [
    for (final range in ranges)
      () {
        final totals = summarize(relevant, range).byCurrency[currency] ??
            CurrencyTotals.empty(currency);
        return MonthTotals(range.start, totals.income, totals.expense);
      }(),
  ];
}

/// Cash the business had at the start of [asOf] in one currency.
class OpeningBalance {
  const OpeningBalance({
    required this.currency,
    required this.amountMinor,
    required this.asOf,
  });

  final Currency currency;
  final int amountMinor;

  /// `yyyy-MM-dd`. Entries on or after this date change the balance.
  final String asOf;
}

/// Current cash balance per currency: opening balance plus the net cash flow
/// of active entries dated on or after the opening date.
///
/// Only currencies with an opening balance appear. Without one, a balance
/// can't be known, so none is shown rather than a misleading figure.
Map<Currency, Money> cashBalances(
  Iterable<OpeningBalance> openings,
  Iterable<LedgerEntry> entries,
) {
  final result = <Currency, Money>{};
  for (final opening in openings) {
    var balance = Money(opening.amountMinor, opening.currency);
    for (final entry in entries) {
      if (entry.currency != opening.currency ||
          entry.status != EntryStatus.active ||
          entry.occurredOn.compareTo(opening.asOf) < 0) {
        continue;
      }
      final amount = Money(entry.amountMinor, entry.currency);
      balance = entry.type.isMoneyIn ? balance + amount : balance - amount;
    }
    result[opening.currency] = balance;
  }
  return {
    for (final currency in Currency.values)
      if (result[currency] != null) currency: result[currency]!,
  };
}
