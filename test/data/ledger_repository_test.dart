import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/core/date_only.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/data/database.dart';
import 'package:sme_financial_copilot/data/ledger_repository.dart';
import 'package:sme_financial_copilot/domain/entry_draft.dart';
import 'package:sme_financial_copilot/domain/enums.dart';
import 'package:sme_financial_copilot/finance_core/ledger_math.dart';

void main() {
  late AppDatabase db;
  late LedgerRepository repo;
  final now = DateTime(2026, 10, 16, 9);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LedgerRepository(db, clock: () => now);
  });

  tearDown(() => db.close());

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
    expect(original['amountMinor'], 5000);
  });

  test('voided entries leave totals but stay in history', () async {
    final keep = await repo.create(expense(5000));
    final drop = await repo.create(expense(2000, description: 'Mistake'));
    await repo.voidEntry(drop, reason: 'Entered twice');

    final range = DateRange.monthOf(now);
    final summary = summarize(await repo.watchLedgerEntries(range).first, range);
    expect(summary.byCurrency[Currency.usd]!.expense.minor, 5000);

    final all = await repo
        .watchEntries(const LedgerFilter(includeVoided: true))
        .first;
    expect(all.map((e) => e.id), containsAll([keep, drop]));
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
}
