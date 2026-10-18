import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/enums.dart';
import 'default_categories.dart';

part 'database.g.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get kind => textEnum<CategoryKind>()();
  TextColumn get nameEn => text()();
  TextColumn get nameKm => text()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EntryRow')
class LedgerEntries extends Table {
  /// Client-generated UUID, so entries created offline sync idempotently.
  TextColumn get id => text()();
  TextColumn get type => textEnum<EntryType>()();

  /// Integer minor units: USD cents or whole KHR riel. Always positive;
  /// the direction comes from [type].
  // Referencing the column inside its own check is drift's documented idiom.
  IntColumn get amountMinor =>
      // ignore: recursive_getters
      integer().check(amountMinor.isBiggerThanValue(0))();

  /// ISO currency code, `USD` or `KHR`.
  TextColumn get currency => text().withLength(min: 3, max: 3)();

  /// Calendar date `yyyy-MM-dd`.
  TextColumn get occurredOn => text().withLength(min: 10, max: 10)();
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get note => text().nullable()();
  TextColumn get paymentMethod => textEnum<PaymentMethod>().nullable()();
  TextColumn get source =>
      textEnum<EntrySource>().withDefault(Constant(EntrySource.manual.name))();
  TextColumn get status =>
      textEnum<EntryStatus>().withDefault(Constant(EntryStatus.active.name))();
  TextColumn get voidReason => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Append-only history: one snapshot per create, edit or void.
@DataClassName('RevisionRow')
class EntryRevisions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entryId => text().references(LedgerEntries, #id)();
  IntColumn get version => integer()();
  TextColumn get kind => textEnum<RevisionKind>()();

  /// JSON snapshot of the entry after this change.
  TextColumn get snapshot => text()();
  DateTimeColumn get changedAt => dateTime()();
}

/// Cash the business held at the start of [asOf], one row per currency.
/// The cash balance is only shown for currencies that have one.
@DataClassName('OpeningBalanceRow')
class OpeningBalances extends Table {
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  IntColumn get amountMinor => integer()();

  /// `yyyy-MM-dd`.
  TextColumn get asOf => text().withLength(min: 10, max: 10)();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {currency};
}

/// Simple key–value app settings (e.g. language).
@DataClassName('SettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// An assistant conversation, kept so it can be reopened from history.
@DataClassName('ChatRow')
class Chats extends Table {
  TextColumn get id => text()();

  /// From the first thing the user sent; empty for a photo without text.
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ChatMessageRow')
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get chatId =>
      text().references(Chats, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  /// JSON from `chat_codec.dart`.
  TextColumn get data => text()();
}

@DriftDatabase(
  tables: [
    Categories,
    LedgerEntries,
    EntryRevisions,
    OpeningBalances,
    AppSettings,
    Chats,
    ChatMessages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'sme_copilot'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await m.createIndex(Index(
            'ledger_entries_occurred_on',
            'CREATE INDEX ledger_entries_occurred_on '
                'ON ledger_entries (occurred_on DESC, created_at DESC)',
          ));
          await batch((b) => b.insertAll(categories, defaultCategories()));
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(openingBalances);
          if (from < 3) {
            await m.createTable(chats);
            await m.createTable(chatMessages);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
