/// How a ledger entry affects the business.
///
/// Owner contributions and withdrawals move cash but are not business income
/// or expenses, which keeps personal money out of profit.
enum EntryType {
  income,
  expense,
  ownerContribution,
  ownerWithdrawal;

  bool get isMoneyIn => this == income || this == ownerContribution;
  bool get isOwnerMovement => this == ownerContribution || this == ownerWithdrawal;

  /// The category kind this type uses, or null when categories don't apply.
  CategoryKind? get categoryKind => switch (this) {
        income => CategoryKind.income,
        expense => CategoryKind.expense,
        _ => null,
      };
}

enum CategoryKind { income, expense }

enum EntrySource { manual, text, voice, receipt }

enum EntryStatus { active, voided }

enum PaymentMethod { cash, bank, mobileWallet, other }

enum RevisionKind { create, edit, voided }
