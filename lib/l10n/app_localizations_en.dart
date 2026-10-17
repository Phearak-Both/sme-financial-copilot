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
  String get navLedger => 'Ledger';

  @override
  String get navSettings => 'Settings';

  @override
  String get moneyIn => 'Money in';

  @override
  String get moneyOut => 'Money out';

  @override
  String get profitCash => 'Profit (cash)';

  @override
  String get netCashFlow => 'Net cash flow';

  @override
  String get summaryFootnote =>
      'Totals are shown per currency. KHR and USD are never added together.';

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
  String get voidReason => 'Reason';

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
  String get searchHint => 'Search';

  @override
  String get filterAll => 'All';

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

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get periodThisMonth => 'This month';

  @override
  String get periodLastMonth => 'Last month';

  @override
  String get periodLast3Months => 'Last 3 months';

  @override
  String get periodThisYear => 'This year';

  @override
  String get cashOnHand => 'Cash on hand';

  @override
  String get cashOnHandHint =>
      'Set your opening cash to see how much money the business has now.';

  @override
  String get openingCash => 'Opening cash';

  @override
  String get openingCashHelp =>
      'How much cash the business had at the start of a date. Cash on hand = opening cash + money in − money out from that date.';

  @override
  String get asOf => 'As of';

  @override
  String asOfValue(String amount, String date) {
    return '$amount as of $date';
  }

  @override
  String get clear => 'Clear';

  @override
  String get negativeBalanceWarning =>
      'Recorded cash is below zero. Some money in may be missing, or the opening cash may be wrong.';

  @override
  String vsComparison(String change) {
    return '$change vs same days before';
  }

  @override
  String vsComparisonFull(String change) {
    return '$change vs previous period';
  }

  @override
  String get noComparison => 'No earlier records to compare';

  @override
  String get trendTitle => 'Last 6 months';

  @override
  String get expenseBreakdown => 'Where money went';

  @override
  String get noExpenses => 'No expenses in this period.';

  @override
  String dashboardEmpty(String currency) {
    return 'No $currency records in this period.';
  }

  @override
  String otherCurrencyHint(String currency) {
    return 'There are $currency records in this period.';
  }

  @override
  String showCurrency(String currency) {
    return 'Show $currency';
  }

  @override
  String get dashboardFootnote =>
      'Cash basis: money is counted on the day it is received or paid. Money the owner puts in or takes out is not counted in profit.';

  @override
  String get trendSemantics =>
      'Bar chart of money in and money out for the last 6 months.';

  @override
  String percentOfTotal(int percent) {
    return '$percent% of money out';
  }

  @override
  String filterActiveRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get demoSection => 'Demo';

  @override
  String get loadSampleData => 'Load sample data';

  @override
  String get loadSampleDataBody =>
      'Adds about 3 months of example shop and farm records in USD and KHR, plus opening cash, so you can try the app. Only available while the ledger is empty.';

  @override
  String sampleDataLoaded(int count) {
    return '$count sample records added';
  }

  @override
  String get navAsk => 'Assistant';

  @override
  String get askTitle => 'Assistant';

  @override
  String get askWelcomeTitle => 'Hello!\nHow can I help you?';

  @override
  String get askHint => 'Record or ask…';

  @override
  String get askSend => 'Send';

  @override
  String get askMicTooltip => 'Record a voice note';

  @override
  String get askPhotoTooltip => 'Photo of a receipt';

  @override
  String get askTakePhoto => 'Take a photo';

  @override
  String get askChoosePhoto => 'Choose from photos';

  @override
  String get askMicDenied =>
      'Microphone access is off. Allow it in system settings to use voice.';

  @override
  String get askThinking => 'Thinking…';

  @override
  String askHeard(String text) {
    return 'Heard: “$text”';
  }

  @override
  String get askProposalTitle =>
      'Here\'s what I understood. Check it before saving.';

  @override
  String get askAmountMissing => 'Amount not found';

  @override
  String get askCurrencyUnknown =>
      'Currency not stated. You\'ll choose it on the next screen.';

  @override
  String get askNoRecords => 'No records in this period yet.';

  @override
  String get askCashUnknown =>
      'Cash on hand is unknown. Set your opening cash in Settings first.';

  @override
  String askCalculatedFrom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Calculated from $count records',
      one: 'Calculated from 1 record',
      zero: 'No records used',
    );
    return '$_temp0';
  }

  @override
  String get askNewChat => 'New conversation';

  @override
  String get askError =>
      'Sorry, something went wrong. Check your internet connection and try again.';

  @override
  String get askQuota =>
      'The free AI limit was reached. Please wait a minute and try again.';

  @override
  String get askNotConfigured =>
      'AI is not set up. Run the app with --dart-define-from-file=env/dev.json.';

  @override
  String get aiConsentTitle => 'Before using the assistant';

  @override
  String get aiConsentBody =>
      'To understand you, the text, voice recording or photo you send is processed by Google Gemini. Only the totals needed to answer a question are sent, never your whole ledger. On the free tier Google may use this data to improve its products, so use test data for now.';

  @override
  String get aiConsentAgree => 'I understand';

  @override
  String get proposalReviewHint =>
      'Filled in by the assistant. Check every field, then save.';

  @override
  String get confirmCurrency => 'Please choose the currency.';

  @override
  String get askRecordingFailed =>
      'The recording couldn\'t be saved. Please try again.';

  @override
  String get askTranscribing => 'Turning your voice into text…';

  @override
  String get askTranscribeFailed =>
      'Couldn\'t turn the recording into text. Please try again or type it.';

  @override
  String get askNothingHeard => 'I couldn\'t hear anything. Please try again.';

  @override
  String get askListening => 'Listening… start talking';

  @override
  String get askDoneTalking => 'Done talking';

  @override
  String askRead(String text) {
    return 'Read: “$text”';
  }
}
