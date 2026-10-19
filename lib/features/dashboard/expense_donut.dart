import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../core/money/money_format.dart';
import '../../domain/enums.dart';
import '../../finance_core/insights.dart';
import 'chart_style.dart';
import 'dashboard_screen.dart';

/// Where the money went: a donut of the largest expense categories with the
/// total in the middle, and a tappable list that opens each in the ledger.
class ExpenseDonut extends ConsumerWidget {
  const ExpenseDonut(this.data, {super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.localeTag;
    final categories = ref.watch(categoriesByIdProvider);
    final rows = data.expenseCategories;
    if (rows.isEmpty) {
      return ChartCard(title: l10n.expenseBreakdown, child: Text(l10n.noExpenses));
    }

    // One colour per category, in a fixed order; the rest fold into Other.
    final palette = seriesColors(context);
    final shown = rows.take(palette.length - (rows.length > palette.length ? 1 : 0)).toList();
    final rest = rows.skip(shown.length).toList();
    final slices = [
      for (final (i, MapEntry(key: id, value: amount)) in shown.indexed)
        (DonutSlice(context.categoryName(categories[id]), amount, palette[i]), id),
      if (rest.isNotEmpty)
        (
          DonutSlice(
            l10n.chartOther,
            rest.map((e) => e.value).reduce((a, b) => a + b),
            otherColor(context),
          ),
          null,
        ),
    ];
    final total = data.current.expense;

    return ChartCard(
      title: l10n.expenseBreakdown,
      child: Column(
        children: [
          DonutChart(
            slices: [for (final (slice, _) in slices) slice],
            total: total,
            totalLabel: l10n.expenseTotal,
          ),
          const SizedBox(height: 12),
          for (final (slice, id) in slices)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => openLedgerFor(context, ref,
                  data: data, type: EntryType.expense, categoryId: id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: slice.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(slice.label)),
                    Text(
                      '${roundedPercent(slice.amount.minor, total.minor)}%',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatMoney(slice.amount, locale: locale),
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
