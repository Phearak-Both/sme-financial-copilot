/// Deterministic financial calculations over ledger entries.
///
/// This is the single place where totals are computed. Home, the ledger and
/// (later) reports and the AI assistant all read numbers from here, so every
/// screen shows the same figures. Totals are always kept per currency.
library;

import '../core/date_only.dart';
import '../core/money/currency.dart';
import '../core/money/money.dart';
import '../domain/enums.dart';

/// The minimal view of an entry that calculations need.
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.occurredOn,
    required this.status,
    this.categoryId,
    this.description = '',
  });

  final String id;
  final EntryType type;
  final int amountMinor;
  final Currency currency;

  /// `yyyy-MM-dd`.
  final String occurredOn;
  final EntryStatus status;
  final String? categoryId;
  final String description;
}

/// Totals for one currency over one period.
class CurrencyTotals {
  const CurrencyTotals({
    required this.currency,
    required this.income,
    required this.expense,
    required this.ownerContribution,
    required this.ownerWithdrawal,
    required this.entryCount,
  });

  factory CurrencyTotals.empty(Currency currency) => CurrencyTotals(
        currency: currency,
        income: Money.zero(currency),
        expense: Money.zero(currency),
        ownerContribution: Money.zero(currency),
        ownerWithdrawal: Money.zero(currency),
        entryCount: 0,
      );

  final Currency currency;
  final Money income;
  final Money expense;
  final Money ownerContribution;
  final Money ownerWithdrawal;
  final int entryCount;

  /// Cash-basis profit: business income minus business expenses.
  /// Owner contributions and withdrawals are excluded.
  Money get profit => income - expense;

  /// Net change in cash, including owner contributions and withdrawals.
  Money get netCashFlow =>
      income + ownerContribution - expense - ownerWithdrawal;

  CurrencyTotals _add(LedgerEntry entry) {
    final amount = Money(entry.amountMinor, currency);
    return CurrencyTotals(
      currency: currency,
      income: entry.type == EntryType.income ? income + amount : income,
      expense: entry.type == EntryType.expense ? expense + amount : expense,
      ownerContribution: entry.type == EntryType.ownerContribution
          ? ownerContribution + amount
          : ownerContribution,
      ownerWithdrawal: entry.type == EntryType.ownerWithdrawal
          ? ownerWithdrawal + amount
          : ownerWithdrawal,
      entryCount: entryCount + 1,
    );
  }
}

/// Summary of a period, keyed by currency. Only currencies that have at least
/// one active entry in the period appear.
class PeriodSummary {
  const PeriodSummary(this.range, this.byCurrency);

  final DateRange range;
  final Map<Currency, CurrencyTotals> byCurrency;

  bool get isEmpty => byCurrency.isEmpty;
  int get entryCount =>
      byCurrency.values.fold(0, (sum, totals) => sum + totals.entryCount);
}

bool _counts(LedgerEntry entry, DateRange range) =>
    entry.status == EntryStatus.active && range.containsKey(entry.occurredOn);

/// Summarises active entries that fall inside [range]. Voided entries are
/// ignored.
PeriodSummary summarize(Iterable<LedgerEntry> entries, DateRange range) {
  final totals = <Currency, CurrencyTotals>{};
  for (final entry in entries) {
    if (!_counts(entry, range)) continue;
    final current =
        totals[entry.currency] ?? CurrencyTotals.empty(entry.currency);
    totals[entry.currency] = current._add(entry);
  }
  final ordered = {
    for (final currency in Currency.values)
      if (totals[currency] != null) currency: totals[currency]!,
  };
  return PeriodSummary(range, ordered);
}

/// Business expenses in [range] grouped by category, per currency, largest
/// first. Entries without a category are grouped under a null key.
Map<Currency, List<MapEntry<String?, Money>>> expensesByCategory(
  Iterable<LedgerEntry> entries,
  DateRange range,
) {
  final grouped = <Currency, Map<String?, int>>{};
  for (final entry in entries) {
    if (entry.type != EntryType.expense || !_counts(entry, range)) continue;
    final perCategory = grouped.putIfAbsent(entry.currency, () => {});
    perCategory[entry.categoryId] =
        (perCategory[entry.categoryId] ?? 0) + entry.amountMinor;
  }
  return {
    for (final MapEntry(key: currency, value: perCategory) in grouped.entries)
      currency: perCategory.entries
          .map((e) => MapEntry(e.key, Money(e.value, currency)))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
  };
}
