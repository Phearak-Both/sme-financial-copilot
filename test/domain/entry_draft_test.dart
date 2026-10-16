import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/domain/entry_draft.dart';
import 'package:sme_financial_copilot/domain/enums.dart';

void main() {
  final today = DateTime(2026, 10, 16, 15, 30);

  EntryDraft draft({
    EntryType type = EntryType.expense,
    int amount = 500,
    DateTime? date,
    String? categoryId = 'transport',
    CategoryKind? kind = CategoryKind.expense,
  }) =>
      EntryDraft(
        type: type,
        amountMinor: amount,
        currency: Currency.usd,
        occurredOn: date ?? DateTime(2026, 10, 16),
        categoryId: categoryId,
        categoryKind: kind,
      );

  test('valid expense passes', () {
    expect(validateDraft(draft(), today: today), isEmpty);
  });

  test('rejects zero amount and future dates', () {
    expect(validateDraft(draft(amount: 0), today: today),
        contains(DraftError.amountNotPositive));
    expect(validateDraft(draft(date: DateTime(2026, 10, 17)), today: today),
        contains(DraftError.futureDate));
  });

  test('income and expense need a matching category', () {
    expect(validateDraft(draft(categoryId: null, kind: null), today: today),
        contains(DraftError.categoryRequired));
    expect(
      validateDraft(draft(type: EntryType.income), today: today),
      contains(DraftError.categoryMismatch),
    );
  });

  test('owner movements need no category', () {
    expect(
      validateDraft(
        draft(type: EntryType.ownerWithdrawal, categoryId: null, kind: null),
        today: today,
      ),
      isEmpty,
    );
  });
}
