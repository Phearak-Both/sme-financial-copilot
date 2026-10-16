import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date_only.dart';
import '../data/database.dart';
import '../data/ledger_repository.dart';
import '../finance_core/ledger_math.dart';

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
final localeProvider = StreamProvider<Locale>((ref) => ref
    .watch(ledgerRepositoryProvider)
    .watchSetting(localeSettingKey)
    .map((code) => supportedAppLocales.firstWhere(
          (locale) => locale.languageCode == code,
          orElse: () => defaultLocale,
        )));

// ------------------------------------------------------------------- ledger

class LedgerFilterNotifier extends Notifier<LedgerFilter> {
  @override
  LedgerFilter build() => const LedgerFilter();

  void set(LedgerFilter filter) => state = filter;
}

final ledgerFilterProvider =
    NotifierProvider<LedgerFilterNotifier, LedgerFilter>(LedgerFilterNotifier.new);

final ledgerEntriesProvider = StreamProvider<List<EntryRow>>((ref) {
  final filter = ref.watch(ledgerFilterProvider);
  return ref.watch(ledgerRepositoryProvider).watchEntries(filter);
});

final recentEntriesProvider = StreamProvider<List<EntryRow>>((ref) => ref
    .watch(ledgerRepositoryProvider)
    .watchEntries(const LedgerFilter(), limit: 5));

final entryProvider = StreamProvider.family<EntryRow?, String>(
  (ref, id) => ref.watch(ledgerRepositoryProvider).watchEntry(id),
);

final revisionsProvider = StreamProvider.family<List<RevisionRow>, String>(
  (ref, id) => ref.watch(ledgerRepositoryProvider).watchRevisions(id),
);

// ---------------------------------------------------------------- summaries

final thisMonthSummaryProvider = StreamProvider<PeriodSummary>((ref) {
  final range = DateRange.monthOf(DateTime.now());
  return ref
      .watch(ledgerRepositoryProvider)
      .watchLedgerEntries(range)
      .map((entries) => summarize(entries, range));
});
