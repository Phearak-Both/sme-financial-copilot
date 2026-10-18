import 'dart:async';

import 'package:uuid/uuid.dart';

import 'cloud_store.dart';
import 'database.dart';

/// Saved assistant conversations, in the cloud with the signed-in user's
/// other records. Messages are stored as opaque JSON strings;
/// `chat_codec.dart` turns them back into chat messages.
class ChatRepository {
  ChatRepository(this._store, {DateTime Function()? clock, Uuid? uuid})
      : _clock = clock ?? DateTime.now,
        _uuid = uuid ?? const Uuid();

  final CloudStore _store;
  final DateTime Function() _clock;
  final Uuid _uuid;

  /// Tells [watchChats] listeners to reload after a change.
  final _changed = StreamController<void>.broadcast();

  void dispose() => _changed.close();

  /// Most recently active first.
  Stream<List<ChatRow>> watchChats() async* {
    Future<List<ChatRow>> load() async => [
          for (final row in await _store.select('chats')) ChatRow.fromJson(row),
        ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    yield await load();
    await for (final _ in _changed.stream) {
      yield await load();
    }
  }

  Future<List<String>> loadMessages(String chatId) async {
    final rows = await _store.select(
      'chat_messages',
      where: {'chat_id': chatId},
    )
      ..sort((a, b) => (a['position'] as num).compareTo(b['position'] as num));
    return [for (final r in rows) r['data'] as String];
  }

  /// Creates a chat and returns its id.
  Future<String> create(String title, List<String> messages) async {
    final id = _uuid.v4();
    final now = _now();
    await _store.insert('chats', {
      'id': id,
      'title': title,
      'created_at': now,
      'updated_at': now,
    });
    await _insertMessages(id, messages);
    _changed.add(null);
    return id;
  }

  /// Replaces the messages of [chatId] and marks it as just used.
  Future<void> update(String chatId, List<String> messages) async {
    await _store.update('chats', {'id': chatId}, {'updated_at': _now()});
    await _store.delete('chat_messages', {'chat_id': chatId});
    await _insertMessages(chatId, messages);
    _changed.add(null);
  }

  /// Messages go with it (on delete cascade).
  Future<void> delete(String chatId) async {
    await _store.delete('chats', {'id': chatId});
    _changed.add(null);
  }

  String _now() => _clock().toUtc().toIso8601String();

  Future<void> _insertMessages(String chatId, List<String> messages) =>
      _store.insertAll('chat_messages', [
        for (final (i, data) in messages.indexed)
          {'chat_id': chatId, 'position': i, 'data': data},
      ]);
}
