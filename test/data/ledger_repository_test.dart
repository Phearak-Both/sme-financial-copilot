import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/data/cloud_store.dart';
import 'package:sme_financial_copilot/core/date_only.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/data/ledger_repository.dart';
import 'package:sme_financial_copilot/domain/entry_draft.dart';
import 'package:sme_financial_copilot/domain/enums.dart';
import 'package:sme_financial_copilot/finance_core/ledger_math.dart';

void main() {
  late MemoryCloudStore db;
  late LedgerRepository repo;
  final now = DateTime(2026, 10, 16, 9);

  setUp(() {
    db = MemoryCloudStore();
    repo = LedgerRepository(db, clock: () => now);
  });


  EntryDraft expense(int cents, {String description = 'Fertilizer'}) =>
      EntryDraft(
        type: EntryType.expense,
        amountMinor: cents,
        currency: Currency.usd,
        occurredOn: DateTime(2026, 10, 16),
        categoryId: 'farm_inputs',
        categoryKind: CategoryKind.expense,
        description: description,
      );

  test('seeds default categories', () async {
    final categories = await repo.watchCategories().first;
    expect(categories.map((c) => c.id), contains('farm_inputs'));
    expect(categories.every((c) => c.nameKm.isNotEmpty), isTrue);
  });

  test('create writes the entry and a revision', () async {
    final id = await repo.create(expense(5000));
    final row = await repo.watchEntry(id).first;
    expect(row!.amountMinor, 5000);
    expect(row.occurredOn, '2026-10-16');
    expect(row.version, 1);

    final revisions = await repo.watchRevisions(id).first;
    expect(revisions.single.kind, RevisionKind.create);
  });

  test('invalid drafts are rejected before writing', () async {
    expect(() => repo.create(expense(0)), throwsA(isA<InvalidDraftException>()));
    expect(await repo.watchEntries(const LedgerFilter()).first, isEmpty);
  });

  test('edit bumps the version and keeps history', () async {
    final id = await repo.create(expense(5000));
    await repo.update(id, expense(4500, description: 'Fertilizer (corrected)'));

    final row = await repo.watchEntry(id).first;
    expect(row!.amountMinor, 4500);
    expect(row.version, 2);

    final revisions = await repo.watchRevisions(id).first;
    expect(revisions.map((r) => r.kind), [RevisionKind.edit, RevisionKind.create]);
    final original = jsonDecode(revisions.last.snapshot) as Map<String, dynamic>;
    expect(original['amount_minor'], 5000);
  });

  test('voided entries leave totals but stay in history', () async {
    final keep = await repo.create(expense(5000));
    final drop = await repo.create(expense(2000, description: 'Mistake'));
    await repo.voidEntry(drop, reason: 'Entered twice');

    final range = DateRange.monthOf(now);
    final summary = summarize(await repo.watchLedgerEntries(range).first, range);
    expect(summary.byCurrency[Currency.usd]!.expense.minor, 5000);

    final all = await repo.watchEntries(const LedgerFilter()).first;
    expect(all.map((e) => e.id), containsAll([keep, drop]));
    final voided = await repo
        .watchEntries(const LedgerFilter(voidedOnly: true))
        .first;
    expect(voided.map((e) => e.id), [drop]);
    await expectLater(repo.update(drop, expense(1)), throwsStateError);
  });

  test('finds possible duplicates', () async {
    final id = await repo.create(expense(5000));
    expect(await repo.findPossibleDuplicates(expense(5000)), hasLength(1));
    expect(await repo.findPossibleDuplicates(expense(5001)), isEmpty);
    expect(
      await repo.findPossibleDuplicates(expense(5000), excludeId: id),
      isEmpty,
    );
  });

  test('filters by text, type and currency', () async {
    await repo.create(expense(5000, description: 'Fertilizer 50%'));
    await repo.create(expense(300, description: 'Tuk-tuk'));

    Future<int> count(LedgerFilter f) async =>
        (await repo.watchEntries(f).first).length;

    expect(await count(const LedgerFilter(query: 'fert')), 1);
    expect(await count(const LedgerFilter(query: '50%')), 1);
    expect(await count(const LedgerFilter(query: '%')), 1);
    expect(await count(const LedgerFilter(type: EntryType.income)), 0);
    expect(await count(const LedgerFilter(currency: Currency.khr)), 0);
    expect(await count(const LedgerFilter(currency: Currency.usd)), 2);
  });

  test('owner movements store no category', () async {
    final id = await repo.create(EntryDraft(
      type: EntryType.ownerWithdrawal,
      amountMinor: 1000,
      currency: Currency.usd,
      occurredOn: DateTime(2026, 10, 16),
      categoryId: 'farm_inputs',
    ));
    expect((await repo.watchEntry(id).first)!.categoryId, isNull);
  });

  test('filters by category', () async {
    await repo.create(expense(5000));
    await repo.create(EntryDraft(
      type: EntryType.expense,
      amountMinor: 300,
      currency: Currency.usd,
      occurredOn: DateTime(2026, 10, 16),
      categoryId: 'transport',
      categoryKind: CategoryKind.expense,
    ));
    final rows =
        await repo.watchEntries(const LedgerFilter(categoryId: 'transport')).first;
    expect(rows.single.amountMinor, 300);
  });

  test('opening balances can be set, replaced and cleared', () async {
    await repo.setOpeningBalance(Currency.usd, 10000, DateTime(2026, 10, 1));
    await repo.setOpeningBalance(Currency.usd, 12000, DateTime(2026, 10, 2));
    await repo.setOpeningBalance(Currency.khr, 0, DateTime(2026, 10, 1));

    var openings = await repo.watchOpeningBalances().first;
    expect(openings, hasLength(2));
    final usd = openings.firstWhere((o) => o.currency == Currency.usd);
    expect([usd.amountMinor, usd.asOf], [12000, '2026-10-02']);

    await repo.clearOpeningBalance(Currency.usd);
    openings = await repo.watchOpeningBalances().first;
    expect(openings.single.currency, Currency.khr);
  });

  test('opening balance rejects negative amounts and future dates', () {
    expect(() => repo.setOpeningBalance(Currency.usd, -1, DateTime(2026, 10, 1)),
        throwsArgumentError);
    expect(() => repo.setOpeningBalance(Currency.usd, 1, DateTime(2026, 10, 17)),
        throwsArgumentError);
  });

  test('a failed save while offline changes nothing', () async {
    final id = await repo.create(expense(5000));
    db.failWith = Exception('offline');
    await expectLater(repo.create(expense(100)), throwsException);
    await expectLater(repo.voidEntry(id), throwsException);
    db.failWith = null;
    final rows = await repo.watchEntries(const LedgerFilter()).first;
    expect(rows.map((e) => (e.id, e.status)), [(id, EntryStatus.active)]);
  });
}
