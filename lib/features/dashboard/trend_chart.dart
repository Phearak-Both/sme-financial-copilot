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
    final inColor = MoneyColors.moneyIn(context);
    final outColor = MoneyColors.moneyOut(context);
    final textStyle = Theme.of(context).textTheme.bodySmall;
    final compact = NumberFormat.compact(locale: locale);

    final maxValue = buckets.fold<double>(
      0,
      (m, t) => [m, _major(t.income), _major(t.expense)].reduce(
        (a, b) => a > b ? a : b,
      ),
    );

    return Semantics(
      label: l10n.trendSemantics,
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxValue == 0 ? 1 : maxValue * 1.15,
                gridData: const FlGridData(drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (final (i, bucket) in buckets.indexed)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 3,
                      barRods: [
                        BarChartRodData(
                          toY: _major(bucket.income),
                          color: inColor,
                          width: 10,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        BarChartRodData(
                          toY: _major(bucket.expense),
                          color: outColor,
                          width: 10,
                          borderRadius: BorderRadius.circular(2),
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
                      getTitlesWidget: (value, meta) => Text(
                        compact.format(value),
                        style: textStyle,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= buckets.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _label(buckets[index].range, locale),
                            style: textStyle,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final bucket = buckets[group.x];
                      final amount = rodIndex == 0 ? bucket.income : bucket.expense;
                      return BarTooltipItem(
                        '${rodIndex == 0 ? l10n.moneyIn : l10n.moneyOut}\n'
                        '${formatMoney(amount, locale: locale)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: inColor, label: l10n.moneyIn),
              const SizedBox(width: 16),
              _Legend(color: outColor, label: l10n.moneyOut),
            ],
          ),
        ],
      ),
    );
  }
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
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
