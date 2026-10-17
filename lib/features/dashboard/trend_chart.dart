import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/labels.dart';
import '../../core/date_only.dart';
import '../../core/money/currency.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../finance_core/period_math.dart';

/// Money in vs money out per week or month, for one currency.
///
/// The chart library needs doubles. They are derived from the integer totals
/// only for drawing; every number shown as text comes from [formatMoney].
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.buckets, required this.currency});

  final List<TrendBucket> buckets;
  final Currency currency;

  double _major(Money m) {
    var factor = 1;
    for (var i = 0; i < currency.exponent; i++) {
      factor *= 10;
    }
    return m.minor / factor;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeTag;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inColor = MoneyColors.moneyIn(context);
    final outColor = MoneyColors.moneyOut(context);
    final axisStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final compact = NumberFormat.compact(locale: locale);

    final maxValue = buckets.fold<double>(
      0,
      (m, t) => [m, _major(t.income), _major(t.expense)].reduce(
        (a, b) => a > b ? a : b,
      ),
    );
    // Four evenly spaced grid lines on a rounded-up scale.
    final interval = _niceStep(maxValue == 0 ? 1 : maxValue / 4);
    final maxY = interval * 4;
    // Wide enough for the longest axis label, e.g. Khmer "១ ពាន់".
    final axisWidth = [
      for (var i = 0; i <= 4; i++)
        (TextPainter(
          text: TextSpan(text: compact.format(interval * i), style: axisStyle),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout()).width,
    ].reduce((a, b) => a > b ? a : b).ceilToDouble() + 10;
    // With many months (this year), label every third one so names fit.
    final labelEvery = buckets.length > 6 ? 3 : 1;

    return Semantics(
      label: l10n.trendSemantics,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l10n.trendTitle, style: theme.textTheme.titleMedium),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Legend(color: inColor, label: l10n.moneyIn),
                      const SizedBox(width: 14),
                      _Legend(color: outColor, label: l10n.moneyOut),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 190,
                child: LayoutBuilder(builder: (context, constraints) {
                  // Two rods per group take about 60% of the group's width.
                  final groupWidth =
                      (constraints.maxWidth - axisWidth) / buckets.length;
                  final rodWidth = (groupWidth * 0.3).clamp(4.0, 18.0);
                  final rodRadius = BorderRadius.vertical(
                    top: Radius.circular(rodWidth / 3),
                  );
                  return BarChart(
                    BarChartData(
                      maxY: maxY,
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
                        for (final (i, bucket) in buckets.indexed)
                          BarChartGroupData(
                            x: i,
                            barsSpace: rodWidth / 4,
                            barRods: [
                              BarChartRodData(
                                toY: _major(bucket.income),
                                color: inColor,
                                width: rodWidth,
                                borderRadius: rodRadius,
                              ),
                              BarChartRodData(
                                toY: _major(bucket.expense),
                                color: outColor,
                                width: rodWidth,
                                borderRadius: rodRadius,
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
                            reservedSize: axisWidth,
                            interval: interval,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                compact.format(value),
                                style: axisStyle,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 ||
                                  index >= buckets.length ||
                                  index % labelEvery != 0) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _label(buckets[index].range, locale),
                                  style: axisStyle,
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
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          // One tooltip per group, showing both amounts.
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (rodIndex != 0) return null;
                            final bucket = buckets[group.x];
                            final style = TextStyle(
                              color: scheme.onInverseSurface,
                              fontSize: 12,
                              height: 1.5,
                            );
                            return BarTooltipItem(
                              '${_label(bucket.range, locale)}\n',
                              style.copyWith(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.left,
                              children: [
                                TextSpan(
                                  text:
                                      '${l10n.moneyIn}  '
                                      '${formatMoney(bucket.income, locale: locale)}\n'
                                      '${l10n.moneyOut}  '
                                      '${formatMoney(bucket.expense, locale: locale)}',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The smallest 1, 2, 2.5 or 5 × 10ⁿ that is at least [raw].
double _niceStep(double raw) {
  var magnitude = 1.0;
  while (magnitude * 10 <= raw) {
    magnitude *= 10;
  }
  while (magnitude > raw) {
    magnitude /= 10;
  }
  for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    if (m * magnitude >= raw) return m * magnitude;
  }
  return 10 * magnitude;
}

/// `Oct` for a whole month, `1-7` for a week (days within the month).
String _label(DateRange range, String locale) {
  if (DateRange.monthOf(range.start) == range) {
    return DateFormat.MMM(locale).format(range.start);
  }
  final days = NumberFormat('0', locale);
  final last = addDays(range.end, -1);
  return '${days.format(range.start.day)}-${days.format(last.day)}';
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
