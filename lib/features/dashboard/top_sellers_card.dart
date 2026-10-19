import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../domain/enums.dart';
import '../../finance_core/insights.dart';
import '../../finance_core/period_math.dart';
import '../../finance_core/sales.dart';
import 'chart_style.dart';
import 'dashboard_screen.dart';

/// Which items bring in the most income in the selected period: a donut of
/// each item's share of income, and a ranked list with each one's change
/// against the comparison period.
class TopSellersCard extends ConsumerWidget {
  const TopSellersCard(this.data, {super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = context.localeTag;
    final items = data.topSellers;
    if (items.isEmpty) {
      return ChartCard(
        title: l10n.topSellersTitle,
        child: Text(l10n.topSellersEmpty),
      );
    }

    // One colour per item, in a fixed order. The rest, and income recorded
    // without a description, fold into Other so the donut adds up to all
    // income.
    final income = data.current.income;
    final palette = seriesColors(context);
    final shown = items.length <= palette.length
        ? items
        : items.take(palette.length - 1).toList();
    final otherItems = items.length - shown.length;
    final other = shown.fold(income, (left, item) => left - item.total);
    final top = items.first;

    // The item that grew most, if it is a real rise and not the top item.
    SalesItem? rising;
    int? risingPercent;
    for (final item in shown.skip(1)) {
      final p = percentChange(item.total, item.previous);
      if (p != null && p >= 20 && (risingPercent == null || p > risingPercent)) {
        rising = item;
        risingPercent = p;
      }
    }

    return ChartCard(
      title: l10n.topSellersTitle,
      subtitle: l10n.topSellersSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChartNote(
            text: l10n.topSellerShare(
              top.name,
              '${roundedPercent(top.total.minor, income.minor)}',
            ),
          ),
          if (rising != null) ...[
            const SizedBox(height: 8),
            ChartNote(
              text: l10n.topSellerRising(rising.name, '+$risingPercent%'),
            ),
          ],
          const SizedBox(height: 16),
          DonutChart(
            slices: [
              for (final (i, item) in shown.indexed)
                DonutSlice(item.name, item.total, palette[i]),
              if (other.minor > 0)
                DonutSlice(l10n.chartOther, other, otherColor(context)),
            ],
            total: income,
            totalLabel: l10n.incomeTotal,
          ),
          const SizedBox(height: 12),
          for (final (i, item) in shown.indexed)
            _SellerRow(
              color: palette[i],
              item: item,
              income: income,
              onTap: () => openLedgerFor(context, ref,
                  data: data, type: EntryType.income, query: item.name),
            ),
          if (other.minor > 0)
            _OtherRow(
              color: otherColor(context),
              label: otherItems > 0
                  ? l10n.otherItems(NumberFormat('0', locale).format(otherItems))
                  : l10n.chartOther,
              amount: other,
              income: income,
            ),
        ],
      ),
    );
  }
}

class _SellerRow extends ConsumerWidget {
  const _SellerRow({
    required this.color,
    required this.item,
    required this.income,
    required this.onTap,
  });

  final Color color;
  final SalesItem item;
  final Money income;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = context.localeTag;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final change = percentChange(item.total, item.previous);
    final (changeText, changeColor, changeIcon) = switch (change) {
      null => (l10n.usualNew, scheme.primary, Icons.auto_awesome_outlined),
      > 0 => ('+$change%', MoneyColors.moneyIn(context), Icons.arrow_upward_rounded),
      < 0 => ('$change%', MoneyColors.moneyOut(context), Icons.arrow_downward_rounded),
      _ => ('0%', scheme.onSurfaceVariant, Icons.remove_rounded),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _Swatch(color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${roundedPercent(item.total.minor, income.minor)}%',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatMoney(item.total, locale: locale),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.salesCount(NumberFormat('0', locale).format(item.count)),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                      Icon(changeIcon, size: 14, color: changeColor),
                      const SizedBox(width: 2),
                      Text(
                        changeText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: changeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherRow extends StatelessWidget {
  const _OtherRow({
    required this.color,
    required this.label,
    required this.amount,
    required this.income,
  });

  final Color color;
  final String label;
  final Money amount;
  final Money income;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          _Swatch(color),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(
            '${roundedPercent(amount.minor, income.minor)}%',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Text(
            formatMoney(amount, locale: context.localeTag),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      );
}
