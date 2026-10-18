import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

/// Saved assistant conversations. Messages are stored as opaque JSON strings;
/// `chat_codec.dart` turns them back into chat messages.
class ChatRepository {
  ChatRepository(this._db, {DateTime Function()? clock, Uuid? uuid})
      : _clock = clock ?? DateTime.now,
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final DateTime Function() _clock;
  final Uuid _uuid;

  /// Most recently active first.
  Stream<List<ChatRow>> watchChats() => (_db.select(_db.chats)
        ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
      .watch();

  Future<List<String>> loadMessages(String chatId) async {
    final rows = await (_db.select(_db.chatMessages)
          ..where((m) => m.chatId.equals(chatId))
          ..orderBy([(m) => OrderingTerm.asc(m.position)]))
        .get();
    return [for (final r in rows) r.data];
  }

  /// Creates a chat and returns its id.
  Future<String> create(String title, List<String> messages) async {
    final id = _uuid.v4();
    final now = _clock();
    await _db.transaction(() async {
      await _db.into(_db.chats).insert(ChatsCompanion.insert(
            id: id,
            title: title,
            createdAt: now,
            updatedAt: now,
          ));
      await _insertMessages(id, messages);
    });
    return id;
  }

  /// Replaces the messages of [chatId] and marks it as just used.
  Future<void> update(String chatId, List<String> messages) =>
      _db.transaction(() async {
        await (_db.update(_db.chats)..where((c) => c.id.equals(chatId)))
            .write(ChatsCompanion(updatedAt: Value(_clock())));
        await (_db.delete(_db.chatMessages)
              ..where((m) => m.chatId.equals(chatId)))
            .go();
        await _insertMessages(chatId, messages);
      });

  Future<void> delete(String chatId) => _db.transaction(() async {
        await (_db.delete(_db.chatMessages)
              ..where((m) => m.chatId.equals(chatId)))
            .go();
        await (_db.delete(_db.chats)..where((c) => c.id.equals(chatId))).go();
      });

  Future<void> _insertMessages(String chatId, List<String> messages) =>
      _db.batch((b) => b.insertAll(_db.chatMessages, [
            for (final (i, data) in messages.indexed)
              ChatMessagesCompanion.insert(
                chatId: chatId,
                position: i,
                data: data,
              ),
          ]));
}
