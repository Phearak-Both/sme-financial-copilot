/// Patterns across months: regular payments, unusual spending, seasons,
/// busy weekdays and owner withdrawals against profit.
///
/// Like the rest of `finance_core`, everything is deterministic, works in
/// integer minor units and looks at one currency at a time.
library;

import '../core/date_only.dart';
import '../core/money/currency.dart';
import '../core/money/money.dart';
import '../domain/enums.dart';
import 'insights.dart';
import 'ledger_math.dart';

bool _isActive(LedgerEntry e, Currency currency) =>
    e.currency == currency && e.status == EntryStatus.active;

// --------------------------------------------------------- regular payments

/// An expense paid about once a month, such as rent or electricity.
class RecurringExpense {
  const RecurringExpense({
    required this.key,
    required this.categoryId,
    required this.description,
    required this.typical,
    required this.dayOfMonth,
    required this.nextDue,
    required this.paidThisMonth,
  });

  /// Groups the entries this was found from; see [recurringKey].
  final String key;
  final String? categoryId;
  final String description;

  /// The middle amount of past payments.
  final Money typical;
  final int dayOfMonth;
  final DateTime nextDue;
  final bool paidThisMonth;

  /// Days from [today] to [nextDue]; negative when it looks overdue.
  int daysUntil(DateTime today) => daysBetween(dateOnly(today), nextDue);
}

/// Entries with the same category and description are the same payment.
String recurringKey(LedgerEntry e) =>
    '${e.categoryId}|${e.description.trim().toLowerCase()}';

/// Months of history searched for regular payments.
const recurringLookbackMonths = 6;

/// Expenses seen in at least 3 of the last [recurringLookbackMonths] months,
/// at most once a month, on about the same day and for about the same amount.
/// Ordered by when they are next due.
List<RecurringExpense> detectRecurring(
  Iterable<LedgerEntry> entries,
  Currency currency,
  DateTime today,
) {
  final t = dateOnly(today);
  final thisMonth = DateTime(t.year, t.month);
  final window = DateRange(
    DateTime(t.year, t.month - recurringLookbackMonths),
    addDays(t, 1),
  );
  final groups = <String, List<LedgerEntry>>{};
  for (final e in entries) {
    if (!_isActive(e, currency) ||
        e.type != EntryType.expense ||
        e.description.trim().isEmpty ||
        !window.containsKey(e.occurredOn)) {
      continue;
    }
    groups.putIfAbsent(recurringKey(e), () => []).add(e);
  }

  final result = <RecurringExpense>[];
  for (final MapEntry(key: key, value: group) in groups.entries) {
    final months = {for (final e in group) e.occurredOn.substring(0, 7)};
    if (months.length < 3 || group.length > months.length) continue;

    final amounts = group.map((e) => e.amountMinor).toList()..sort();
    final typical = amounts[amounts.length ~/ 2];
    // Within 25% of the middle amount.
    if (amounts.any((a) => (a - typical).abs() * 4 > typical)) continue;

    final days = group.map((e) => fromDateKey(e.occurredOn).day).toList()
      ..sort();
    final day = days[days.length ~/ 2];
    if (days.any((d) => (d - day).abs() > 5)) continue;

    final paid = months.contains(toDateKey(thisMonth).substring(0, 7));
    final dueMonth = paid
        ? DateTime(thisMonth.year, thisMonth.month + 1)
        : thisMonth;
    final lastDay = DateTime(dueMonth.year, dueMonth.month + 1, 0).day;
    final latest = group.reduce(
      (a, b) => a.occurredOn.compareTo(b.occurredOn) >= 0 ? a : b,
    );
    result.add(RecurringExpense(
      key: key,
      categoryId: latest.categoryId,
      description: latest.description.trim(),
      typical: Money(typical, currency),
      dayOfMonth: day,
      nextDue: DateTime(dueMonth.year, dueMonth.month, day > lastDay ? lastDay : day),
      paidThisMonth: paid,
    ));
  }
  return result..sort((a, b) => a.nextDue.compareTo(b.nextDue));
}

// ------------------------------------------------------- unusual spending

/// One expense category this month against its usual level.
class CategoryComparison {
  const CategoryComparison(this.categoryId, this.current, this.usual);

  final String? categoryId;
  final Money current;

  /// Average of the same days in the previous [usualMonths] months.
  final Money usual;

  /// Null when there is nothing usual to compare with.
  int? get percent =>
      usual.isZero ? null : roundedPercent(current.minor - usual.minor, usual.minor);

  /// A jump of at least [alertPercent], ignoring small amounts.
  bool isAlert(Money usualTotal) {
    final p = percent;
    final increase = current.minor - usual.minor;
    return p != null && p >= alertPercent && increase * 20 >= usualTotal.minor;
  }
}

/// Months averaged for "usual" spending.
const usualMonths = 3;

/// Spending this much above usual is flagged.
const alertPercent = 30;

/// Spending by category so far this month, compared with the same days of
/// each of the previous [usualMonths] months (so the 19th is compared with
/// the 1st-19th, not with whole months). Regular payments ([recurringKeys])
/// are left out, since they aren't surprises.
///
/// Largest increase first. Empty when there's no earlier history.
List<CategoryComparison> compareWithUsual(
  Iterable<LedgerEntry> entries,
  Currency currency,
  DateTime today, {
  Set<String> recurringKeys = const {},
}) {
  final t = dateOnly(today);
  final elapsed = t.day;
  final mine = entries
      .where((e) =>
          _isActive(e, currency) &&
          e.type == EntryType.expense &&
          !recurringKeys.contains(recurringKey(e)))
      .toList();

  Map<String?, int> byCategory(DateRange range) {
    final totals = <String?, int>{};
    for (final e in mine) {
      if (!range.containsKey(e.occurredOn)) continue;
      totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.amountMinor;
    }
    return totals;
  }

  final current = byCategory(DateRange(DateTime(t.year, t.month), addDays(t, 1)));
  final earlier = <String?, int>{};
  var monthsWithData = 0;
  for (var i = 1; i <= usualMonths; i++) {
    final start = DateTime(t.year, t.month - i);
    final monthEnd = DateTime(t.year, t.month - i + 1);
    final end = DateTime(start.year, start.month, elapsed + 1);
    final totals = byCategory(
      DateRange(start, end.isAfter(monthEnd) ? monthEnd : end),
    );
    if (totals.isNotEmpty) monthsWithData++;
    for (final MapEntry(:key, :value) in totals.entries) {
      earlier[key] = (earlier[key] ?? 0) + value;
    }
  }
  if (monthsWithData == 0) return const [];

  final result = [
    for (final id in {...current.keys, ...earlier.keys})
      CategoryComparison(
        id,
        Money(current[id] ?? 0, currency),
        // Rounded to the nearest minor unit.
        Money(((earlier[id] ?? 0) * 2 + usualMonths) ~/ (usualMonths * 2), currency),
      ),
  ];
  return result
    ..sort((a, b) => (b.current.minor - b.usual.minor)
        .compareTo(a.current.minor - a.usual.minor));
}

// ------------------------------------------------------------ seasonality

/// Income for each calendar month, per year, to show busy and lean seasons.
class Seasonality {
  const Seasonality(this.years, this.peakMonths, this.lowMonths);

  /// Year -> 12 monthly totals (January first), oldest year first. Months
  /// before the first record, and this month onwards, are null, so a month
  /// still in progress doesn't look like a slump.
  final Map<int, List<Money?>> years;

  /// Months (1-12) with the highest and lowest average income. Empty until
  /// there is a full year of history.
  final List<int> peakMonths;
  final List<int> lowMonths;
}

/// Income by month for up to the last [maxYears] calendar years that have
/// income. Null when there's no income at all.
Seasonality? seasonality(
  Iterable<LedgerEntry> entries,
  Currency currency,
  DateTime today, {
  int maxYears = 3,
}) {
  final t = dateOnly(today);
  final totals = <int, List<int>>{};
  String? first;
  for (final e in entries) {
    if (!_isActive(e, currency) || e.type != EntryType.income) continue;
    final date = fromDateKey(e.occurredOn);
    if (date.year <= t.year - maxYears || date.isAfter(t)) continue;
    totals.putIfAbsent(date.year, () => List.filled(12, 0))[date.month - 1] +=
        e.amountMinor;
    if (first == null || e.occurredOn.compareTo(first) < 0) first = e.occurredOn;
  }
  if (totals.isEmpty) return null;

  final years = [...totals.keys]..sort();
  final thisMonth = DateTime(t.year, t.month);
  final firstDate = fromDateKey(first!);
  final firstMonth = DateTime(firstDate.year, firstDate.month);
  final series = <int, List<Money?>>{
    for (final year in years)
      year: [
        for (var m = 1; m <= 12; m++)
          !DateTime(year, m).isBefore(thisMonth) ||
                  DateTime(year, m).isBefore(firstMonth)
              ? null
              : Money(totals[year]![m - 1], currency),
      ],
  };

  // Average each calendar month over the years where it is complete.
  final averages = <int, int>{};
  for (var m = 1; m <= 12; m++) {
    var sum = 0;
    var count = 0;
    for (final year in years) {
      final month = DateTime(year, m);
      if (!month.isBefore(thisMonth) || series[year]![m - 1] == null) continue;
      sum += totals[year]![m - 1];
      count++;
    }
    if (count > 0) averages[m] = sum ~/ count;
  }
  if (averages.length < 12) return Seasonality(series, const [], const []);

  final ranked = averages.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Seasonality(
    series,
    [ranked[0].key, ranked[1].key]..sort(),
    [ranked[11].key, ranked[10].key]..sort(),
  );
}

// ---------------------------------------------------------------- weekdays

/// Average income on each day of the week.
class WeekdayIncome {
  const WeekdayIncome(this.averages);

  /// Monday first, as in [DateTime.weekday] - 1.
  final List<Money> averages;

  /// Weekday numbers (1 = Monday) of the best and worst days.
  int get best => _pick((a, b) => a > b);
  int get worst => _pick((a, b) => a < b);

  int _pick(bool Function(int, int) better) {
    var index = 0;
    for (var i = 1; i < 7; i++) {
      if (better(averages[i].minor, averages[index].minor)) index = i;
    }
    return index + 1;
  }

  /// How many times the best day's income the worst day brings, in tenths
  /// (21 = 2.1×). Null when the worst day has no income.
  int? get ratioTenths {
    final low = averages[worst - 1].minor;
    if (low == 0) return null;
    return (averages[best - 1].minor * 20 + low) ~/ (low * 2);
  }
}

/// Weeks of history used for [weekdayIncome].
const weekdayWeeks = 12;

/// Average income per weekday over the [weekdayWeeks] weeks up to [today],
/// counting days with no sales as zero. Null without any income.
WeekdayIncome? weekdayIncome(
  Iterable<LedgerEntry> entries,
  Currency currency,
  DateTime today,
) {
  final end = addDays(dateOnly(today), 1);
  final range = DateRange(addDays(end, -weekdayWeeks * 7), end);
  final sums = List.filled(7, 0);
  var any = false;
  for (final e in entries) {
    if (!_isActive(e, currency) ||
        e.type != EntryType.income ||
        !range.containsKey(e.occurredOn)) {
      continue;
    }
    sums[fromDateKey(e.occurredOn).weekday - 1] += e.amountMinor;
    any = true;
  }
  if (!any) return null;
  // The range is whole weeks, so every weekday occurs [weekdayWeeks] times.
  return WeekdayIncome([
    for (final s in sums)
      Money((s * 2 + weekdayWeeks) ~/ (weekdayWeeks * 2), currency),
  ]);
}

// ---------------------------------------------------- withdrawals vs profit

/// Profit and owner withdrawals for one month.
class MonthProfitWithdrawal {
  const MonthProfitWithdrawal(this.month, this.profit, this.withdrawn);

  final DateRange month;
  final Money profit;
  final Money withdrawn;

  /// The owner took out more than the business earned.
  bool get overdrawn => withdrawn.minor > 0 && withdrawn.minor > profit.minor;
}

/// The last [months] calendar months up to and including this one, oldest
/// first.
List<MonthProfitWithdrawal> profitVsWithdrawals(
  Iterable<LedgerEntry> entries,
  Currency currency,
  DateTime today, {
  int months = 6,
}) {
  final t = dateOnly(today);
  final mine = entries.where((e) => e.currency == currency).toList();
  return [
    for (var i = months - 1; i >= 0; i--)
      () {
        final range = DateRange.monthOf(DateTime(t.year, t.month - i));
        final totals = summarize(mine, range).byCurrency[currency] ??
            CurrencyTotals.empty(currency);
        return MonthProfitWithdrawal(range, totals.profit, totals.ownerWithdrawal);
      }(),
  ];
}
