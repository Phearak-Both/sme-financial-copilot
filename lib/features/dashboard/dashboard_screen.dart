import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/labels.dart';
import '../../app/load_error.dart';
import '../../app/providers.dart';
import '../../core/money/currency.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../data/ledger_repository.dart';
import '../../domain/enums.dart';
import '../../finance_core/period_math.dart';
import '../../finance_core/insights.dart';
import 'cash_balance_card.dart';
import 'expense_donut.dart';
import 'insights_card.dart';
import 'patterns_section.dart';
import 'top_sellers_card.dart';
import 'trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final period = ref.watch(dashboardPeriodProvider);
    final currency = ref.watch(dashboardCurrencyProvider);
    final data = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navDashboard)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in ReportPeriod.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(l10n.periodLabel(p)),
                      selected: p == period,
                      onSelected: (_) =>
                          ref.read(dashboardPeriodProvider.notifier).set(p),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<Currency>(
            segments: [
              for (final c in Currency.values)
                ButtonSegment(value: c, label: Text(c.code)),
            ],
            selected: {currency},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                ref.read(dashboardCurrencyProvider.notifier).set(s.first),
          ),
          const SizedBox(height: 16),
          CashBalanceCard(
            currency: currency,
            runway: data.value?.insights
                .where((i) => i is RunwayInsight || i is RunwayStatusInsight)
                .firstOrNull,
          ),
          const SizedBox(height: 16),
          if (data.hasError && !data.hasValue)
            const LoadError()
          else
          data.when(
            data: (d) => d.isEmpty ? _EmptyPeriod(d) : _DashboardBody(d),
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const LoadError(),
          ),
          const SizedBox(height: 32),
          const PatternsSection(),
          const SizedBox(height: 16),
          Text(l10n.dashboardFootnote, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Opens the ledger filtered to what a dashboard figure was computed from.
void openLedgerFor(
  BuildContext context,
  WidgetRef ref, {
  required DashboardData data,
  EntryType? type,
  String? categoryId,
  String query = '',
}) {
  ref.read(ledgerFilterProvider.notifier).set(LedgerFilter(
        query: query,
        currency: data.currency,
        range: data.range,
        type: type,
        categoryId: categoryId,
      ));
  context.go('/ledger');
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody(this.data);

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = data.current;
    final previous = data.previous;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _KpiCard(
                label: l10n.moneyIn,
                value: current.income,
                color: MoneyColors.moneyIn(context),
                change: _ChangeInfo(current.income, previous.income, data),
                onTap: () => openLedgerFor(context, ref,
                    data: data, type: EntryType.income),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: l10n.moneyOut,
                value: current.expense,
                color: MoneyColors.moneyOut(context),
                change: _ChangeInfo(current.expense, previous.expense, data),
                onTap: () => openLedgerFor(context, ref,
                    data: data, type: EntryType.expense),
              ),
            ),
          ],
        ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _KpiCard(
                label: l10n.profitCash,
                value: current.profit,
                signed: true,
                onTap: () => openLedgerFor(context, ref, data: data),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: l10n.netCashFlow,
                value: current.netCashFlow,
                signed: true,
                onTap: () => openLedgerFor(context, ref, data: data),
              ),
            ),
          ],
        ),
        ),
        const SizedBox(height: 16),
        InsightsCard(data),
        const SizedBox(height: 16),
        TrendChart(buckets: data.trend, currency: data.currency),
        const SizedBox(height: 16),
        TopSellersCard(data),
        const SizedBox(height: 16),
        ExpenseDonut(data),
      ],
    );
  }
}

class _ChangeInfo {
  const _ChangeInfo(this.current, this.previous, this.data);

  final Money current;
  final Money previous;
  final DashboardData data;

  String describe(BuildContext context) {
    final l10n = context.l10n;
    final percent = percentChange(current, previous);
    if (percent == null) return l10n.noComparison;
    final change = '${percent > 0 ? '+' : ''}$percent%';
    // A period still in progress is compared with the same elapsed days.
    final inProgress = elapsedPart(data.range, DateTime.now()) != data.range;
    return inProgress ? l10n.vsComparison(change) : l10n.vsComparisonFull(change);
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    this.color,
    this.change,
    this.signed = false,
    this.onTap,
  });

  final String label;
  final Money value;
  final Color? color;
  final _ChangeInfo? change;
  final bool signed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.bodyMedium),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatMoney(value, locale: context.localeTag, signed: signed),
                  style: textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (change != null) ...[
                const SizedBox(height: 4),
                Text(change!.describe(context), style: textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPeriod extends ConsumerWidget {
  const _EmptyPeriod(this.data);

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final others = data.currenciesWithData.where((c) => c != data.currency);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.insights_outlined,
                size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(l10n.dashboardEmpty(data.currency.code), textAlign: TextAlign.center),
            for (final other in others) ...[
              const SizedBox(height: 8),
              Text(l10n.otherCurrencyHint(other.code), textAlign: TextAlign.center),
              TextButton(
                onPressed: () =>
                    ref.read(dashboardCurrencyProvider.notifier).set(other),
                child: Text(l10n.showCurrency(other.code)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
