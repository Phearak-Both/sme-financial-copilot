// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SME Copilot';

  @override
  String get navHome => 'Home';

  @override
  String get navLedger => 'Ledger';

  @override
  String get navSettings => 'Settings';

  @override
  String get thisMonth => 'This month';

  @override
  String get moneyIn => 'Money in';

  @override
  String get moneyOut => 'Money out';

  @override
  String get profitCash => 'Profit (cash)';

  @override
  String get netCashFlow => 'Net cash flow';

  @override
  String get ownerMovements => 'Owner in / out';

  @override
  String get summaryFootnote =>
      'Totals are shown per currency. KHR and USD are never added together.';

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return '$_temp0';
  }

  @override
  String get homeEmptyTitle => 'No records yet';

  @override
  String get homeEmptyBody =>
      'Record your first sale or expense to see this month\'s money in, money out and profit.';

  @override
  String get recent => 'Recent';

  @override
  String get viewAll => 'View all';

  @override
  String get typeIncome => 'Income';

  @override
  String get typeExpense => 'Expense';

  @override
  String get typeOwnerContribution => 'Owner put money in';

  @override
  String get typeOwnerWithdrawal => 'Owner took money out';

  @override
  String get ownerHelp =>
      'Personal money moving into or out of the business. It changes cash but is not counted in profit.';

  @override
  String get newEntry => 'New entry';

  @override
  String get editEntry => 'Edit entry';

  @override
  String get entryDetails => 'Entry details';

  @override
  String get amount => 'Amount';

  @override
  String get currency => 'Currency';

  @override
  String get category => 'Category';

  @override
  String get date => 'Date';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'e.g. Bought fertilizer';

  @override
  String get note => 'Note';

  @override
  String get paymentMethod => 'Paid by';

  @override
  String get pmCash => 'Cash';

  @override
  String get pmBank => 'Bank';

  @override
  String get pmMobileWallet => 'Mobile wallet';

  @override
  String get pmOther => 'Other';

  @override
  String get notSet => 'Not set';

  @override
  String get uncategorized => 'No category';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get voidAction => 'Void';

  @override
  String get voidTitle => 'Void this entry?';

  @override
  String get voidBody =>
      'It stays in the history but no longer counts in any total.';

  @override
  String get voidReason => 'Reason (optional)';

  @override
  String get voided => 'Voided';

  @override
  String get errorAmountEmpty => 'Enter an amount';

  @override
  String get errorAmountInvalid => 'Enter a valid number';

  @override
  String errorAmountDecimals(String currency) {
    return 'Too many decimal places for $currency';
  }

  @override
  String get errorAmountPositive => 'Amount must be more than zero';

  @override
  String get errorAmountTooLarge => 'Amount is too large';

  @override
  String get errorFutureDate => 'The date can\'t be in the future';

  @override
  String get errorCategory => 'Choose a category';

  @override
  String get duplicateTitle => 'Possible duplicate';

  @override
  String duplicateBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count entries with the same amount, currency and date already exist.',
      one: 'An entry with the same amount, currency and date already exists.',
    );
    return '$_temp0 Save anyway?';
  }

  @override
  String get saveAnyway => 'Save anyway';

  @override
  String get savedMessage => 'Saved';

  @override
  String get updatedMessage => 'Updated';

  @override
  String get voidedMessage => 'Entry voided';

  @override
  String get searchHint => 'Search description or note';

  @override
  String get filterAll => 'All';

  @override
  String get showVoided => 'Show voided';

  @override
  String get ledgerEmptyFiltered => 'No entries match these filters.';

  @override
  String get ledgerEmpty => 'No entries yet. Tap + to record one.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get history => 'History';

  @override
  String get revisionCreate => 'Created';

  @override
  String get revisionEdit => 'Edited';

  @override
  String get revisionVoided => 'Voided';

  @override
  String versionLabel(int version) {
    return 'Version $version';
  }

  @override
  String get source => 'Source';

  @override
  String get sourceManual => 'Entered by hand';

  @override
  String get sourceText => 'Typed to assistant';

  @override
  String get sourceVoice => 'Voice';

  @override
  String get sourceReceipt => 'Receipt photo';

  @override
  String get language => 'Language';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get somethingWrong => 'Something went wrong. Please try again.';

  @override
  String get entryNotFound => 'This entry no longer exists.';
}
