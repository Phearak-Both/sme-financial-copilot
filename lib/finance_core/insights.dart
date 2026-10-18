/// Plain-language observations for the dashboard, computed from the ledger.
///
/// Like the rest of `finance_core`, these are deterministic and per currency.
/// Each insight carries numbers only; the interface turns them into text.
library;

import '../core/date_only.dart';
import '../core/money/currency.dart';
import '../core/money/money.dart';
import '../domain/enums.dart';
import 'ledger_math.dart';
import 'period_math.dart';

/// [muted] is for an insight that can't be worked out yet.
enum InsightTone { good, neutral, warning, muted }

sealed class Insight {
  const Insight();

  InsightTone get tone;
}

/// Share of income kept as profit. Only when income is positive and the
/// period made a profit or broke even.
class MarginInsight extends Insight {
  const MarginInsight(this.percent);

  final int percent;

  @override
  InsightTone get tone =>
      percent >= 20 ? InsightTone.good : InsightTone.neutral;
}

/// Expenses were higher than income.
class LossInsight extends Insight {
  const LossInsight(this.loss);

  /// How much more was spent than earned (positive).
  final Money loss;

  @override
  InsightTone get tone => InsightTone.warning;
}

/// The owner took out more than the business earned.
class WithdrawalInsight extends Insight {
  const WithdrawalInsight(this.withdrawn, this.profit);

  final Money withdrawn;
  final Money profit;

  @override
  InsightTone get tone => InsightTone.warning;
}

/// How long cash on hand lasts at the recent spending rate.
class RunwayInsight extends Insight {
  const RunwayInsight(this.days);

  final int days;

  @override
  InsightTone get tone =>
      days < runwayWarningDays ? InsightTone.warning : InsightTone.good;
}

/// Profit for the whole period if the pace so far continues.
class ForecastInsight extends Insight {
  const ForecastInsight(this.profit);

  final Money profit;

  @override
  InsightTone get tone =>
      profit.isNegative ? InsightTone.warning : InsightTone.neutral;
}

/// The expense category that grew the most against the comparison period.
class CategoryIncreaseInsight extends Insight {
  const CategoryIncreaseInsight(this.categoryId, this.percent, this.increase);

  final String? categoryId;
  final int percent;
  final Money increase;

  @override
  InsightTone get tone => InsightTone.warning;
}

/// The biggest source of income and its share.
class TopIncomeInsight extends Insight {
  const TopIncomeInsight(this.categoryId, this.percent);

  final String? categoryId;
  final int percent;

  /// Most income depends on one source.
  bool get concentrated => percent >= 70;

  @override
  InsightTone get tone => InsightTone.neutral;
}

/// No income in the period, so there is no margin or income source.
class NoIncomeInsight extends Insight {
  const NoIncomeInsight({required this.forSource});

  /// Shown in the income source slot rather than the margin slot.
  final bool forSource;

  @override
  InsightTone get tone => InsightTone.muted;
}

/// Withdrawals, if any, stayed within profit.
class WithdrawalOkInsight extends Insight {
  const WithdrawalOkInsight(this.withdrawn, this.profit);

  final Money withdrawn;
  final Money profit;

  @override
  InsightTone get tone => InsightTone.good;
}

/// Why the runway can't be shown, or that it is very long.
enum RunwayStatus { needsOpeningCash, noRecentSpending, overAYear }

class RunwayStatusInsight extends Insight {
  const RunwayStatusInsight(this.status);

  final RunwayStatus status;

  @override
  InsightTone get tone => status == RunwayStatus.overAYear
      ? InsightTone.good
      : InsightTone.muted;
}

/// Why there is no forecast.
enum ForecastStatus { tooEarly, periodFinished }

class ForecastStatusInsight extends Insight {
  const ForecastStatusInsight(this.status);

  final ForecastStatus status;

  @override
  InsightTone get tone => InsightTone.muted;
}

/// No expense category rose sharply.
class NoCategoryIncreaseInsight extends Insight {
  const NoCategoryIncreaseInsight();

  @override
  InsightTone get tone => InsightTone.good;
}

/// Below this many days of cash, the runway is flagged.
const runwayWarningDays = 30;

/// Days of spending used for the runway rate.
const runwayRateDays = 30;

/// One insight per topic for [currency] in [range], always in the same
/// order: margin, withdrawals, runway, forecast, expense increase and income
/// source. A topic that can't be worked out says why.
///
/// [entries] must cover [range], [comparison] and the [runwayRateDays] days
/// up to [today]. [cash] is cash on hand, if an opening balance is set.
List<Insight> buildInsights({
  required Iterable<LedgerEntry> entries,
  required Currency currency,
  required DateRange range,
  required DateRange comparison,
  required DateTime today,
  Money? cash,
}) {
  final mine = entries.where((e) => e.currency == currency).toList();
  final totals =
      summarize(mine, range).byCurrency[currency] ??
      CurrencyTotals.empty(currency);
  final insights = <Insight>[];

  // Margin or loss.
  final profit = totals.profit;
  if (profit.isNegative) {
    insights.add(LossInsight(-profit));
  } else if (totals.income.minor > 0) {
    insights.add(
      MarginInsight(roundedPercent(profit.minor, totals.income.minor)),
    );
  } else {
    insights.add(const NoIncomeInsight(forSource: false));
  }

  // Withdrawals beyond what the business earned.
  final withdrawn = totals.ownerWithdrawal;
  if (withdrawn.minor > 0 && withdrawn.minor > profit.minor) {
    insights.add(WithdrawalInsight(withdrawn, profit));
  } else {
    insights.add(WithdrawalOkInsight(withdrawn, profit));
  }

  // Cash runway at the recent spending rate.
  if (cash == null) {
    insights.add(const RunwayStatusInsight(RunwayStatus.needsOpeningCash));
  } else if (cash.minor <= 0) {
    insights.add(const RunwayInsight(0));
  } else {
    final tomorrow = addDays(dateOnly(today), 1);
    final recent = DateRange(addDays(tomorrow, -runwayRateDays), tomorrow);
    final spent = summarize(mine, recent).byCurrency[currency]?.expense;
    if (spent == null || spent.minor == 0) {
      insights.add(const RunwayStatusInsight(RunwayStatus.noRecentSpending));
    } else {
      final days = cash.minor * runwayRateDays ~/ spent.minor;
      insights.add(
        days > 365
            ? const RunwayStatusInsight(RunwayStatus.overAYear)
            : RunwayInsight(days),
      );
    }
  }

  // Forecast for a period still in progress, once there's a week of data.
  final elapsed = elapsedPart(range, today);
  final elapsedDays = daysBetween(elapsed.start, elapsed.end);
  final totalDays = daysBetween(range.start, range.end);
  if (elapsed == range) {
    insights.add(const ForecastStatusInsight(ForecastStatus.periodFinished));
  } else if (elapsedDays < 7) {
    insights.add(const ForecastStatusInsight(ForecastStatus.tooEarly));
  } else {
    insights.add(
      ForecastInsight(Money(profit.minor * totalDays ~/ elapsedDays, currency)),
    );
  }

  // Biggest expense category increase. Small categories are ignored so a
  // jump from $1 to $3 doesn't crowd out what matters.
  final now = expensesByCategory(mine, range)[currency] ?? const [];
  final before = <String?, int>{
    for (final e in expensesByCategory(mine, comparison)[currency] ?? const [])
      e.key: e.value.minor,
  };
  CategoryIncreaseInsight? biggest;
  for (final MapEntry(key: id, value: amount) in now) {
    final previous = before[id] ?? 0;
    final increase = amount.minor - previous;
    if (previous == 0 || increase <= 0) continue;
    final percent = roundedPercent(increase, previous);
    if (percent < 20 || increase * 10 < totals.expense.minor) continue;
    if (biggest == null || increase > biggest.increase.minor) {
      biggest = CategoryIncreaseInsight(id, percent, Money(increase, currency));
    }
  }
  insights.add(biggest ?? const NoCategoryIncreaseInsight());

  // Top income source.
  final incomeByCategory = <String?, int>{};
  for (final e in mine) {
    if (e.type != EntryType.income ||
        e.status != EntryStatus.active ||
        !range.containsKey(e.occurredOn)) {
      continue;
    }
    incomeByCategory[e.categoryId] =
        (incomeByCategory[e.categoryId] ?? 0) + e.amountMinor;
  }
  if (totals.income.minor > 0 && incomeByCategory.isNotEmpty) {
    final top = incomeByCategory.entries.reduce(
      (a, b) => b.value > a.value ? b : a,
    );
    insights.add(
      TopIncomeInsight(top.key, roundedPercent(top.value, totals.income.minor)),
    );
  } else {
    insights.add(const NoIncomeInsight(forSource: true));
  }

  return insights;
}

/// `part / whole` as a whole-number percentage, rounded half away from zero.
int roundedPercent(int part, int whole) {
  final scaled = part.abs() * 100;
  final rounded = (scaled * 2 + whole.abs()) ~/ (whole.abs() * 2);
  return (part < 0) != (whole < 0) ? -rounded : rounded;
}
