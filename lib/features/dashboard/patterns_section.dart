import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/labels.dart';
import '../../app/load_error.dart';
import '../../app/providers.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../finance_core/patterns.dart';
import 'chart_style.dart';

/// Views that look across months of history rather than the selected
/// period: spending against usual, regular bills, withdrawals against
/// profit, busy weekdays and seasons.
class PatternsSection extends ConsumerWidget {
  const PatternsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final patterns = ref.watch(dashboardPatternsProvider);
    if (patterns.hasError && !patterns.hasValue) return const LoadError();
    final p = patterns.value;
    if (p == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.patternsTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          l10n.patternsSubtitle,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        _SpendingVsUsual(p.spending),
        const SizedBox(height: 16),
        _RegularPayments(p.recurring),
        const SizedBox(height: 16),
        _WithdrawalChart(p.withdrawals),
        if (p.weekdays != null) ...[
          const SizedBox(height: 16),
          _WeekdayChart(p.weekdays!),
        ],
        if (p.seasons != null) ...[
          const SizedBox(height: 16),
          _SeasonChart(p.seasons!),
        ],
      ],
    );
  }
}

// ------------------------------------------------------ spending vs usual

class _SpendingVsUsual extends ConsumerWidget {
  const _SpendingVsUsual(this.rows);

  final List<CategoryComparison> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = context.localeTag;
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesByIdProvider);
    final nowColor = MoneyColors.moneyOut(context);
    final usualColor = theme.colorScheme.onSurfaceVariant;

    if (rows.isEmpty) {
      return ChartCard(
        title: l10n.usualTitle,
        child: Text(l10n.usualNoHistory),
      );
    }
    final currency = rows.first.current.currency;
    final usualTotal = Money(
      rows.fold(0, (sum, r) => sum + r.usual.minor),
      currency,
    );
    final alerts = rows.where((r) => r.isAlert(usualTotal)).toList();
    // The biggest categories either way, at most six bars.
    final shown = [...rows]
      ..sort((a, b) {
        int size(CategoryComparison r) =>
            r.current.minor > r.usual.minor ? r.current.minor : r.usual.minor;
        return size(b).compareTo(size(a));
      });
    final bars = shown.take(6).toList();
    final max = bars.fold<int>(1, (m, r) {
      final v = r.current.minor > r.usual.minor ? r.current.minor : r.usual.minor;
      return v > m ? v : m;
    });

    return ChartCard(
      title: l10n.usualTitle,
      subtitle: l10n.usualSubtitle,
      legend: Legend([
        (nowColor, l10n.usualThisMonth),
        (usualColor, l10n.usualAverage),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final alert in alerts.take(2)) ...[
            ChartNote(
              warning: true,
              text: '${l10n.usualAlert(context.categoryName(categories[alert.categoryId]), '${alert.percent}')}\n'
                  '${l10n.usualAlertBody(formatMoney(alert.current - alert.usual, locale: locale), formatMoney(alert.usual, locale: locale))}',
            ),
            const SizedBox(height: 8),
          ],
          if (alerts.isEmpty) ...[
            ChartNote(text: l10n.usualNoAlert),
            const SizedBox(height: 8),
          ],
          for (final row in bars)
            _UsualBar(
              label: context.categoryName(categories[row.categoryId]),
              row: row,
              max: max,
              nowColor: nowColor,
              usualColor: usualColor,
              highlighted: alerts.contains(row),
            ),
        ],
      ),
    );
  }
}

/// This month's spending as a bar, with the usual level as a tick mark.
class _UsualBar extends StatelessWidget {
  const _UsualBar({
    required this.label,
    required this.row,
    required this.max,
    required this.nowColor,
    required this.usualColor,
    required this.highlighted,
  });

  final String label;
  final CategoryComparison row;
  final int max;
  final Color nowColor;
  final Color usualColor;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeTag;
    final theme = Theme.of(context);
    final percent = row.percent;
    final change = percent == null
        ? l10n.usualNew
        : '${percent > 0 ? '+' : ''}$percent%';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: highlighted
                      ? const TextStyle(fontWeight: FontWeight.w600)
                      : null,
                ),
              ),
              Text(
                formatMoney(row.current, locale: locale),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                child: Text(
                  change,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: highlighted
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: highlighted ? FontWeight.w700 : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final usualX = width * row.usual.minor / max;
            return SizedBox(
              height: 14,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: 3,
                    bottom: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: nowColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 3,
                    bottom: 3,
                    width: width * row.current.minor / max,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: highlighted ? nowColor : nowColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  if (!row.usual.isZero)
                    Positioned(
                      left: (usualX - 1.5).clamp(0, width - 3),
                      top: 0,
                      bottom: 0,
                      width: 3,
                      child: Tooltip(
                        message:
                            '${l10n.usualAverage}: ${formatMoney(row.usual, locale: locale)}',
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: usualColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// -------------------------------------------------------- regular payments

class _RegularPayments extends ConsumerWidget {
  const _RegularPayments(this.items);

  final List<RecurringExpense> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = context.localeTag;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final categories = ref.watch(categoriesByIdProvider);
    final today = DateTime.now();

    if (items.isEmpty) {
      return ChartCard(title: l10n.recurringTitle, child: Text(l10n.recurringNone));
    }
    final soon = items.where((r) => r.daysUntil(today) <= 7).toList();
    final soonTotal = soon.isEmpty
        ? null
        : soon.map((r) => r.typical).reduce((a, b) => a + b);

    return ChartCard(
      title: l10n.recurringTitle,
      subtitle: l10n.recurringSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChartNote(
            text: soonTotal == null
                ? l10n.recurringNoneSoon
                : l10n.recurringUpcoming(formatMoney(soonTotal, locale: locale)),
          ),
          const SizedBox(height: 4),
          for (final item in items)
            () {
              final days = item.daysUntil(today);
              final (status, color) = switch (days) {
                < 0 => (l10n.recurringLate, scheme.error),
                0 => (l10n.recurringDueToday, scheme.error),
                1 => (l10n.recurringDueTomorrow, scheme.primary),
                _ when item.paidThisMonth && days > 7 =>
                  (l10n.recurringPaid, MoneyColors.moneyIn(context)),
                _ => (l10n.recurringDueIn('$days'), days <= 7 ? scheme.primary : scheme.onSurfaceVariant),
              };
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.surfaceContainerHighest,
                  child: Text(
                    NumberFormat('0', locale).format(item.dayOfMonth),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                title: Text(item.description),
                subtitle: Text(
                  '${context.categoryName(categories[item.categoryId])} · '
                  '${l10n.recurringEvery(formatMoney(item.typical, locale: locale), NumberFormat('0', locale).format(item.dayOfMonth))}',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }(),
        ],
      ),
    );
  }
}

// --------------------------------------------------- withdrawals vs profit

class _WithdrawalChart extends StatelessWidget {
  const _WithdrawalChart(this.months);

  final List<MonthProfitWithdrawal> months;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeTag;
    final profitColor = seriesColors(context)[0];
    final drawColor = seriesColors(context)[1];
    final current = months.last;
    final overCount = months.where((m) => m.overdrawn).length;

    final note = current.overdrawn
        ? ChartNote(
            warning: true,
            text: l10n.withdrawThisMonth(
              formatMoney(current.withdrawn, locale: locale),
              formatMoney(current.profit, locale: locale),
            ),
          )
        : overCount > 0
            ? ChartNote(warning: true, text: l10n.withdrawMonthsOver('$overCount'))
            : ChartNote(text: l10n.withdrawNeverOver);

    return ChartCard(
      title: l10n.withdrawChartTitle,
      legend: Legend([
        (profitColor, l10n.chartProfit),
        (drawColor, l10n.chartWithdrawn),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          note,
          const SizedBox(height: 16),
          _GroupedBars(
            labels: [
              for (final m in months) DateFormat.MMM(locale).format(m.month.start),
            ],
            series: [
              (l10n.chartProfit, profitColor, [for (final m in months) m.profit]),
              (l10n.chartWithdrawn, drawColor, [for (final m in months) m.withdrawn]),
            ],
            flagged: {
              for (final (i, m) in months.indexed)
                if (m.overdrawn) i,
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- weekdays

class _WeekdayChart extends StatelessWidget {
  const _WeekdayChart(this.weekdays);

  final WeekdayIncome weekdays;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeTag;
    final theme = Theme.of(context);
    // 2026-01-05 is a Monday.
    String name(int weekday, {bool short = false}) =>
        (short ? DateFormat.E(locale) : DateFormat.EEEE(locale))
            .format(DateTime(2026, 1, 4 + weekday));

    final best = weekdays.best;
    final worst = weekdays.worst;
    final ratio = weekdays.ratioTenths;
    final note = ratio == null
        ? l10n.weekdayNoIncome(name(best), name(worst))
        : l10n.weekdayRatio(
            name(best),
            NumberFormat('0.0', locale).format(ratio / 10),
            name(worst),
          );
    final inColor = MoneyColors.moneyIn(context);

    return ChartCard(
      title: l10n.weekdayTitle,
      subtitle: l10n.weekdaySubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChartNote(text: note),
          const SizedBox(height: 16),
          _GroupedBars(
            labels: [for (var d = 1; d <= 7; d++) name(d, short: true)],
            series: [(l10n.moneyIn, inColor, weekdays.averages)],
            // The best day is solid, the worst grey, the rest lighter.
            colorFor: (i, base) => i + 1 == best
                ? base
                : i + 1 == worst
                    ? theme.colorScheme.outline
                    : base.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- seasons

class _SeasonChart extends StatelessWidget {
  const _SeasonChart(this.seasons);

  final Seasonality seasons;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeTag;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = seriesColors(context);
    final years = seasons.years.keys.toList();
    final currency = seasons.years.values
        .expand((m) => m)
        .firstWhere((m) => m != null)!
        .currency;
    String month(int m, {bool short = true}) =>
        (short ? DateFormat.MMM(locale) : DateFormat.MMMM(locale))
            .format(DateTime(2026, m));
    String months(List<int> list) => list.map((m) => month(m, short: false)).join(', ');

    final maxValue = seasons.years.values
        .expand((m) => m)
        .whereType<Money>()
        .fold<double>(0, (m, v) => toMajor(v) > m ? toMajor(v) : m);
    final interval = niceStep(maxValue == 0 ? 1 : maxValue / 4);
    final compact = NumberFormat.compact(locale: locale);
    final axisStyle =
        theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);

    return ChartCard(
      title: l10n.seasonTitle,
      legend: Legend([
        for (final (i, year) in years.indexed)
          (palette[i], NumberFormat('0', locale).format(year)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChartNote(
            text: seasons.peakMonths.isEmpty
                ? l10n.seasonNeedYear
                : l10n.seasonPeaks(months(seasons.peakMonths), months(seasons.lowMonths)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 11,
                minY: 0,
                maxY: interval * 4,
                // Shade the busiest months behind the lines.
                rangeAnnotations: RangeAnnotations(
                  verticalRangeAnnotations: [
                    for (final m in seasons.peakMonths)
                      VerticalRangeAnnotation(
                        x1: m - 1.4 < 0 ? 0 : m - 1.4,
                        x2: m - 0.6 > 11 ? 11 : m - 0.6,
                        color: MoneyColors.moneyIn(context).withValues(alpha: 0.10),
                      ),
                  ],
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: scheme.outlineVariant,
                    strokeWidth: 1,
                    dashArray: value == 0 ? null : [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: interval,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(compact.format(value),
                            style: axisStyle, maxLines: 1, softWrap: false,
                            textAlign: TextAlign.right),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.round();
                        if (i != value || i % 2 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(month(i + 1), style: axisStyle),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => scheme.inverseSurface,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          '${month(spot.x.toInt() + 1)} ${years[spot.barIndex]}: '
                          '${formatMoney(seasons.years[years[spot.barIndex]]![spot.x.toInt()] ?? Money.zero(currency), locale: locale)}',
                          TextStyle(color: scheme.onInverseSurface, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  for (final (i, year) in years.indexed)
                    LineChartBarData(
                      spots: [
                        for (final (m, value) in seasons.years[year]!.indexed)
                          value == null
                              ? FlSpot.nullSpot
                              : FlSpot(m.toDouble(), toMajor(value)),
                      ],
                      color: palette[i],
                      barWidth: i == years.length - 1 ? 2.5 : 2,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      dotData: FlDotData(
                        getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                          radius: 3,
                          color: palette[i],
                          strokeWidth: 1.5,
                          strokeColor: theme.cardTheme.color ?? scheme.surface,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ shared bars

/// Vertical bars, one group per label and one bar per series, with a
/// tooltip per group. [flagged] groups get a warning mark under the label.
class _GroupedBars extends StatelessWidget {
  const _GroupedBars({
    required this.labels,
    required this.series,
    this.flagged = const {},
    this.colorFor,
  });

  final List<String> labels;
  final List<(String, Color, List<Money>)> series;
  final Set<int> flagged;
  final Color Function(int index, Color base)? colorFor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = context.localeTag;
    final axisStyle =
        theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final compact = NumberFormat.compact(locale: locale);
    final values = [for (final (_, _, list) in series) ...list.map(toMajor)];
    final maxValue = values.fold<double>(0, (m, v) => v > m ? v : m);
    final minValue = values.fold<double>(0, (m, v) => v < m ? v : m);
    final interval = niceStep(
      (maxValue - minValue) == 0 ? 1 : (maxValue - minValue) / 4,
    );
    final maxY = (maxValue / interval).ceil() * interval;
    final minY = (minValue / interval).floor() * interval;

    return SizedBox(
      height: 190,
      child: LayoutBuilder(builder: (context, constraints) {
        final groupWidth = (constraints.maxWidth - 44) / labels.length;
        final rodWidth = (groupWidth * 0.6 / series.length).clamp(4.0, 18.0);
        return BarChart(
          BarChartData(
            maxY: maxY == 0 ? interval : maxY,
            minY: minY,
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (value) => FlLine(
                color: scheme.outlineVariant,
                strokeWidth: 1,
                dashArray: value == 0 ? null : [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              for (var i = 0; i < labels.length; i++)
                BarChartGroupData(
                  x: i,
                  barsSpace: 2,
                  barRods: [
                    for (final (_, color, list) in series)
                      BarChartRodData(
                        toY: toMajor(list[i]),
                        color: colorFor?.call(i, color) ?? color,
                        width: rodWidth,
                        borderRadius: list[i].isNegative
                            ? BorderRadius.vertical(bottom: Radius.circular(rodWidth / 3))
                            : BorderRadius.vertical(top: Radius.circular(rodWidth / 3)),
                      ),
                  ],
                ),
            ],
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  interval: interval,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(compact.format(value),
                        style: axisStyle, maxLines: 1, softWrap: false,
                        textAlign: TextAlign.right),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: flagged.isEmpty ? 26 : 42,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(labels[i], style: axisStyle),
                          if (flagged.contains(i))
                            Icon(Icons.warning_amber_rounded,
                                size: 14, color: scheme.error),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => scheme.inverseSurface,
                tooltipBorderRadius: BorderRadius.circular(10),
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (rodIndex != 0) return null;
                  final style = TextStyle(
                    color: scheme.onInverseSurface,
                    fontSize: 12,
                    height: 1.5,
                  );
                  return BarTooltipItem(
                    '${labels[group.x]}\n',
                    style.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.left,
                    children: [
                      TextSpan(
                        text: [
                          for (final (name, _, list) in series)
                            '$name  ${formatMoney(list[group.x], locale: locale, signed: list[group.x].isNegative)}',
                        ].join('\n'),
                        style: style,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}
