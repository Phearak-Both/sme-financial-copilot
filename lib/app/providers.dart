import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date_only.dart';
import '../core/money/currency.dart';
import '../core/money/money.dart';
import '../data/database.dart';
import '../data/ledger_repository.dart';
import '../finance_core/ledger_math.dart';
import '../finance_core/period_math.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final ledgerRepositoryProvider = Provider<LedgerRepository>(
  (ref) => LedgerRepository(ref.watch(databaseProvider)),
);

final categoriesProvider = StreamProvider<List<CategoryRow>>(
  (ref) => ref.watch(ledgerRepositoryProvider).watchCategories(),
);

final categoriesByIdProvider = Provider<Map<String, CategoryRow>>((ref) {
  final categories = ref.watch(categoriesProvider).value ?? const [];
  return {for (final c in categories) c.id: c};
});

// ----------------------------------------------------------------- language

const localeSettingKey = 'locale';

/// Khmer is the default language; users can switch to English in Settings.
const defaultLocale = Locale('km');
const supportedAppLocales = [Locale('km'), Locale('en')];

/// The user's chosen language, falling back to [defaultLocale].
final localeProvider = StreamProvider<Locale>(
  (ref) => ref
      .watch(ledgerRepositoryProvider)
      .watchSetting(localeSettingKey)
      .map(
        (code) => supportedAppLocales.firstWhere(
          (locale) => locale.languageCode == code,
          orElse: () => defaultLocale,
        ),
      ),
);

// ------------------------------------------------------------------- ledger

class LedgerFilterNotifier extends Notifier<LedgerFilter> {
  @override
  LedgerFilter build() => const LedgerFilter();

  void set(LedgerFilter filter) => state = filter;
}

final ledgerFilterProvider =
    NotifierProvider<LedgerFilterNotifier, LedgerFilter>(
      LedgerFilterNotifier.new,
    );

final ledgerEntriesProvider = StreamProvider<List<EntryRow>>((ref) {
  final filter = ref.watch(ledgerFilterProvider);
  return ref.watch(ledgerRepositoryProvider).watchEntries(filter);
});

final recentEntriesProvider = StreamProvider<List<EntryRow>>(
  (ref) => ref
      .watch(ledgerRepositoryProvider)
      .watchEntries(const LedgerFilter(), limit: 5),
);

final entryProvider = StreamProvider.family<EntryRow?, String>(
  (ref, id) => ref.watch(ledgerRepositoryProvider).watchEntry(id),
);

final revisionsProvider = StreamProvider.family<List<RevisionRow>, String>(
  (ref, id) => ref.watch(ledgerRepositoryProvider).watchRevisions(id),
);

// ------------------------------------------------------------- cash balance

final openingBalancesProvider = StreamProvider<List<OpeningBalance>>(
  (ref) => ref.watch(ledgerRepositoryProvider).watchOpeningBalances(),
);

/// Current cash per currency, only for currencies with an opening balance.
final cashBalancesProvider = StreamProvider<Map<Currency, Money>>((ref) async* {
  final openings = await ref.watch(openingBalancesProvider.future);
  if (openings.isEmpty) {
    yield const {};
    return;
  }
  final earliest = openings
      .map((o) => o.asOf)
      .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
  final range = DateRange(
    fromDateKey(earliest),
    addDays(dateOnly(DateTime.now()), 1),
  );
  yield* ref
      .watch(ledgerRepositoryProvider)
      .watchLedgerEntries(range)
      .map((entries) => cashBalances(openings, entries));
});

// ---------------------------------------------------------------- dashboard

class DashboardPeriodNotifier extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => ReportPeriod.thisMonth;

  void set(ReportPeriod period) => state = period;
}

final dashboardPeriodProvider =
    NotifierProvider<DashboardPeriodNotifier, ReportPeriod>(
      DashboardPeriodNotifier.new,
    );

class DashboardCurrencyNotifier extends Notifier<Currency> {
  @override
  Currency build() => Currency.usd;

  void set(Currency currency) => state = currency;
}

final dashboardCurrencyProvider =
    NotifierProvider<DashboardCurrencyNotifier, Currency>(
      DashboardCurrencyNotifier.new,
    );

/// Everything the dashboard shows for one period and currency.
class DashboardData {
  const DashboardData({
    required this.period,
    required this.currency,
    required this.range,
    required this.comparisonRange,
    required this.current,
    required this.previous,
    required this.trend,
    required this.expenseCategories,
    required this.currenciesWithData,
  });

  final ReportPeriod period;
  final Currency currency;
  final DateRange range;
  final DateRange comparisonRange;
  final CurrencyTotals current;
  final CurrencyTotals previous;
  final List<MonthTotals> trend;
  final List<MapEntry<String?, Money>> expenseCategories;

  /// Currencies that have entries in [range], to hint at the other currency.
  final Set<Currency> currenciesWithData;

  bool get isEmpty => current.entryCount == 0;
}

final dashboardProvider = StreamProvider<DashboardData>((ref) {
  final period = ref.watch(dashboardPeriodProvider);
  final currency = ref.watch(dashboardCurrencyProvider);
  final today = DateTime.now();

  final range = rangeFor(period, today);
  final comparison = comparisonRangeFor(period, today);
  final trendEnd = addDays(elapsedPart(range, today).end, -1);
  final trendStart = DateTime(trendEnd.year, trendEnd.month - 5);
  final starts = [range.start, comparison.start, trendStart]..sort();
  final window = DateRange(starts.first, range.end);

  return ref.watch(ledgerRepositoryProvider).watchLedgerEntries(window).map((
    entries,
  ) {
    final current = summarize(entries, range);
    return DashboardData(
      period: period,
      currency: currency,
      range: range,
      comparisonRange: comparison,
      current: current.byCurrency[currency] ?? CurrencyTotals.empty(currency),
      previous:
          summarize(entries, comparison).byCurrency[currency] ??
          CurrencyTotals.empty(currency),
      trend: monthlyTrend(entries, currency, lastMonth: trendEnd),
      expenseCategories:
          expensesByCategory(entries, range)[currency] ?? const [],
      currenciesWithData: current.byCurrency.keys.toSet(),
    );
  });
});
