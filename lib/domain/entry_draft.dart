import '../core/date_only.dart';
import '../core/money/currency.dart';
import 'enums.dart';

/// The fields a user fills in (or confirms) before an entry is saved.
/// Used by manual entry today and by AI-proposed drafts later.
class EntryDraft {
  const EntryDraft({
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.occurredOn,
    this.categoryId,
    this.categoryKind,
    this.description = '',
    this.note,
    this.paymentMethod,
    this.source = EntrySource.manual,
  });

  final EntryType type;
  final int amountMinor;
  final Currency currency;
  final DateTime occurredOn;
  final String? categoryId;

  /// Kind of the selected category, used to check it matches [type].
  final CategoryKind? categoryKind;
  final String description;
  final String? note;
  final PaymentMethod? paymentMethod;
  final EntrySource source;

  String get occurredOnKey => toDateKey(occurredOn);
}

enum DraftError { amountNotPositive, futureDate, categoryRequired, categoryMismatch }

/// Validates a draft. Returns an empty list when it can be saved.
List<DraftError> validateDraft(EntryDraft draft, {required DateTime today}) {
  final errors = <DraftError>[];
  if (draft.amountMinor <= 0) errors.add(DraftError.amountNotPositive);
  if (dateOnly(draft.occurredOn).isAfter(dateOnly(today))) {
    errors.add(DraftError.futureDate);
  }
  final expectedKind = draft.type.categoryKind;
  if (expectedKind != null) {
    if (draft.categoryId == null) {
      errors.add(DraftError.categoryRequired);
    } else if (draft.categoryKind != expectedKind) {
      errors.add(DraftError.categoryMismatch);
    }
  }
  return errors;
}
