import 'package:supabase_flutter/supabase_flutter.dart';

/// The few table operations the repositories need. Rows are JSON maps with
/// the tables' snake_case column names.
///
/// [SupabaseCloudStore] is the real one; Row-Level Security limits every
/// call to the signed-in user's rows. [MemoryCloudStore] keeps rows in memory
/// for tests and for running without Supabase.
abstract class CloudStore {
  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, Object> where = const {},
  });

  /// Inserts [row] and returns it as stored, with server defaults filled in.
  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> row);

  Future<void> insertAll(String table, List<Map<String, dynamic>> rows);

  /// Updates the rows matching [where] and returns the first, as stored.
  Future<Map<String, dynamic>> update(
    String table,
    Map<String, Object> where,
    Map<String, dynamic> values,
  );

  Future<Map<String, dynamic>> upsert(
    String table,
    Map<String, dynamic> row, {
    required String onConflict,
  });

  Future<void> delete(String table, Map<String, Object> where);
}

class SupabaseCloudStore implements CloudStore {
  SupabaseCloudStore(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, Object> where = const {},
  }) async {
    var query = _client.from(table).select();
    for (final MapEntry(:key, :value) in where.entries) {
      query = query.eq(key, value);
    }
    // PostgREST returns at most 1,000 rows per request by default.
    final rows = <Map<String, dynamic>>[];
    const page = 1000;
    for (var from = 0; ; from += page) {
      final batch = await query.range(from, from + page - 1);
      rows.addAll(batch);
      if (batch.length < page) return rows;
    }
  }

  @override
  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> row,
  ) =>
      _client.from(table).insert(row).select().single();

  @override
  Future<void> insertAll(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from(table).insert(rows);
  }

  @override
  Future<Map<String, dynamic>> update(
    String table,
    Map<String, Object> where,
    Map<String, dynamic> values,
  ) {
    var query = _client.from(table).update(values);
    for (final MapEntry(:key, :value) in where.entries) {
      query = query.eq(key, value);
    }
    return query.select().limit(1).single();
  }

  @override
  Future<Map<String, dynamic>> upsert(
    String table,
    Map<String, dynamic> row, {
    required String onConflict,
  }) =>
      _client
          .from(table)
          .upsert(row, onConflict: onConflict)
          .select()
          .single();

  @override
  Future<void> delete(String table, Map<String, Object> where) async {
    var query = _client.from(table).delete();
    for (final MapEntry(:key, :value) in where.entries) {
      query = query.eq(key, value);
    }
    await query;
  }
}

/// In-memory tables that follow the same rules as the Supabase schema:
/// defaults, entry versions, frozen voided entries and revision snapshots.
class MemoryCloudStore implements CloudStore {
  MemoryCloudStore({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final _tables = <String, List<Map<String, dynamic>>>{};
  var _nextId = 1;

  /// Set to make every call fail, e.g. to test being offline.
  Object? failWith;

  List<Map<String, dynamic>> _table(String name) =>
      _tables.putIfAbsent(name, () => []);

  static bool _matches(Map<String, dynamic> row, Map<String, Object> where) =>
      where.entries.every((e) => row[e.key] == e.value);

  String _now() => _clock().toUtc().toIso8601String();

  void _check() {
    if (failWith != null) throw failWith!;
  }

  @override
  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, Object> where = const {},
  }) async {
    _check();
    return [
      for (final row in _table(table))
        if (_matches(row, where)) {...row},
    ];
  }

  @override
  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> row,
  ) async {
    _check();
    final now = _now();
    final stored = {
      ...switch (table) {
        'ledger_entries' => {
            'description': '',
            'source': 'manual',
            'note': null,
            'category_id': null,
            'payment_method': null,
            'void_reason': null,
          },
        'chat_messages' || 'entry_revisions' => {'id': _nextId++},
        _ => const <String, dynamic>{},
      },
      'created_at': now,
      'updated_at': now,
      ...row,
    };
    if (table == 'ledger_entries') {
      stored
        ..['version'] = 1
        ..['status'] = 'active'
        ..['created_at'] = now
        ..['updated_at'] = now;
    }
    _table(table).add(stored);
    if (table == 'ledger_entries') _revision(stored, 'create');
    return {...stored};
  }

  @override
  Future<void> insertAll(String table, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await insert(table, row);
    }
  }

  @override
  Future<Map<String, dynamic>> update(
    String table,
    Map<String, Object> where,
    Map<String, dynamic> values,
  ) async {
    _check();
    final rows = _table(table).where((r) => _matches(r, where)).toList();
    if (rows.isEmpty) throw StateError('No $table row matches $where');
    for (final row in rows) {
      if (table == 'ledger_entries') {
        if (row['status'] == 'voided') {
          throw StateError('Entry ${row['id']} is voided and cannot be changed');
        }
        row
          ..addAll(values)
          ..['version'] = (row['version'] as int) + 1
          ..['updated_at'] = _now();
        _revision(row, row['status'] == 'voided' ? 'voided' : 'edit');
      } else {
        row.addAll(values);
      }
    }
    return {...rows.first};
  }

  @override
  Future<Map<String, dynamic>> upsert(
    String table,
    Map<String, dynamic> row, {
    required String onConflict,
  }) async {
    _check();
    final keys = onConflict.split(',');
    final existing = _table(table).where(
      (r) => keys.every((k) => r[k] == row[k]),
    );
    if (existing.isEmpty) return insert(table, row);
    existing.first.addAll(row);
    return {...existing.first};
  }

  @override
  Future<void> delete(String table, Map<String, Object> where) async {
    _check();
    _table(table).removeWhere((r) => _matches(r, where));
    if (table == 'chats' && where['id'] != null) {
      _table('chat_messages').removeWhere((m) => m['chat_id'] == where['id']);
    }
  }

  void _revision(Map<String, dynamic> entry, String kind) {
    _table('entry_revisions').add({
      'id': _nextId++,
      'entry_id': entry['id'],
      'version': entry['version'],
      'kind': kind,
      'snapshot': {...entry},
      'changed_at': _now(),
    });
  }
}
