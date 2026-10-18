/// Row types for the cloud ledger (Supabase tables, see
/// `supabase/migrations/0001_cloud_ledger.sql`). JSON keys are the table's
/// snake_case column names.
library;

import 'dart:convert';

import '../domain/enums.dart';

DateTime _time(Object? value) => DateTime.parse(value! as String).toLocal();

/// Enum names are stored as-is, e.g. `ownerWithdrawal`.
T _enum<T extends Enum>(List<T> values, Object? name) =>
    values.byName(name! as String);

T? _enumOrNull<T extends Enum>(List<T> values, Object? name) =>
    name == null ? null : values.byName(name as String);

class CategoryRow {
  const CategoryRow({
    required this.id,
    required this.kind,
    required this.nameEn,
    required this.nameKm,
    this.isSystem = true,
    this.isArchived = false,
    this.sortOrder = 0,
  });

  final String id;
  final CategoryKind kind;
  final String nameEn;
  final String nameKm;
  final bool isSystem;
  final bool isArchived;
  final int sortOrder;
}

class EntryRow {
  const EntryRow({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.occurredOn,
    this.categoryId,
    this.description = '',
    this.note,
    this.paymentMethod,
    this.source = EntrySource.manual,
    this.status = EntryStatus.active,
    this.voidReason,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EntryRow.fromJson(Map<String, dynamic> json) => EntryRow(
        id: json['id'] as String,
        type: _enum(EntryType.values, json['type']),
        amountMinor: (json['amount_minor'] as num).toInt(),
        currency: json['currency'] as String,
        occurredOn: json['occurred_on'] as String,
        categoryId: json['category_id'] as String?,
        description: json['description'] as String? ?? '',
        note: json['note'] as String?,
        paymentMethod: _enumOrNull(PaymentMethod.values, json['payment_method']),
        source: _enum(EntrySource.values, json['source'] ?? 'manual'),
        status: _enum(EntryStatus.values, json['status'] ?? 'active'),
        voidReason: json['void_reason'] as String?,
        version: (json['version'] as num?)?.toInt() ?? 1,
        createdAt: _time(json['created_at']),
        updatedAt: _time(json['updated_at']),
      );

  final String id;
  final EntryType type;

  /// Integer minor units: USD cents or whole riel. Always positive.
  final int amountMinor;

  /// `USD` or `KHR`.
  final String currency;

  /// `yyyy-MM-dd`.
  final String occurredOn;
  final String? categoryId;
  final String description;
  final String? note;
  final PaymentMethod? paymentMethod;
  final EntrySource source;
  final EntryStatus status;
  final String? voidReason;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class RevisionRow {
  const RevisionRow({
    required this.id,
    required this.entryId,
    required this.version,
    required this.kind,
    required this.snapshot,
    required this.changedAt,
  });

  factory RevisionRow.fromJson(Map<String, dynamic> json) => RevisionRow(
        id: (json['id'] as num).toInt(),
        entryId: json['entry_id'] as String,
        version: (json['version'] as num).toInt(),
        kind: _enum(RevisionKind.values, json['kind']),
        snapshot: json['snapshot'] is String
            ? json['snapshot'] as String
            : jsonEncode(json['snapshot']),
        changedAt: _time(json['changed_at']),
      );

  final int id;
  final String entryId;
  final int version;
  final RevisionKind kind;

  /// JSON of the entry row after this change (snake_case keys).
  final String snapshot;
  final DateTime changedAt;
}

/// An assistant conversation, kept so it can be reopened from history.
class ChatRow {
  const ChatRow({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRow.fromJson(Map<String, dynamic> json) => ChatRow(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        createdAt: _time(json['created_at']),
        updatedAt: _time(json['updated_at']),
      );

  final String id;

  /// From the first thing the user sent; empty for a photo without text.
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
}
