import 'dart:async';

import 'package:uuid/uuid.dart';

import '../core/date_only.dart';
import '../core/money/currency.dart';
import '../domain/entry_draft.dart';
import '../domain/enums.dart';
import '../finance_core/ledger_math.dart';
import '../finance_core/period_math.dart';
import 'cloud_store.dart';
import 'database.dart';
import 'default_categories.dart';

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

/// The only code path that writes ledger entries. Entries live in the cloud
/// (one account's rows only, enforced by Row-Level Security); this class
/// keeps them in memory while the app runs, so screens update instantly.
///
/// Every write validates the draft first. The database itself bumps the
/// version, freezes voided entries and records the revision history.
class LedgerRepository {
  LedgerRepository(this._store, {DateTime Function()? clock, Uuid? uuid})
      : _clock = clock ?? DateTime.now,
        _uuid = uuid ?? const Uuid();

  final CloudStore _store;
  final DateTime Function() _clock;
  final Uuid _uuid;

  late final _entries = _Live<List<EntryRow>>(
    () async => [
      for (final row in await _store.select('ledger_entries'))
        EntryRow.fromJson(row),
    ],
  );

  late final _openings = _Live<List<OpeningBalance>>(_loadOpenings);

  /// Ids of entries whose history just changed.
  final _revised = StreamController<String>.broadcast();

  /// Reloads everything from the cloud, e.g. to pick up changes made on
  /// another device.
  Future<void> refresh() async {
    await _entries.reload();
    await _openings.reload();
  }

  void dispose() {
    _entries.close();
    _openings.close();
    _revised.close();
  }

  // ---------------------------------------------------------------- reads

  /// Categories are built in, the same for every account.
  Stream<List<CategoryRow>> watchCategories() => Stream.value(_categories);

  static final _categories = defaultCategories()
      .where((c) => !c.isArchived)
      .toList()
    ..sort((a, b) => a.kind != b.kind
        ? a.kind.index.compareTo(b.kind.index)
        : a.sortOrder.compareTo(b.sortOrder));

  Stream<List<EntryRow>> watchEntries(LedgerFilter filter, {int? limit}) =>
      _entries.watch().map((rows) => _filter(rows, filter, limit));

  static List<EntryRow> _filter(
    List<EntryRow> rows,
    LedgerFilter filter,
    int? limit,
  ) {
    final text = filter.query.trim().toLowerCase();
    final matches = rows.where((e) {
      // Voided entries are listed with the rest; [voidedOnly] shows them
      // alone. (Totals never count them; that's done in ledger_math.)
      if (filter.voidedOnly && e.status != EntryStatus.voided) return false;
      if (filter.type != null && e.type != filter.type) return false;
      if (filter.currency != null && e.currency != filter.currency!.code) {
        return false;
      }
      if (filter.categoryId != null && e.categoryId != filter.categoryId) {
        return false;
      }
      if (filter.range != null && !filter.range!.containsKey(e.occurredOn)) {
        return false;
      }
      if (text.isNotEmpty &&
          !e.description.toLowerCase().contains(text) &&
          !(e.note?.toLowerCase().contains(text) ?? false)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final byDate = b.occurredOn.compareTo(a.occurredOn);
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });
    return limit == null || matches.length <= limit
        ? matches
        : matches.sublist(0, limit);
  }

  /// Entries in [range], for calculations. Voided ones are included; the
  /// finance_core math skips them.
  Stream<List<LedgerEntry>> watchLedgerEntries(DateRange range) =>
      watchEntries(LedgerFilter(range: range))
          .map((rows) => rows.map(toLedgerEntry).toList());

  Stream<EntryRow?> watchEntry(String id) => _entries
      .watch()
      .map((rows) => rows.where((e) => e.id == id).firstOrNull);

  /// Newest first.
  Stream<List<RevisionRow>> watchRevisions(String entryId) async* {
    Future<List<RevisionRow>> load() async => [
          for (final row in await _store.select(
            'entry_revisions',
            where: {'entry_id': entryId},
          ))
            RevisionRow.fromJson(row),
        ]..sort((a, b) => b.id.compareTo(a.id));
    yield await load();
    await for (final _ in _revised.stream.where((id) => id == entryId)) {
      yield await load();
    }
  }

  /// Active entries with the same type, amount, currency and date as [draft].
  /// Used to warn the user before saving a likely duplicate.
  Future<List<EntryRow>> findPossibleDuplicates(
    EntryDraft draft, {
    String? excludeId,
  }) async => [
        for (final e in await _entries.get())
          if (e.status == EntryStatus.active &&
              e.type == draft.type &&
              e.amountMinor == draft.amountMinor &&
              e.currency == draft.currency.code &&
              e.occurredOn == draft.occurredOnKey &&
              e.id != excludeId)
            e,
      ];

  // --------------------------------------------------------------- writes

  Future<String> create(EntryDraft draft) async {
    _validate(draft);
    final id = _uuid.v4();
    final row = await _store.insert('ledger_entries', {
      'id': id,
      ..._fields(draft),
      'source': draft.source.name,
    });
    await _saved(EntryRow.fromJson(row));
    return id;
  }

  /// Saves many entries with a few requests, e.g. sample data. Every draft
  /// is validated first, so nothing is saved if one is invalid.
  Future<void> createAll(List<EntryDraft> drafts, {int chunkSize = 250}) async {
    drafts.forEach(_validate);
    final rows = [
      for (final draft in drafts)
        {'id': _uuid.v4(), ..._fields(draft), 'source': draft.source.name},
    ];
    for (var i = 0; i < rows.length; i += chunkSize) {
      final end = i + chunkSize < rows.length ? i + chunkSize : rows.length;
      await _store.insertAll('ledger_entries', rows.sublist(i, end));
    }
    await _entries.reload();
  }

  Future<void> update(String id, EntryDraft draft) async {
    _validate(draft);
    await _requireActive(id);
    final row = await _store.update(
      'ledger_entries',
      {'id': id},
      _fields(draft),
    );
    await _saved(EntryRow.fromJson(row));
  }

  /// Voids an entry. Voided entries stay in the database and history but are
  /// excluded from every total. Nothing is ever hard-deleted.
  Future<void> voidEntry(String id, {String? reason}) async {
    await _requireActive(id);
    final row = await _store.update('ledger_entries', {'id': id}, {
      'status': EntryStatus.voided.name,
      'void_reason': _blankToNull(reason),
    });
    await _saved(EntryRow.fromJson(row));
  }

  Map<String, dynamic> _fields(EntryDraft draft) => {
        'type': draft.type.name,
        'amount_minor': draft.amountMinor,
        'currency': draft.currency.code,
        'occurred_on': draft.occurredOnKey,
        'category_id': _categoryFor(draft),
        'description': draft.description.trim(),
        'note': _blankToNull(draft.note),
        'payment_method': draft.paymentMethod?.name,
      };

  Future<void> _saved(EntryRow row) async {
    final current = await _entries.get();
    _entries.set([
      for (final e in current)
        if (e.id != row.id) e,
      row,
    ]);
    _revised.add(row.id);
  }

  // ------------------------------------------------------- opening cash

  Stream<List<OpeningBalance>> watchOpeningBalances() => _openings.watch();

  Future<List<OpeningBalance>> _loadOpenings() async => [
        for (final row in await _store.select('opening_balances'))
          OpeningBalance(
            currency: Currency.fromCode(row['currency'] as String),
            amountMinor: (row['amount_minor'] as num).toInt(),
            asOf: row['as_of'] as String,
          ),
      ];

  /// Sets the cash held at the start of [asOf]. Zero is a valid balance.
  Future<void> setOpeningBalance(
    Currency currency,
    int amountMinor,
    DateTime asOf,
  ) async {
    if (amountMinor < 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be >= 0');
    }
    if (dateOnly(asOf).isAfter(dateOnly(_clock()))) {
      throw ArgumentError.value(asOf, 'asOf', 'cannot be in the future');
    }
    await _store.upsert(
      'opening_balances',
      {
        'currency': currency.code,
        'amount_minor': amountMinor,
        'as_of': toDateKey(asOf),
        'updated_at': _clock().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,currency',
    );
    await _openings.reload();
  }

  Future<void> clearOpeningBalance(Currency currency) async {
    await _store.delete('opening_balances', {'currency': currency.code});
    await _openings.reload();
  }

  // -------------------------------------------------------------- helpers

  void _validate(EntryDraft draft) {
    final errors = validateDraft(draft, today: _clock());
    if (errors.isNotEmpty) throw InvalidDraftException(errors);
  }

  Future<EntryRow> _requireActive(String id) async {
    final row = (await _entries.get()).where((e) => e.id == id).firstOrNull;
    if (row == null) throw StateError('Entry $id not found');
    if (row.status == EntryStatus.voided) {
      throw StateError('Entry $id is voided and cannot be changed');
    }
    return row;
  }

  static String? _categoryFor(EntryDraft draft) =>
      draft.type.categoryKind == null ? null : draft.categoryId;

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

/// A value loaded from the cloud once, then kept current by this app's own
/// writes. Each listener gets the latest value first, then every change.
class _Live<T> {
  _Live(this._load);

  final Future<T> Function() _load;
  final _changes = StreamController<T>.broadcast();
  T? _value;
  Future<T>? _loading;

  Future<T> get() {
    final value = _value;
    if (value != null) return Future.value(value);
    return _loading ??= _load().then(
      (v) {
        _value = v;
        return v;
      },
      onError: (Object e) {
        // Let the next listener try again, e.g. after reconnecting.
        _loading = null;
        throw e;
      },
    );
  }

  Future<void> reload() async {
    _loading = null;
    set(await _load());
  }

  void set(T value) {
    _value = value;
    _loading = Future.value(value);
    _changes.add(value);
  }

  Stream<T> watch() {
    late final StreamController<T> out;
    StreamSubscription<T>? sub;
    out = StreamController<T>(
      onListen: () {
        sub = _changes.stream.listen(out.add);
        get().then(
          (_) {
            if (!out.isClosed) out.add(_value as T);
          },
          onError: (Object e, StackTrace s) {
            if (!out.isClosed) out.addError(e, s);
          },
        );
      },
      onCancel: () async {
        await sub?.cancel();
        await out.close();
      },
    );
    return out.stream;
  }

  void close() => _changes.close();
}

LedgerEntry toLedgerEntry(EntryRow row) => LedgerEntry(
      id: row.id,
      type: row.type,
      amountMinor: row.amountMinor,
      currency: Currency.fromCode(row.currency),
      occurredOn: row.occurredOn,
      status: row.status,
      categoryId: row.categoryId,
      description: row.description,
    );
