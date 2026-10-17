import '../core/money/currency.dart';
import 'enums.dart';

/// An entry suggested by the assistant. It is never saved directly: it
/// pre-fills the entry form, and the user reviews and confirms it there.
///
/// Fields the assistant could not determine are null, so the form can ask
/// for them instead of guessing.
class EntryProposal {
  const EntryProposal({
    required this.type,
    required this.source,
    this.amountText,
    this.currency,
    this.occurredOn,
    this.categoryId,
    this.description = '',
    this.paymentMethod,
    this.rawInput,
  });

  final EntryType type;
  final EntrySource source;

  /// Amount in major units as ASCII digits, e.g. "12.50". Parsed by the form
  /// with the same deterministic parser as manual entry.
  final String? amountText;

  /// Null when the input didn't say which currency.
  final Currency? currency;
  final DateTime? occurredOn;
  final String? categoryId;
  final String description;
  final PaymentMethod? paymentMethod;

  /// What the user typed, said (transcript) or what the receipt showed.
  final String? rawInput;
}
