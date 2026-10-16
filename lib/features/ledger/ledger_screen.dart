import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';
import '../../data/database.dart';
import '../../data/ledger_repository.dart';
import '../../domain/enums.dart';
import '../../finance_core/ledger_math.dart';
import '../../core/date_only.dart';
import 'entry_tile.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  late final TextEditingController _search = TextEditingController(
    text: ref.read(ledgerFilterProvider).query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _update(LedgerFilter Function(LedgerFilter) change) {
    final notifier = ref.read(ledgerFilterProvider.notifier);
    notifier.set(change(ref.read(ledgerFilterProvider)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = ref.watch(ledgerFilterProvider);
    final entries = ref.watch(ledgerEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navLedger)),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newEntry,
        onPressed: () =>
            context.push('/entry/new?type=${EntryType.expense.name}'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => _update((f) => f.copyWith(query: value)),
            ),
          ),
          _FilterBar(filter: filter, onChanged: _update),
          const Divider(height: 1),
          Expanded(
            child: entries.when(
              data: (rows) => rows.isEmpty
                  ? _EmptyLedger(
                      filtered: !filter.isDefault,
                      onClear: () {
                        _search.clear();
                        ref
                            .read(ledgerFilterProvider.notifier)
                            .set(const LedgerFilter());
                      },
                    )
                  : _GroupedList(rows),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(l10n.somethingWrong)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.onChanged});

  final LedgerFilter filter;
  final void Function(LedgerFilter Function(LedgerFilter)) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onTap(),
          ),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          chip(l10n.filterAll, filter.type == null,
              () => onChanged((f) => f.copyWith(type: () => null))),
          for (final type in EntryType.values)
            chip(l10n.entryType(type), filter.type == type,
                () => onChanged((f) => f.copyWith(type: () => type))),
          const SizedBox(width: 8),
          chip('USD + KHR', filter.currency == null,
              () => onChanged((f) => f.copyWith(currency: () => null))),
          for (final currency in Currency.values)
            chip(currency.code, filter.currency == currency,
                () => onChanged((f) => f.copyWith(currency: () => currency))),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(l10n.showVoided),
            selected: filter.includeVoided,
            onSelected: (value) =>
                onChanged((f) => f.copyWith(includeVoided: value)),
          ),
        ],
      ),
    );
  }
}

/// Entries grouped by day, with each day's net cash flow per currency.
class _GroupedList extends StatelessWidget {
  const _GroupedList(this.rows);

  final List<EntryRow> rows;

  @override
  Widget build(BuildContext context) {
    final days = <String, List<EntryRow>>{};
    for (final row in rows) {
      days.putIfAbsent(row.occurredOn, () => []).add(row);
    }
    final items = <Widget>[
      for (final MapEntry(key: day, value: dayRows) in days.entries) ...[
        _DayHeader(day: day, rows: dayRows),
        for (final row in dayRows) EntryTile(entry: row),
      ],
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: items,
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.rows});

  final String day;
  final List<EntryRow> rows;

  @override
  Widget build(BuildContext context) {
    final dayRange = DateRange(
      fromDateKey(day),
      fromDateKey(day).add(const Duration(days: 1)),
    );
    final summary = summarize(rows.map(toLedgerEntry), dayRange);
    final totals = summary.byCurrency.values
        .map((t) => formatMoney(t.netCashFlow,
            locale: context.localeTag, signed: true))
        .join('  ·  ');
    final style = Theme.of(context).textTheme.labelLarge;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(context.dayLabel(day), style: style)),
          Text(totals, style: style),
        ],
      ),
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger({required this.filtered, required this.onClear});

  final bool filtered;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filtered ? l10n.ledgerEmptyFiltered : l10n.ledgerEmpty,
              textAlign: TextAlign.center,
            ),
            if (filtered)
              TextButton(onPressed: onClear, child: Text(l10n.clearFilters)),
          ],
        ),
      ),
    );
  }
}
