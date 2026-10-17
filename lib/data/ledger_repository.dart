import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/date_only.dart';
import '../core/money/currency.dart';
import '../domain/entry_draft.dart';
import '../domain/enums.dart';
import '../finance_core/ledger_math.dart';
import '../finance_core/period_math.dart';
import 'database.dart';

/// Filters for the ledger list. All fields are optional and combine with AND.
class LedgerFilter {
  const LedgerFilter({
    this.query = '',
    this.type,
    this.currency,
    this.categoryId,
    this.range,
    this.voidedOnly = false,
  });

  final String query;
  final EntryType? type;
  final Currency? currency;
  final String? categoryId;
  final DateRange? range;
  final bool voidedOnly;

  LedgerFilter copyWith({
    String? query,
    EntryType? Function()? type,
    Currency? Function()? currency,
    String? Function()? categoryId,
    DateRange? Function()? range,
    bool? voidedOnly,
  }) =>
      LedgerFilter(
        query: query ?? this.query,
        type: type != null ? type() : this.type,
        currency: currency != null ? currency() : this.currency,
        categoryId: categoryId != null ? categoryId() : this.categoryId,
        range: range != null ? range() : this.range,
        voidedOnly: voidedOnly ?? this.voidedOnly,
      );

  bool get isDefault =>
      query.isEmpty &&
      type == null &&
      currency == null &&
      categoryId == null &&
      range == null &&
      !voidedOnly;

  @override
  bool operator ==(Object other) =>
      other is LedgerFilter &&
      other.query == query &&
      other.type == type &&
      other.currency == currency &&
      other.categoryId == categoryId &&
      other.range == range &&
      other.voidedOnly == voidedOnly;

  @override
  int get hashCode =>
      Object.hash(query, type, currency, categoryId, range, voidedOnly);
}

class InvalidDraftException implements Exception {
  const InvalidDraftException(this.errors);
  final List<DraftError> errors;

  @override
  String toString() => 'InvalidDraftException($errors)';
}

/// The only code path that writes ledger entries. Every write validates the
/// draft and appends a revision snapshot in the same database transaction.
class LedgerRepository {
  LedgerRepository(this._db, {DateTime Function()? clock, Uuid? uuid})
      : _clock = clock ?? DateTime.now,
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final DateTime Function() _clock;
  final Uuid _uuid;

  // ---------------------------------------------------------------- reads

  Stream<List<CategoryRow>> watchCategories() {
    final query = _db.select(_db.categories)
      ..where((c) => c.isArchived.equals(false))
      ..orderBy([
        (c) => OrderingTerm(expression: c.kind),
        (c) => OrderingTerm(expression: c.sortOrder),
      ]);
    return query.watch();
  }

  Stream<List<EntryRow>> watchEntries(LedgerFilter filter, {int? limit}) {
    final query = _db.select(_db.ledgerEntries)
      ..where((e) {
        final conditions = <Expression<bool>>[];
        // Voided entries are listed with the rest; [voidedOnly] shows them
        // alone. (Totals never count them; that's done in ledger_math.)
        if (filter.voidedOnly) {
          conditions.add(e.status.equalsValue(EntryStatus.voided));
        }
        if (filter.type != null) conditions.add(e.type.equalsValue(filter.type));
        if (filter.currency != null) {
          conditions.add(e.currency.equals(filter.currency!.code));
        }
        if (filter.categoryId != null) {
          conditions.add(e.categoryId.equals(filter.categoryId!));
        }
        if (filter.range != null) {
          conditions
            ..add(e.occurredOn.isBiggerOrEqualValue(filter.range!.startKey))
            ..add(e.occurredOn.isSmallerThanValue(filter.range!.endKey));
        }
        final text = filter.query.trim();
        if (text.isNotEmpty) {
          final pattern = '%${_escapeLike(text)}%';
          conditions.add(
            e.description.like(pattern, escapeChar: r'\') |
                e.note.like(pattern, escapeChar: r'\'),
          );
        }
        return conditions.isEmpty
            ? const Constant(true)
            : conditions.reduce((a, b) => a & b);
      })
      ..orderBy([
        (e) => OrderingTerm.desc(e.occurredOn),
        (e) => OrderingTerm.desc(e.createdAt),
      ]);
    if (limit != null) query.limit(limit);
    return query.watch();
  }

  /// Entries in [range], for calculations. Voided ones are included; the
  /// finance_core math skips them.
  Stream<List<LedgerEntry>> watchLedgerEntries(DateRange range) =>
      watchEntries(LedgerFilter(range: range))
          .map((rows) => rows.map(toLedgerEntry).toList());

  Stream<EntryRow?> watchEntry(String id) =>
      (_db.select(_db.ledgerEntries)..where((e) => e.id.equals(id)))
          .watchSingleOrNull();

  Stream<List<RevisionRow>> watchRevisions(String entryId) =>
      (_db.select(_db.entryRevisions)
            ..where((r) => r.entryId.equals(entryId))
            ..orderBy([(r) => OrderingTerm.desc(r.id)]))
          .watch();

  /// Active entries with the same type, amount, currency and date as [draft].
  /// Used to warn the user before saving a likely duplicate.
  Future<List<EntryRow>> findPossibleDuplicates(
    EntryDraft draft, {
    String? excludeId,
  }) {
    final query = _db.select(_db.ledgerEntries)
      ..where((e) {
        var condition = e.status.equalsValue(EntryStatus.active) &
            e.type.equalsValue(draft.type) &
            e.amountMinor.equals(draft.amountMinor) &
            e.currency.equals(draft.currency.code) &
            e.occurredOn.equals(draft.occurredOnKey);
        if (excludeId != null) condition = condition & e.id.equals(excludeId).not();
        return condition;
      });
    return query.get();
  }

  // --------------------------------------------------------------- writes

  Future<String> create(EntryDraft draft) {
    _validate(draft);
    final id = _uuid.v4();
    final now = _clock();
    return _db.transaction(() async {
      await _db.into(_db.ledgerEntries).insert(
            LedgerEntriesCompanion.insert(
              id: id,
              type: draft.type,
              amountMinor: draft.amountMinor,
              currency: draft.currency.code,
              occurredOn: draft.occurredOnKey,
              categoryId: Value(_categoryFor(draft)),
              description: Value(draft.description.trim()),
              note: Value(_blankToNull(draft.note)),
              paymentMethod: Value(draft.paymentMethod),
              source: Value(draft.source),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _recordRevision(id, RevisionKind.create, now);
      return id;
    });
  }

  Future<void> update(String id, EntryDraft draft) {
    _validate(draft);
    final now = _clock();
    return _db.transaction(() async {
      final existing = await _requireActive(id);
      await (_db.update(_db.ledgerEntries)..where((e) => e.id.equals(id)))
          .write(
        LedgerEntriesCompanion(
          type: Value(draft.type),
          amountMinor: Value(draft.amountMinor),
          currency: Value(draft.currency.code),
          occurredOn: Value(draft.occurredOnKey),
          categoryId: Value(_categoryFor(draft)),
          description: Value(draft.description.trim()),
          note: Value(_blankToNull(draft.note)),
          paymentMethod: Value(draft.paymentMethod),
          version: Value(existing.version + 1),
          updatedAt: Value(now),
        ),
      );
      await _recordRevision(id, RevisionKind.edit, now);
    });
  }

  /// Voids an entry. Voided entries stay in the database and history but are
  /// excluded from every total. Nothing is ever hard-deleted.
  Future<void> voidEntry(String id, {String? reason}) {
    final now = _clock();
    return _db.transaction(() async {
      final existing = await _requireActive(id);
      await (_db.update(_db.ledgerEntries)..where((e) => e.id.equals(id)))
          .write(
        LedgerEntriesCompanion(
          status: const Value(EntryStatus.voided),
          voidReason: Value(_blankToNull(reason)),
          version: Value(existing.version + 1),
          updatedAt: Value(now),
        ),
      );
      await _recordRevision(id, RevisionKind.voided, now);
    });
  }

  // ------------------------------------------------------- opening cash

  Stream<List<OpeningBalance>> watchOpeningBalances() =>
      _db.select(_db.openingBalances).watch().map((rows) => [
            for (final row in rows)
              OpeningBalance(
                currency: Currency.fromCode(row.currency),
                amountMinor: row.amountMinor,
                asOf: row.asOf,
              ),
          ]);

  /// Sets the cash held at the start of [asOf]. Zero is a valid balance.
  Future<void> setOpeningBalance(
    Currency currency,
    int amountMinor,
    DateTime asOf,
  ) {
    if (amountMinor < 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be >= 0');
    }
    if (dateOnly(asOf).isAfter(dateOnly(_clock()))) {
      throw ArgumentError.value(asOf, 'asOf', 'cannot be in the future');
    }
    return _db.into(_db.openingBalances).insertOnConflictUpdate(
          OpeningBalancesCompanion.insert(
            currency: currency.code,
            amountMinor: amountMinor,
            asOf: toDateKey(asOf),
            updatedAt: _clock(),
          ),
        );
  }

  Future<void> clearOpeningBalance(Currency currency) =>
      (_db.delete(_db.openingBalances)
            ..where((b) => b.currency.equals(currency.code)))
          .go();

  // ------------------------------------------------------------- settings

  Stream<String?> watchSetting(String key) =>
      (_db.select(_db.appSettings)..where((s) => s.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  Future<void> setSetting(String key, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  // -------------------------------------------------------------- helpers

  void _validate(EntryDraft draft) {
    final errors = validateDraft(draft, today: _clock());
    if (errors.isNotEmpty) throw InvalidDraftException(errors);
  }

  Future<EntryRow> _requireActive(String id) async {
    final row = await (_db.select(_db.ledgerEntries)
          ..where((e) => e.id.equals(id)))
        .getSingleOrNull();
    if (row == null) throw StateError('Entry $id not found');
    if (row.status == EntryStatus.voided) {
      throw StateError('Entry $id is voided and cannot be changed');
    }
    return row;
  }

  Future<void> _recordRevision(String id, RevisionKind kind, DateTime at) async {
    final row = await (_db.select(_db.ledgerEntries)
          ..where((e) => e.id.equals(id)))
        .getSingle();
    await _db.into(_db.entryRevisions).insert(
          EntryRevisionsCompanion.insert(
            entryId: id,
            version: row.version,
            kind: kind,
            snapshot: jsonEncode(row.toJson()),
            changedAt: at,
          ),
        );
  }

  static String? _categoryFor(EntryDraft draft) =>
      draft.type.categoryKind == null ? null : draft.categoryId;

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static String _escapeLike(String text) => text
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

LedgerEntry toLedgerEntry(EntryRow row) => LedgerEntry(
      id: row.id,
      type: row.type,
      amountMinor: row.amountMinor,
      currency: Currency.fromCode(row.currency),
      occurredOn: row.occurredOn,
      status: row.status,
      categoryId: row.categoryId,
    );
