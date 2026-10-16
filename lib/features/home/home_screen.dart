import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../domain/enums.dart';
import '../../finance_core/ledger_math.dart';
import '../ledger/entry_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(thisMonthSummaryProvider);
    final recent = ref.watch(recentEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          summary.when(
            data: (s) => s.isEmpty ? const _EmptySummary() : _SummaryCard(s),
            loading: () => const _CardPlaceholder(),
            error: (_, _) => Text(l10n.somethingWrong),
          ),
          const SizedBox(height: 16),
          const _QuickActions(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(l10n.recent,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              TextButton(
                onPressed: () => context.go('/ledger'),
                child: Text(l10n.viewAll),
              ),
            ],
          ),
          recent.when(
            data: (entries) => Column(
              children: [
                for (final entry in entries)
                  EntryTile(entry: entry, showDate: true),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => Text(l10n.somethingWrong),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.push('/entry/new?type=${EntryType.income.name}'),
            icon: const Icon(Icons.add),
            label: Text(l10n.moneyIn),
            style: FilledButton.styleFrom(
              backgroundColor: MoneyColors.moneyIn(context),
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.push('/entry/new?type=${EntryType.expense.name}'),
            icon: const Icon(Icons.remove),
            label: Text(l10n.moneyOut),
            style: FilledButton.styleFrom(
              backgroundColor: MoneyColors.moneyOut(context),
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.summary);

  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(l10n.thisMonth, style: textTheme.titleMedium)),
                Text(l10n.entriesCount(summary.entryCount),
                    style: textTheme.bodySmall),
              ],
            ),
            for (final totals in summary.byCurrency.values) ...[
              const Divider(height: 24),
              _CurrencyTotalsView(totals),
            ],
            const SizedBox(height: 12),
            Text(l10n.summaryFootnote, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CurrencyTotalsView extends StatelessWidget {
  const _CurrencyTotalsView(this.totals);

  final CurrencyTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeTag;
    String fmt(Money m, {bool signed = false}) =>
        formatMoney(m, locale: locale, signed: signed);
    final hasOwnerMovements =
        !totals.ownerContribution.isZero || !totals.ownerWithdrawal.isZero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Chip(
          label: Text(totals.currency.code),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(height: 8),
        _Line(l10n.moneyIn, fmt(totals.income),
            color: MoneyColors.moneyIn(context)),
        _Line(l10n.moneyOut, fmt(totals.expense),
            color: MoneyColors.moneyOut(context)),
        _Line(l10n.profitCash, fmt(totals.profit, signed: true), emphasize: true),
        if (hasOwnerMovements)
          _Line(
            l10n.ownerMovements,
            '+${fmt(totals.ownerContribution)} / -${fmt(totals.ownerWithdrawal)}',
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.color, this.emphasize = false});

  final String label;
  final String value;
  final Color? color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = emphasize ? textTheme.titleLarge : textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyLarge)),
          Text(value,
              style: style?.copyWith(
                color: color,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

class _EmptySummary extends StatelessWidget {
  const _EmptySummary();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.menu_book_outlined,
                size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(l10n.homeEmptyTitle, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.homeEmptyBody,
                textAlign: TextAlign.center, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder();

  @override
  Widget build(BuildContext context) =>
      const Card(child: SizedBox(height: 160));
}
