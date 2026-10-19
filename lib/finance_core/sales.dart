/// What sells: income grouped by what was sold.
///
/// The ledger has no separate item field, so an item is the entry's
/// description ("Rice", "Drinks"), matched without regard to case or extra
/// spaces. Like the rest of `finance_core`, this is per currency and exact.
library;

import '../core/date_only.dart';
import '../core/money/currency.dart';
import '../core/money/money.dart';
import '../domain/enums.dart';
import 'ledger_math.dart';

/// Income from one item over a period.
class SalesItem {
  const SalesItem({
    required this.name,
    required this.categoryId,
    required this.total,
    required this.count,
    required this.previous,
  });

  /// The description as last written.
  final String name;

  /// The category most of its income was recorded under.
  final String? categoryId;
  final Money total;

  /// Number of entries.
  final int count;

  /// Income from the same item in the comparison period.
  final Money previous;
}

/// Items in [range], highest income first, compared with [comparison].
/// Income without a description isn't an item and is left out.
List<SalesItem> topSellers(
  Iterable<LedgerEntry> entries,
  Currency currency,
  DateRange range,
  DateRange comparison,
) {
  final totals = <String, int>{};
  final counts = <String, int>{};
  final before = <String, int>{};
  final names = <String, LedgerEntry>{};
  final categories = <String, Map<String?, int>>{};

  for (final e in entries) {
    if (e.currency != currency ||
        e.type != EntryType.income ||
        e.status != EntryStatus.active) {
      continue;
    }
    final name = e.description.trim();
    if (name.isEmpty) continue;
    final key = name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (comparison.containsKey(e.occurredOn)) {
      before[key] = (before[key] ?? 0) + e.amountMinor;
    }
    if (!range.containsKey(e.occurredOn)) continue;
    totals[key] = (totals[key] ?? 0) + e.amountMinor;
    counts[key] = (counts[key] ?? 0) + 1;
    final latest = names[key];
    if (latest == null || e.occurredOn.compareTo(latest.occurredOn) >= 0) {
      names[key] = e;
    }
    final byCategory = categories.putIfAbsent(key, () => {});
    byCategory[e.categoryId] = (byCategory[e.categoryId] ?? 0) + e.amountMinor;
  }

  return [
    for (final MapEntry(:key, :value) in totals.entries)
      SalesItem(
        name: names[key]!.description.trim(),
        categoryId: categories[key]!.entries
            .reduce((a, b) => b.value > a.value ? b : a)
            .key,
        total: Money(value, currency),
        count: counts[key]!,
        previous: Money(before[key] ?? 0, currency),
      ),
  ]..sort((a, b) {
      final byTotal = b.total.compareTo(a.total);
      return byTotal != 0 ? byTotal : a.name.compareTo(b.name);
    });
}
