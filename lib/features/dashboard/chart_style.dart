import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/labels.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../finance_core/insights.dart';

/// Categorical colours for chart series, assigned in this fixed order and
/// never cycled. Light and dark steps are separate, validated sets; the
/// dark ones are stepped for dark surfaces rather than flipped.
const _seriesLight = [
  Color(0xFF2A78D6), // blue
  Color(0xFFEB6834), // orange
  Color(0xFF1BAF7A), // aqua
  Color(0xFFEDA100), // yellow
  Color(0xFFE87BA4), // magenta
  Color(0xFF008300), // green
];
const _seriesDark = [
  Color(0xFF3987E5),
  Color(0xFFD95926),
  Color(0xFF199E70),
  Color(0xFFC98500),
  Color(0xFFD55181),
  Color(0xFF008300),
];

/// Series colours for the current theme. Callers fold anything past the
/// last slot into "Other".
List<Color> seriesColors(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? _seriesDark : _seriesLight;

/// Grey for "Other" and other de-emphasised marks.
Color otherColor(BuildContext context) =>
    Theme.of(context).colorScheme.outline;

/// Major units as a double, only for drawing; text always uses formatMoney.
double toMajor(Money m) {
  var factor = 1;
  for (var i = 0; i < m.currency.exponent; i++) {
    factor *= 10;
  }
  return m.minor / factor;
}

/// The smallest 1, 2, 2.5 or 5 × 10ⁿ that is at least [raw].
double niceStep(double raw) {
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

/// A card with a title, an optional explanation and a body.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    this.subtitle,
    this.legend,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? legend;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                ?legend,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// A coloured dot and its label.
class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});

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

/// A row of [LegendDot]s.
class Legend extends StatelessWidget {
  const Legend(this.items, {super.key});

  final List<(Color, String)> items;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 14,
        runSpacing: 4,
        children: [
          for (final (color, label) in items) LegendDot(color: color, label: label),
        ],
      );
}

/// A short statement under a chart, with an icon so tone never depends on
/// colour alone.
class ChartNote extends StatelessWidget {
  const ChartNote({
    super.key,
    required this.text,
    this.warning = false,
  });

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = warning ? scheme.error : scheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.lightbulb_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// One slice of a [DonutChart].
class DonutSlice {
  const DonutSlice(this.label, this.amount, this.color);

  final String label;
  final Money amount;
  final Color color;
}

/// A donut with [total] in the middle. Touching a slice shows its label,
/// amount and share there instead.
class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.total,
    required this.totalLabel,
  });

  final List<DonutSlice> slices;
  final Money total;
  final String totalLabel;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.localeTag;
    final slices = widget.slices;
    final touched =
        _touched != null && _touched! < slices.length ? slices[_touched!] : null;

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              centerSpaceRadius: 64,
              sectionsSpace: 2,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  final index = response?.touchedSection?.touchedSectionIndex;
                  setState(() => _touched =
                      event.isInterestedForInteractions && index != null && index >= 0
                          ? index
                          : null);
                },
              ),
              sections: [
                for (final (i, slice) in slices.indexed)
                  PieChartSectionData(
                    value: toMajor(slice.amount),
                    color: slice.color,
                    radius: _touched == i ? 30 : 24,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  touched?.label ?? widget.totalLabel,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  formatMoney(touched?.amount ?? widget.total, locale: locale),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (touched != null)
                  Text(
                    '${roundedPercent(touched.amount.minor, widget.total.minor)}%',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
