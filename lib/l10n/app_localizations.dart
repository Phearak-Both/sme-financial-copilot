import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SME Copilot'**
  String get appTitle;

  /// No description provided for @navLedger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get navLedger;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @moneyIn.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get moneyIn;

  /// No description provided for @moneyOut.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get moneyOut;

  /// No description provided for @profitCash.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profitCash;

  /// No description provided for @netCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Net cash flow'**
  String get netCashFlow;

  /// No description provided for @summaryFootnote.
  ///
  /// In en, this message translates to:
  /// **'Totals are shown per currency. KHR and USD are never added together.'**
  String get summaryFootnote;

  /// No description provided for @typeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get typeIncome;

  /// No description provided for @typeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get typeExpense;

  /// No description provided for @typeOwnerContribution.
  ///
  /// In en, this message translates to:
  /// **'Owner put money in'**
  String get typeOwnerContribution;

  /// No description provided for @typeOwnerWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Owner took money out'**
  String get typeOwnerWithdrawal;

  /// No description provided for @ownerHelp.
  ///
  /// In en, this message translates to:
  /// **'Personal money moving into or out of the business. It changes cash but is not counted in profit.'**
  String get ownerHelp;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get newEntry;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// No description provided for @entryDetails.
  ///
  /// In en, this message translates to:
  /// **'Entry details'**
  String get entryDetails;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bought fertilizer'**
  String get descriptionHint;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paymentMethod;

  /// No description provided for @pmCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get pmCash;

  /// No description provided for @pmBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get pmBank;

  /// No description provided for @pmMobileWallet.
  ///
  /// In en, this message translates to:
  /// **'Mobile wallet'**
  String get pmMobileWallet;

  /// No description provided for @pmOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get pmOther;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get uncategorized;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @voidAction.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get voidAction;

  /// No description provided for @voidTitle.
  ///
  /// In en, this message translates to:
  /// **'Void this entry?'**
  String get voidTitle;

  /// No description provided for @voidBody.
  ///
  /// In en, this message translates to:
  /// **'It stays in the history but no longer counts in any total.'**
  String get voidBody;

  /// No description provided for @voidReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get voidReason;

  /// No description provided for @voided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get voided;

  /// No description provided for @errorAmountEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get errorAmountEmpty;

  /// No description provided for @errorAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get errorAmountInvalid;

  /// No description provided for @errorAmountDecimals.
  ///
  /// In en, this message translates to:
  /// **'Too many decimal places for {currency}'**
  String errorAmountDecimals(String currency);

  /// No description provided for @errorAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be more than zero'**
  String get errorAmountPositive;

  /// No description provided for @errorAmountTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Amount is too large'**
  String get errorAmountTooLarge;

  /// No description provided for @errorFutureDate.
  ///
  /// In en, this message translates to:
  /// **'The date can\'t be in the future'**
  String get errorFutureDate;

  /// No description provided for @errorCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get errorCategory;

  /// No description provided for @duplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get duplicateTitle;

  /// No description provided for @duplicateBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{An entry with the same amount, currency and date already exists.} other{{count} entries with the same amount, currency and date already exist.}} Save anyway?'**
  String duplicateBody(int count);

  /// No description provided for @saveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get saveAnyway;

  /// No description provided for @savedMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedMessage;

  /// No description provided for @updatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedMessage;

  /// No description provided for @voidedMessage.
  ///
  /// In en, this message translates to:
  /// **'Entry voided'**
  String get voidedMessage;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @ledgerEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No entries match these filters.'**
  String get ledgerEmptyFiltered;

  /// No description provided for @ledgerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet. Tap + to record one.'**
  String get ledgerEmpty;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @revisionCreate.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get revisionCreate;

  /// No description provided for @revisionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get revisionEdit;

  /// No description provided for @revisionVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get revisionVoided;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(int version);

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @sourceManual.
  ///
  /// In en, this message translates to:
  /// **'Entered by hand'**
  String get sourceManual;

  /// No description provided for @sourceText.
  ///
  /// In en, this message translates to:
  /// **'Typed to assistant'**
  String get sourceText;

  /// No description provided for @sourceVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get sourceVoice;

  /// No description provided for @sourceReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo'**
  String get sourceReceipt;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWrong;

  /// No description provided for @entryNotFound.
  ///
  /// In en, this message translates to:
  /// **'This entry no longer exists.'**
  String get entryNotFound;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @periodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get periodThisMonth;

  /// No description provided for @periodLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get periodLastMonth;

  /// No description provided for @periodLast3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get periodLast3Months;

  /// No description provided for @periodThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get periodThisYear;

  /// No description provided for @cashOnHand.
  ///
  /// In en, this message translates to:
  /// **'Cash on hand'**
  String get cashOnHand;

  /// No description provided for @cashOnHandHint.
  ///
  /// In en, this message translates to:
  /// **'Set your opening cash to see how much money the business has now.'**
  String get cashOnHandHint;

  /// No description provided for @openingCash.
  ///
  /// In en, this message translates to:
  /// **'Opening cash'**
  String get openingCash;

  /// No description provided for @openingCashHelp.
  ///
  /// In en, this message translates to:
  /// **'How much cash the business had at the start of a date. Cash on hand = opening cash + money in − money out from that date.'**
  String get openingCashHelp;

  /// No description provided for @asOf.
  ///
  /// In en, this message translates to:
  /// **'As of'**
  String get asOf;

  /// No description provided for @asOfValue.
  ///
  /// In en, this message translates to:
  /// **'{amount} as of {date}'**
  String asOfValue(String amount, String date);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @negativeBalanceWarning.
  ///
  /// In en, this message translates to:
  /// **'Recorded cash is below zero. Some money in may be missing, or the opening cash may be wrong.'**
  String get negativeBalanceWarning;

  /// No description provided for @vsComparison.
  ///
  /// In en, this message translates to:
  /// **'{change} vs same days before'**
  String vsComparison(String change);

  /// No description provided for @vsComparisonFull.
  ///
  /// In en, this message translates to:
  /// **'{change} vs previous period'**
  String vsComparisonFull(String change);

  /// No description provided for @noComparison.
  ///
  /// In en, this message translates to:
  /// **'No earlier records to compare'**
  String get noComparison;

  /// No description provided for @trendTitle.
  ///
  /// In en, this message translates to:
  /// **'Money in and out'**
  String get trendTitle;

  /// No description provided for @expenseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Where money went'**
  String get expenseBreakdown;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period.'**
  String get noExpenses;

  /// No description provided for @dashboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No {currency} records in this period.'**
  String dashboardEmpty(String currency);

  /// No description provided for @otherCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'There are {currency} records in this period.'**
  String otherCurrencyHint(String currency);

  /// No description provided for @showCurrency.
  ///
  /// In en, this message translates to:
  /// **'Show {currency}'**
  String showCurrency(String currency);

  /// No description provided for @dashboardFootnote.
  ///
  /// In en, this message translates to:
  /// **'Cash basis: money is counted on the day it is received or paid. Money the owner puts in or takes out is not counted in profit.'**
  String get dashboardFootnote;

  /// No description provided for @trendSemantics.
  ///
  /// In en, this message translates to:
  /// **'Bar chart of money in and money out for the selected period.'**
  String get trendSemantics;

  /// No description provided for @percentOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of money out'**
  String percentOfTotal(int percent);

  /// No description provided for @filterActiveRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String filterActiveRange(String start, String end);

  /// No description provided for @navAsk.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get navAsk;

  /// No description provided for @askTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get askTitle;

  /// No description provided for @askWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hello!\nHow can I help you?'**
  String get askWelcomeTitle;

  /// No description provided for @askHint.
  ///
  /// In en, this message translates to:
  /// **'Record or ask…'**
  String get askHint;

  /// No description provided for @askSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get askSend;

  /// No description provided for @askMicTooltip.
  ///
  /// In en, this message translates to:
  /// **'Record a voice note'**
  String get askMicTooltip;

  /// No description provided for @askPhotoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Photo of a receipt'**
  String get askPhotoTooltip;

  /// No description provided for @askTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get askTakePhoto;

  /// No description provided for @askChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose from photos'**
  String get askChoosePhoto;

  /// No description provided for @askMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off. Allow it in system settings to use voice.'**
  String get askMicDenied;

  /// No description provided for @askThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get askThinking;

  /// No description provided for @askAmountMissing.
  ///
  /// In en, this message translates to:
  /// **'Amount not found'**
  String get askAmountMissing;

  /// No description provided for @askCurrencyUnknown.
  ///
  /// In en, this message translates to:
  /// **'Currency not stated. You\'ll choose it on the next screen.'**
  String get askCurrencyUnknown;

  /// No description provided for @askNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No records in this period yet.'**
  String get askNoRecords;

  /// No description provided for @askCashUnknown.
  ///
  /// In en, this message translates to:
  /// **'Cash on hand is unknown. Set your opening cash in Settings first.'**
  String get askCashUnknown;

  /// No description provided for @askCalculatedFrom.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No records used} =1{Calculated from 1 record} other{Calculated from {count} records}}'**
  String askCalculatedFrom(int count);

  /// No description provided for @askNewChat.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get askNewChat;

  /// No description provided for @askError.
  ///
  /// In en, this message translates to:
  /// **'Sorry, something went wrong. Check your internet connection and try again.'**
  String get askError;

  /// No description provided for @askQuota.
  ///
  /// In en, this message translates to:
  /// **'The free AI limit was reached. Please wait a minute and try again.'**
  String get askQuota;

  /// No description provided for @askNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'AI is not set up. Run the app with --dart-define-from-file=env/dev.json.'**
  String get askNotConfigured;

  /// No description provided for @aiConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Before using the assistant'**
  String get aiConsentTitle;

  /// No description provided for @aiConsentBody.
  ///
  /// In en, this message translates to:
  /// **'To understand you, the text, voice recording or photo you send is processed by Google Gemini. Only the totals needed to answer a question are sent, never your whole ledger. On the free tier Google may use this data to improve its products, so use test data for now.'**
  String get aiConsentBody;

  /// No description provided for @aiConsentAgree.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get aiConsentAgree;

  /// No description provided for @proposalReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Filled in by the assistant. Check every field, then save.'**
  String get proposalReviewHint;

  /// No description provided for @confirmCurrency.
  ///
  /// In en, this message translates to:
  /// **'Please choose the currency.'**
  String get confirmCurrency;

  /// No description provided for @askRecordingFailed.
  ///
  /// In en, this message translates to:
  /// **'The recording couldn\'t be saved. Please try again.'**
  String get askRecordingFailed;

  /// No description provided for @askTranscribing.
  ///
  /// In en, this message translates to:
  /// **'Turning your voice into text…'**
  String get askTranscribing;

  /// No description provided for @askTranscribeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t turn the recording into text. Please try again or type it.'**
  String get askTranscribeFailed;

  /// No description provided for @askNothingHeard.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t hear anything. Please try again.'**
  String get askNothingHeard;

  /// No description provided for @askListening.
  ///
  /// In en, this message translates to:
  /// **'Listening… start talking'**
  String get askListening;

  /// No description provided for @askDoneTalking.
  ///
  /// In en, this message translates to:
  /// **'Done talking'**
  String get askDoneTalking;

  /// No description provided for @askRead.
  ///
  /// In en, this message translates to:
  /// **'Read: “{text}”'**
  String askRead(String text);

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the PDF. Please try again.'**
  String get exportFailed;

  /// No description provided for @glTitle.
  ///
  /// In en, this message translates to:
  /// **'General Ledger'**
  String get glTitle;

  /// No description provided for @glAccount.
  ///
  /// In en, this message translates to:
  /// **'Cash account ({currency})'**
  String glAccount(String currency);

  /// No description provided for @glNo.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get glNo;

  /// No description provided for @glDebit.
  ///
  /// In en, this message translates to:
  /// **'Debit (in)'**
  String get glDebit;

  /// No description provided for @glCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit (out)'**
  String get glCredit;

  /// No description provided for @glBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get glBalance;

  /// No description provided for @glOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get glOpening;

  /// No description provided for @glTotals.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get glTotals;

  /// No description provided for @glClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing balance'**
  String get glClosing;

  /// No description provided for @glPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period: {from} – {to}'**
  String glPeriod(String from, String to);

  /// No description provided for @glGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated: {date}'**
  String glGenerated(String date);

  /// No description provided for @glVoidedNote.
  ///
  /// In en, this message translates to:
  /// **'Voided entries are not included. KHR and USD are kept in separate accounts.'**
  String get glVoidedNote;

  /// No description provided for @glNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No records yet.'**
  String get glNoEntries;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export general ledger'**
  String get exportTitle;

  /// No description provided for @exportCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get exportCurrency;

  /// No description provided for @exportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get exportPeriod;

  /// No description provided for @periodLast6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get periodLast6Months;

  /// No description provided for @periodLastYear.
  ///
  /// In en, this message translates to:
  /// **'Last year'**
  String get periodLastYear;

  /// No description provided for @exportSaved.
  ///
  /// In en, this message translates to:
  /// **'PDF saved'**
  String get exportSaved;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @insightMarginTitle.
  ///
  /// In en, this message translates to:
  /// **'Profit margin {percent}%'**
  String insightMarginTitle(String percent);

  /// No description provided for @insightMarginBody.
  ///
  /// In en, this message translates to:
  /// **'Out of every 100 you earn, you keep {percent} as profit.'**
  String insightMarginBody(String percent);

  /// No description provided for @insightLossTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending more than you earn'**
  String get insightLossTitle;

  /// No description provided for @insightLossBody.
  ///
  /// In en, this message translates to:
  /// **'Money out is {amount} more than money in for this period.'**
  String insightLossBody(String amount);

  /// No description provided for @insightWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals exceed profit'**
  String get insightWithdrawTitle;

  /// No description provided for @insightWithdrawBody.
  ///
  /// In en, this message translates to:
  /// **'You took out {withdrawn} while profit was {profit}, which lowers the business\'s cash.'**
  String insightWithdrawBody(String withdrawn, String profit);

  /// No description provided for @insightRunwayTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash lasts about {days} days'**
  String insightRunwayTitle(String days);

  /// No description provided for @insightRunwayBody.
  ///
  /// In en, this message translates to:
  /// **'At your average spending over the last 30 days.'**
  String get insightRunwayBody;

  /// No description provided for @insightRunwayLowBody.
  ///
  /// In en, this message translates to:
  /// **'At your average spending over the last 30 days. Consider keeping a bigger cash buffer.'**
  String get insightRunwayLowBody;

  /// No description provided for @insightForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Projected profit: {amount}'**
  String insightForecastTitle(String amount);

  /// No description provided for @insightForecastBody.
  ///
  /// In en, this message translates to:
  /// **'If the pace so far continues to the end of the period.'**
  String get insightForecastBody;

  /// No description provided for @insightCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'{category} spending up {percent}%'**
  String insightCategoryTitle(String category, String percent);

  /// No description provided for @insightCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} more than the previous period.'**
  String insightCategoryBody(String amount);

  /// No description provided for @insightTopIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'{category}: {percent}% of income'**
  String insightTopIncomeTitle(String category, String percent);

  /// No description provided for @insightTopIncomeBody.
  ///
  /// In en, this message translates to:
  /// **'Your biggest source of income in this period.'**
  String get insightTopIncomeBody;

  /// No description provided for @insightTopIncomeRiskBody.
  ///
  /// In en, this message translates to:
  /// **'Most of your income depends on one source. Adding others lowers the risk.'**
  String get insightTopIncomeRiskBody;

  /// No description provided for @insightNoIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'No income yet'**
  String get insightNoIncomeTitle;

  /// No description provided for @insightNoIncomeMarginBody.
  ///
  /// In en, this message translates to:
  /// **'Profit margin appears once you record income.'**
  String get insightNoIncomeMarginBody;

  /// No description provided for @insightNoIncomeSourceBody.
  ///
  /// In en, this message translates to:
  /// **'Your main income source appears once you record income.'**
  String get insightNoIncomeSourceBody;

  /// No description provided for @insightWithdrawOkTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals within profit'**
  String get insightWithdrawOkTitle;

  /// No description provided for @insightWithdrawOkBody.
  ///
  /// In en, this message translates to:
  /// **'You took out {withdrawn} of {profit} profit.'**
  String insightWithdrawOkBody(String withdrawn, String profit);

  /// No description provided for @insightNoWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'No owner withdrawals'**
  String get insightNoWithdrawTitle;

  /// No description provided for @insightNoWithdrawBody.
  ///
  /// In en, this message translates to:
  /// **'No money was taken out of the business in this period.'**
  String get insightNoWithdrawBody;

  /// No description provided for @insightRunwaySetupTitle.
  ///
  /// In en, this message translates to:
  /// **'How long will your cash last?'**
  String get insightRunwaySetupTitle;

  /// No description provided for @insightRunwaySetupBody.
  ///
  /// In en, this message translates to:
  /// **'Set opening cash in Settings to see.'**
  String get insightRunwaySetupBody;

  /// No description provided for @insightRunwayNoSpendTitle.
  ///
  /// In en, this message translates to:
  /// **'No spending in the last 30 days'**
  String get insightRunwayNoSpendTitle;

  /// No description provided for @insightRunwayNoSpendBody.
  ///
  /// In en, this message translates to:
  /// **'Cash runway is estimated from recent spending.'**
  String get insightRunwayNoSpendBody;

  /// No description provided for @insightRunwayLongTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash lasts over a year'**
  String get insightRunwayLongTitle;

  /// No description provided for @insightForecastWaitTitle.
  ///
  /// In en, this message translates to:
  /// **'Projected profit'**
  String get insightForecastWaitTitle;

  /// No description provided for @insightForecastEarlyBody.
  ///
  /// In en, this message translates to:
  /// **'Available after the first 7 days of the period.'**
  String get insightForecastEarlyBody;

  /// No description provided for @insightForecastDoneBody.
  ///
  /// In en, this message translates to:
  /// **'This period has ended. The final profit is shown above.'**
  String get insightForecastDoneBody;

  /// No description provided for @insightNoIncreaseTitle.
  ///
  /// In en, this message translates to:
  /// **'No sharp rise in spending'**
  String get insightNoIncreaseTitle;

  /// No description provided for @insightNoIncreaseBody.
  ///
  /// In en, this message translates to:
  /// **'No expense category grew by 20% or more compared with the previous period.'**
  String get insightNoIncreaseBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
