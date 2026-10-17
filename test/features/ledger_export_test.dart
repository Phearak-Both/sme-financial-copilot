import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/core/date_only.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/data/database.dart';
import 'package:sme_financial_copilot/data/ledger_repository.dart';
import 'package:sme_financial_copilot/domain/entry_draft.dart';
import 'package:sme_financial_copilot/domain/enums.dart';
import 'package:sme_financial_copilot/features/ledger/ledger_export.dart';
import 'package:sme_financial_copilot/finance_core/period_math.dart';
import 'package:sme_financial_copilot/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late LedgerRepository repo;
  final today = DateTime(2026, 10, 17);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LedgerRepository(db, clock: () => today);
  });
  tearDown(() => db.close());

  Future<String> add(
    EntryType type,
    int minor,
    String day, {
    Currency currency = Currency.usd,
    String description = '',
  }) => repo.create(
    EntryDraft(
      type: type,
      amountMinor: minor,
      currency: currency,
      occurredOn: DateTime.parse(day),
      categoryId: switch (type.categoryKind) {
        CategoryKind.income => 'other_income',
        CategoryKind.expense => 'farm_inputs',
        null => null,
      },
      categoryKind: type.categoryKind,
      description: description,
    ),
  );

  Future<GeneralLedger> build(
    ExportPeriod period, {
    Currency currency = Currency.usd,
    List<OpeningBalance> openings = const [],
    String lang = 'en',
  }) async => buildGeneralLedger(
    entries: await repo.watchEntries(const LedgerFilter()).first,
    openings: openings,
    categories: {for (final c in await repo.watchCategories().first) c.id: c},
    currency: currency,
    range: period.rangeFor(today),
    today: today,
    l10n: lookupAppLocalizations(Locale(lang)),
    isKhmer: lang == 'km',
  );

  test('periods are whole months including this one', () {
    String start(ExportPeriod p) => toDateKey(p.rangeFor(today).start);
    expect(start(ExportPeriod.thisMonth), '2026-10-01');
    expect(start(ExportPeriod.last3Months), '2026-08-01');
    expect(start(ExportPeriod.last6Months), '2026-05-01');
    expect(start(ExportPeriod.lastYear), '2025-11-01');
  });

  test('carries the cash balance into the period', () async {
    await add(EntryType.income, 5000, '2026-09-10', description: 'Sold rice');
    await add(EntryType.expense, 2550, '2026-10-03', description: 'Fertilizer');
    await add(EntryType.income, 1200, '2026-10-06', description: 'Vegetables');
    final voided = await add(EntryType.expense, 999, '2026-10-04');
    await repo.voidEntry(voided);
    await add(EntryType.expense, 40000, '2026-10-05', currency: Currency.khr);

    final ledger = await build(
      ExportPeriod.thisMonth,
      openings: const [
        OpeningBalance(
          currency: Currency.usd,
          amountMinor: 10000,
          asOf: '2026-09-01',
        ),
      ],
    );
    expect((ledger.firstDay, ledger.lastDay), ('2026-10-01', '2026-10-17'));
    // Opening $100 on 1 Sep + $50 in September = $150 brought into October.
    expect(ledger.rows.map((r) => r.description), [
      'Opening balance',
      'Fertilizer',
      'Vegetables',
    ]);
    expect(ledger.rows.map((r) => r.balance), [15000, 12450, 13650]);
    expect(
      (
        ledger.entryCount,
        ledger.totalDebit,
        ledger.totalCredit,
        ledger.closing,
      ),
      (2, 1200, 2550, 13650),
    );

    final longer = await build(ExportPeriod.last3Months);
    expect(longer.rows.map((r) => r.description), [
      'Opening balance',
      'Sold rice',
      'Fertilizer',
      'Vegetables',
    ]);

    final khr = await build(ExportPeriod.thisMonth, currency: Currency.khr);
    expect(khr.rows.last.credit, 40000);
    expect(khr.closing, -40000);
  });

  test('without opening cash, earlier entries are brought forward', () async {
    await add(EntryType.income, 5000, '2026-09-10');
    await add(EntryType.expense, 1000, '2026-10-02');
    final ledger = await build(ExportPeriod.thisMonth);
    expect(ledger.rows.first.balance, 5000);
    expect(ledger.closing, 4000);
  });

  test(
    'opening cash dated inside the period starts the balance there',
    () async {
      await add(EntryType.expense, 1000, '2026-10-02', description: 'Before');
      await add(EntryType.income, 500, '2026-10-12', description: 'After');
      final ledger = await build(
        ExportPeriod.thisMonth,
        openings: const [
          OpeningBalance(
            currency: Currency.usd,
            amountMinor: 20000,
            asOf: '2026-10-10',
          ),
        ],
      );
      expect(ledger.rows.map((r) => r.description), [
        'Before',
        'Opening balance',
        'After',
      ]);
      expect(ledger.rows.map((r) => r.balance), [null, 20000, 20500]);
    },
  );

  test('empty period still has an opening row and no entries', () async {
    final ledger = await build(ExportPeriod.thisMonth, lang: 'km');
    expect(ledger.entryCount, 0);
    expect(ledger.rows.single.description, 'សមតុល្យដើមគ្រា');
  });

  test('amounts carry no symbol and keep currency decimals', () {
    expect(glAmount(123450, Currency.usd), '1,234.50');
    expect(glAmount(-50000, Currency.khr), '-50,000');
  });
}
