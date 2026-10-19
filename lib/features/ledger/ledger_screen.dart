import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/labels.dart';
import '../../app/load_error.dart';
import '../../app/providers.dart';
import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';
import '../../data/database.dart';
import '../../data/ledger_repository.dart';
import '../../domain/enums.dart';
import '../../finance_core/ledger_math.dart';
import '../../finance_core/reports.dart';
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
    // The dashboard can set a search; show it in the box.
    ref.listen(ledgerFilterProvider, (_, next) {
      if (next.query != _search.text) _search.text = next.query;
    });

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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
          _ActiveFilters(filter: filter, onChanged: _update),
          const Divider(height: 1),
          Expanded(
            child: entries.hasError && !entries.hasValue
                ? const LoadError()
                : entries.when(
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
              error: (_, _) => const LoadError(),
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

  Future<void> _pickRange(BuildContext context) async {
    final today = dateOnly(DateTime.now());
    final picked = await showModalBottomSheet<_RangeChoice>(
      context: context,
      showDragHandle: true,
      builder: (_) => _DateRangeSheet(current: filter.range, today: today),
    );
    if (picked == null || !context.mounted) return;
    var range = picked.range;
    if (picked.custom) {
      final current = filter.range;
      final dates = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: today,
        initialDateRange: current == null || current.start.isAfter(today)
            ? null
            : DateTimeRange(
                start: current.start,
                end: addDays(current.end, -1).isAfter(today)
                    ? today
                    : addDays(current.end, -1),
              ),
      );
      if (dates == null) return;
      range = DateRange(dates.start, addDays(dates.end, 1));
    }
    onChanged((f) => f.copyWith(range: () => range));
  }

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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilterChip(
              avatar: const Icon(Icons.date_range, size: 18),
              label: Text(
                filter.range == null
                    ? l10n.date
                    : context.rangeLabel(filter.range!),
              ),
              selected: filter.range != null,
              showCheckmark: false,
              onSelected: (_) => _pickRange(context),
              onDeleted: filter.range == null
                  ? null
                  : () => onChanged((f) => f.copyWith(range: () => null)),
            ),
          ),
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
            label: Text(l10n.voided),
            selected: filter.voidedOnly,
            onSelected: (value) =>
                onChanged((f) => f.copyWith(voidedOnly: value)),
          ),
        ],
      ),
    );
  }
}

/// What was chosen in [_DateRangeSheet]: a fixed range, no range (all
/// dates), or [custom] to pick dates on a calendar.
class _RangeChoice {
  const _RangeChoice(this.range, {this.custom = false});
  final DateRange? range;
  final bool custom;
}

class _DateRangeSheet extends StatelessWidget {
  const _DateRangeSheet({required this.current, required this.today});

  final DateRange? current;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tomorrow = addDays(today, 1);
    // Ranges stop at today, so the dates shown never run into the future.
    DateRange upToToday(DateRange r) =>
        r.end.isAfter(tomorrow) ? DateRange(r.start, tomorrow) : r;
    final presets = <(String, DateRange?)>[
      (l10n.filterAll, null),
      (l10n.today, DateRange(today, tomorrow)),
      for (final r in [
        ReportRange.thisMonth,
        ReportRange.lastMonth,
        ReportRange.last3Months,
        ReportRange.thisYear,
      ])
        (l10n.reportRangeLabel(r), upToToday(r.rangeFor(today))),
    ];
    final isPreset = presets.any((p) => p.$2 == current);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                l10n.date,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final (label, range) in presets)
              ListTile(
                title: Text(label),
                // Today needs no dates under it.
                subtitle: range == null || addDays(range.start, 1) == range.end
                    ? null
                    : Text(context.rangeLabel(range)),
                trailing: range == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, _RangeChoice(range)),
              ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(l10n.pickDates),
              subtitle: isPreset ? null : Text(context.rangeLabel(current!)),
              trailing: isPreset ? null : const Icon(Icons.check),
              onTap: () => Navigator.pop(
                context,
                const _RangeChoice(null, custom: true),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Chips for filters set from elsewhere (e.g. dashboard drill-down) that the
/// filter bar doesn't show, so the user can see and remove them.
class _ActiveFilters extends ConsumerWidget {
  const _ActiveFilters({required this.filter, required this.onChanged});

  final LedgerFilter filter;
  final void Function(LedgerFilter Function(LedgerFilter)) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (filter.categoryId == null) {
      return const SizedBox.shrink();
    }
    final categories = ref.watch(categoriesByIdProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (filter.categoryId != null)
            InputChip(
              avatar: const Icon(Icons.label_outline, size: 18),
              label: Text(context.categoryName(categories[filter.categoryId])),
              onDeleted: () =>
                  onChanged((f) => f.copyWith(categoryId: () => null)),
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
    final dayRange = DateRange(fromDateKey(day), addDays(fromDateKey(day), 1));
    final summary = summarize(rows.map(toLedgerEntry), dayRange);
    final totals = summary.byCurrency.values
        .map((t) => formatMoney(t.netCashFlow,
            locale: context.localeTag, signed: true))
        .join('  ·  ');
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    // A light text heading instead of a filled band.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
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
