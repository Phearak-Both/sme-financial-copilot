import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/date_only.dart';
import '../core/money/currency.dart';
import '../core/money/money.dart';
import '../cloud/auth.dart';
import '../cloud/supabase_config.dart';
import '../data/cloud_store.dart';
import '../data/database.dart';
import '../data/ledger_repository.dart';
import '../data/settings_store.dart';
import '../finance_core/insights.dart';
import '../finance_core/ledger_math.dart';
import '../finance_core/patterns.dart';
import '../finance_core/period_math.dart';
import '../finance_core/sales.dart';

/// Where records live: the signed-in user's rows in Supabase, or memory when
/// Supabase isn't set up (nothing is kept after the app closes).
final cloudStoreProvider = Provider<CloudStore>(
  (ref) => supabaseReady
      ? SupabaseCloudStore(Supabase.instance.client)
      : MemoryCloudStore(),
);

/// The signed-in user's id; null when signed out or without Supabase.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider).value?.id,
);

/// Rebuilt for each signed-in user, so one account's records never show
/// for another.
final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  ref.watch(currentUserIdProvider);
  final repo = LedgerRepository(ref.watch(cloudStoreProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

/// Device preferences such as the language.
final settingsStoreProvider = Provider<SettingsStore>((ref) {
  final store = SettingsStore();
  ref.onDispose(store.dispose);
  return store;
});

final categoriesProvider = StreamProvider<List<CategoryRow>>(
  (ref) => ref.watch(ledgerRepositoryProvider).watchCategories(),
);

final categoriesByIdProvider = Provider<Map<String, CategoryRow>>((ref) {
  final categories = ref.watch(categoriesProvider).value ?? const [];
  return {for (final c in categories) c.id: c};
});

// ----------------------------------------------------------------- settings

/// The currency last used for an entry; new entries start with it.
const lastCurrencySettingKey = 'last_currency';

/// Set on the Export page; also tells the assistant whose business it is.
const businessNameSettingKey = 'businessName';

// ----------------------------------------------------------------- language

const localeSettingKey = 'locale';

/// Khmer is the default language; users can switch to English in Settings.
const defaultLocale = Locale('km');
const supportedAppLocales = [Locale('km'), Locale('en')];

/// The user's chosen language, falling back to [defaultLocale].
final localeProvider = StreamProvider<Locale>(
  (ref) => ref
      .watch(settingsStoreProvider)
      .watch(localeSettingKey)
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
    required this.topSellers,
    required this.currenciesWithData,
    required this.insights,
  });

  final ReportPeriod period;
  final Currency currency;
  final DateRange range;
  final DateRange comparisonRange;
  final CurrencyTotals current;
  final CurrencyTotals previous;
  final List<TrendBucket> trend;
  final List<MapEntry<String?, Money>> expenseCategories;
  /// Income by item (description), against the comparison period.
  final List<SalesItem> topSellers;

  /// Currencies that have entries in [range], to hint at the other currency.
  final Set<Currency> currenciesWithData;

  final List<Insight> insights;

  bool get isEmpty => current.entryCount == 0;
}

final dashboardProvider = StreamProvider<DashboardData>((ref) {
  final period = ref.watch(dashboardPeriodProvider);
  final currency = ref.watch(dashboardCurrencyProvider);
  final today = DateTime.now();

  final range = rangeFor(period, today);
  final comparison = comparisonRangeFor(period, today);
  final cash = ref.watch(cashBalancesProvider).value?[currency];
  // Also covers the recent days the cash runway is measured over.
  final tomorrow = addDays(dateOnly(today), 1);
  final starts = [
    range.start,
    comparison.start,
    addDays(tomorrow, -runwayRateDays),
  ]..sort();
  final window = DateRange(
    starts.first,
    range.end.isAfter(tomorrow) ? range.end : tomorrow,
  );

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
      trend: periodTrend(entries, currency, range),
      expenseCategories:
          expensesByCategory(entries, range)[currency] ?? const [],
      topSellers: topSellers(entries, currency, range, comparison),
      currenciesWithData: current.byCurrency.keys.toSet(),
      insights: buildInsights(
        entries: entries,
        currency: currency,
        range: range,
        comparison: comparison,
        today: today,
        cash: cash,
      ),
    );
  });
});

/// Patterns that look at months or years of history rather than the
/// selected period: regular payments, unusual spending, seasons, busy days
/// and withdrawals against profit.
class DashboardPatterns {
  const DashboardPatterns({
    required this.recurring,
    required this.spending,
    required this.seasons,
    required this.weekdays,
    required this.withdrawals,
  });

  final List<RecurringExpense> recurring;
  final List<CategoryComparison> spending;
  final Seasonality? seasons;
  final WeekdayIncome? weekdays;
  final List<MonthProfitWithdrawal> withdrawals;
}

final dashboardPatternsProvider = StreamProvider<DashboardPatterns>((ref) {
  final currency = ref.watch(dashboardCurrencyProvider);
  final today = DateTime.now();
  // Three calendar years covers the seasonality chart and everything else.
  final window = DateRange(
    DateTime(today.year - 2),
    addDays(dateOnly(today), 1),
  );

  return ref.watch(ledgerRepositoryProvider).watchLedgerEntries(window).map((
    entries,
  ) {
    final recurring = detectRecurring(entries, currency, today);
    return DashboardPatterns(
      recurring: recurring,
      spending: compareWithUsual(
        entries,
        currency,
        today,
        recurringKeys: {for (final r in recurring) r.key},
      ),
      seasons: seasonality(entries, currency, today),
      weekdays: weekdayIncome(entries, currency, today),
      withdrawals: profitVsWithdrawals(entries, currency, today),
    );
  });
});
