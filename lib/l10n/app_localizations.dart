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

  /// No description provided for @chatHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get chatHistory;

  /// No description provided for @noChats.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noChats;

  /// No description provided for @photoChat.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo'**
  String get photoChat;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this conversation?'**
  String get deleteChatTitle;

  /// No description provided for @deleteChatBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed for good. Entries you saved from it stay in the ledger.'**
  String get deleteChatBody;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @pickDates.
  ///
  /// In en, this message translates to:
  /// **'Pick dates'**
  String get pickDates;

  /// No description provided for @noChatsInRange.
  ///
  /// In en, this message translates to:
  /// **'No conversations in this period'**
  String get noChatsInRange;

  /// No description provided for @authLogInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to keep your records safe.'**
  String get authLogInSubtitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account for your business.'**
  String get authSignUpSubtitle;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get nameRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordMismatch;

  /// No description provided for @authWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get authWrongCredentials;

  /// No description provided for @authEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email first. Check your inbox.'**
  String get authEmailNotConfirmed;

  /// No description provided for @authUserExists.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Log in instead.'**
  String get authUserExists;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password.'**
  String get authWeakPassword;

  /// No description provided for @authRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get authRateLimited;

  /// No description provided for @authNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect. Check your internet and try again.'**
  String get authNetwork;

  /// No description provided for @authOther.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t complete that. Please try again.'**
  String get authOther;

  /// No description provided for @checkEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkEmailTitle;

  /// No description provided for @checkEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a confirmation link to {email}. Open it, then log in here.'**
  String checkEmailBody(String email);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutTitle;

  /// No description provided for @logOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your records stay on this device.'**
  String get logOutBody;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @authEmailRejected.
  ///
  /// In en, this message translates to:
  /// **'This email address wasn\'t accepted. Please use an email you can receive mail at.'**
  String get authEmailRejected;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get phoneInvalid;

  /// No description provided for @authWrongCredentialsPhone.
  ///
  /// In en, this message translates to:
  /// **'Wrong phone number or password.'**
  String get authWrongCredentialsPhone;

  /// No description provided for @authUserExistsPhone.
  ///
  /// In en, this message translates to:
  /// **'This phone number already has an account. Log in instead.'**
  String get authUserExistsPhone;

  /// No description provided for @askHelloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String askHelloName(String name);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Check your internet connection and try again.'**
  String get saveFailed;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your records. Check your internet connection.'**
  String get loadFailed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @patternsTitle.
  ///
  /// In en, this message translates to:
  /// **'Patterns from your history'**
  String get patternsTitle;

  /// No description provided for @patternsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Worked out from months of records, not only the period above.'**
  String get patternsSubtitle;

  /// No description provided for @runwayScale.
  ///
  /// In en, this message translates to:
  /// **'{days} of {max} days'**
  String runwayScale(String days, String max);

  /// No description provided for @chartOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chartOther;

  /// No description provided for @expenseTotal.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get expenseTotal;

  /// No description provided for @usualTitle.
  ///
  /// In en, this message translates to:
  /// **'This month vs your usual'**
  String get usualTitle;

  /// No description provided for @usualSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Spending from the 1st to today, against the average of the same days in the last 3 months. Regular bills are left out.'**
  String get usualSubtitle;

  /// No description provided for @usualThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get usualThisMonth;

  /// No description provided for @usualAverage.
  ///
  /// In en, this message translates to:
  /// **'Usual'**
  String get usualAverage;

  /// No description provided for @usualAlert.
  ///
  /// In en, this message translates to:
  /// **'{category} is {percent}% higher than usual'**
  String usualAlert(String category, String percent);

  /// No description provided for @usualAlertBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} more than the usual {usual} for this point in the month.'**
  String usualAlertBody(String amount, String usual);

  /// No description provided for @usualNoAlert.
  ///
  /// In en, this message translates to:
  /// **'No category is far above its usual level.'**
  String get usualNoAlert;

  /// No description provided for @usualNoHistory.
  ///
  /// In en, this message translates to:
  /// **'Shown once you have a month of records.'**
  String get usualNoHistory;

  /// No description provided for @usualNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get usualNew;

  /// No description provided for @recurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Regular payments'**
  String get recurringTitle;

  /// No description provided for @recurringSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses you pay about once a month. They aren\'t counted as surprises above.'**
  String get recurringSubtitle;

  /// No description provided for @recurringUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Due in the next 7 days: {amount}'**
  String recurringUpcoming(String amount);

  /// No description provided for @recurringNoneSoon.
  ///
  /// In en, this message translates to:
  /// **'Nothing due in the next 7 days.'**
  String get recurringNoneSoon;

  /// No description provided for @recurringDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get recurringDueToday;

  /// No description provided for @recurringDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get recurringDueTomorrow;

  /// No description provided for @recurringDueIn.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String recurringDueIn(String days);

  /// No description provided for @recurringLate.
  ///
  /// In en, this message translates to:
  /// **'Not paid yet'**
  String get recurringLate;

  /// No description provided for @recurringPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get recurringPaid;

  /// No description provided for @recurringEvery.
  ///
  /// In en, this message translates to:
  /// **'About {amount} around day {day}'**
  String recurringEvery(String amount, String day);

  /// No description provided for @recurringNone.
  ///
  /// In en, this message translates to:
  /// **'Regular payments appear after about 3 months of records.'**
  String get recurringNone;

  /// No description provided for @withdrawChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Profit vs money taken out'**
  String get withdrawChartTitle;

  /// No description provided for @chartProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get chartProfit;

  /// No description provided for @chartWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Taken out'**
  String get chartWithdrawn;

  /// No description provided for @withdrawThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month you took out {withdrawn} but the business made {profit} profit.'**
  String withdrawThisMonth(String withdrawn, String profit);

  /// No description provided for @withdrawMonthsOver.
  ///
  /// In en, this message translates to:
  /// **'In {count} of the last 6 months you took out more than the business made.'**
  String withdrawMonthsOver(String count);

  /// No description provided for @withdrawNeverOver.
  ///
  /// In en, this message translates to:
  /// **'In the last 6 months you never took out more than the business made.'**
  String get withdrawNeverOver;

  /// No description provided for @weekdayTitle.
  ///
  /// In en, this message translates to:
  /// **'Best and worst days'**
  String get weekdayTitle;

  /// No description provided for @weekdaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Average income on each day, last 12 weeks.'**
  String get weekdaySubtitle;

  /// No description provided for @weekdayRatio.
  ///
  /// In en, this message translates to:
  /// **'{best} brings in {ratio}× the income of {worst}.'**
  String weekdayRatio(String best, String ratio, String worst);

  /// No description provided for @weekdayNoIncome.
  ///
  /// In en, this message translates to:
  /// **'{best} brings in the most; {worst} usually has none.'**
  String weekdayNoIncome(String best, String worst);

  /// No description provided for @seasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Income through the year'**
  String get seasonTitle;

  /// No description provided for @seasonPeaks.
  ///
  /// In en, this message translates to:
  /// **'Income peaks in {peak} and is lowest in {low}. Save during the busy months for the lean ones.'**
  String seasonPeaks(String peak, String low);

  /// No description provided for @seasonNeedYear.
  ///
  /// In en, this message translates to:
  /// **'Busy and lean months are named after a full year of records.'**
  String get seasonNeedYear;

  /// No description provided for @sampleData.
  ///
  /// In en, this message translates to:
  /// **'Sample data'**
  String get sampleData;

  /// No description provided for @loadSampleData.
  ///
  /// In en, this message translates to:
  /// **'Load sample data'**
  String get loadSampleData;

  /// No description provided for @loadSampleHelp.
  ///
  /// In en, this message translates to:
  /// **'Adds two years of example records for a shop with a rice field, so every dashboard chart has something to show.'**
  String get loadSampleHelp;

  /// No description provided for @loadSampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add sample data?'**
  String get loadSampleTitle;

  /// No description provided for @loadSampleBody.
  ///
  /// In en, this message translates to:
  /// **'This adds about {count} example entries to this account. Entries can be voided but not deleted, so use a test account to keep your real records clean.'**
  String loadSampleBody(String count);

  /// No description provided for @loadSampleDone.
  ///
  /// In en, this message translates to:
  /// **'Added {count} sample entries.'**
  String loadSampleDone(String count);

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @incomeTotal.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get incomeTotal;

  /// No description provided for @topSellersTitle.
  ///
  /// In en, this message translates to:
  /// **'Top sellers'**
  String get topSellersTitle;

  /// No description provided for @topSellersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Income by item, from the description of each entry.'**
  String get topSellersSubtitle;

  /// No description provided for @topSellerShare.
  ///
  /// In en, this message translates to:
  /// **'{item} brings in {percent}% of your income.'**
  String topSellerShare(String item, String percent);

  /// No description provided for @topSellerRising.
  ///
  /// In en, this message translates to:
  /// **'{item} grew the most: {change} vs the previous period.'**
  String topSellerRising(String item, String change);

  /// No description provided for @salesCount.
  ///
  /// In en, this message translates to:
  /// **'sold {count} times'**
  String salesCount(String count);

  /// No description provided for @otherItems.
  ///
  /// In en, this message translates to:
  /// **'{count} other items'**
  String otherItems(String count);

  /// No description provided for @topSellersEmpty.
  ///
  /// In en, this message translates to:
  /// **'When you record income, add a description such as \"Rice\" or \"Drinks\" to see what sells best.'**
  String get topSellersEmpty;

  /// No description provided for @navExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get navExport;

  /// No description provided for @exportPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Export reports'**
  String get exportPageTitle;

  /// No description provided for @exportPageIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose a report, pick the options and save it as a PDF.'**
  String get exportPageIntro;

  /// No description provided for @reportAccountStatement.
  ///
  /// In en, this message translates to:
  /// **'Account statement'**
  String get reportAccountStatement;

  /// No description provided for @reportAccountStatementDesc.
  ///
  /// In en, this message translates to:
  /// **'Every entry with the running cash balance.'**
  String get reportAccountStatementDesc;

  /// No description provided for @reportIncomeStatement.
  ///
  /// In en, this message translates to:
  /// **'Income statement'**
  String get reportIncomeStatement;

  /// No description provided for @reportIncomeStatementDesc.
  ///
  /// In en, this message translates to:
  /// **'Income, expenses and profit by category.'**
  String get reportIncomeStatementDesc;

  /// No description provided for @reportCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash flow report'**
  String get reportCashFlow;

  /// No description provided for @reportCashFlowDesc.
  ///
  /// In en, this message translates to:
  /// **'Cash in and out, month by month.'**
  String get reportCashFlowDesc;

  /// No description provided for @reportLoanSummary.
  ///
  /// In en, this message translates to:
  /// **'Loan-ready financial summary'**
  String get reportLoanSummary;

  /// No description provided for @reportLoanSummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'The key figures a bank or microfinance lender asks for.'**
  String get reportLoanSummaryDesc;

  /// No description provided for @reportLanguage.
  ///
  /// In en, this message translates to:
  /// **'Report language'**
  String get reportLanguage;

  /// No description provided for @periodLast12Months.
  ///
  /// In en, this message translates to:
  /// **'Last 12 months'**
  String get periodLast12Months;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessName;

  /// No description provided for @ownerName.
  ///
  /// In en, this message translates to:
  /// **'Owner name'**
  String get ownerName;

  /// No description provided for @savePdf.
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get savePdf;

  /// No description provided for @isIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get isIncome;

  /// No description provided for @isExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get isExpenses;

  /// No description provided for @isTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total expenses'**
  String get isTotalExpenses;

  /// No description provided for @isNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Net profit (loss)'**
  String get isNetProfit;

  /// No description provided for @isMargin.
  ///
  /// In en, this message translates to:
  /// **'Profit margin'**
  String get isMargin;

  /// No description provided for @colThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get colThisPeriod;

  /// No description provided for @colPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get colPrevious;

  /// No description provided for @colChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get colChange;

  /// No description provided for @isComparedWith.
  ///
  /// In en, this message translates to:
  /// **'Previous period: {from} – {to}'**
  String isComparedWith(String from, String to);

  /// No description provided for @isOwnerNote.
  ///
  /// In en, this message translates to:
  /// **'Owner contributions ({contributed}) and withdrawals ({withdrawn}) move cash but are not business income or expenses, so they are not included above.'**
  String isOwnerNote(String contributed, String withdrawn);

  /// No description provided for @reportBasisNote.
  ///
  /// In en, this message translates to:
  /// **'Cash basis: income and expenses are counted on the day money is received or paid. Voided entries are left out. Prepared from the owner\'s own records; not audited.'**
  String get reportBasisNote;

  /// No description provided for @cfOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening cash'**
  String get cfOpening;

  /// No description provided for @cfCashIn.
  ///
  /// In en, this message translates to:
  /// **'Cash in'**
  String get cfCashIn;

  /// No description provided for @cfCashOut.
  ///
  /// In en, this message translates to:
  /// **'Cash out'**
  String get cfCashOut;

  /// No description provided for @cfOwnerIn.
  ///
  /// In en, this message translates to:
  /// **'Owner contributions'**
  String get cfOwnerIn;

  /// No description provided for @cfOwnerOut.
  ///
  /// In en, this message translates to:
  /// **'Owner withdrawals'**
  String get cfOwnerOut;

  /// No description provided for @cfTotalIn.
  ///
  /// In en, this message translates to:
  /// **'Total cash in'**
  String get cfTotalIn;

  /// No description provided for @cfTotalOut.
  ///
  /// In en, this message translates to:
  /// **'Total cash out'**
  String get cfTotalOut;

  /// No description provided for @cfNet.
  ///
  /// In en, this message translates to:
  /// **'Net change in cash'**
  String get cfNet;

  /// No description provided for @cfClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing cash'**
  String get cfClosing;

  /// No description provided for @cfByMonth.
  ///
  /// In en, this message translates to:
  /// **'Month by month'**
  String get cfByMonth;

  /// No description provided for @colMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get colMonth;

  /// No description provided for @colNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get colNet;

  /// No description provided for @cfNoOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening and closing cash need an opening cash amount dated on or before the start of the period (Settings → Opening cash).'**
  String get cfNoOpening;

  /// No description provided for @lsBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get lsBusiness;

  /// No description provided for @lsOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get lsOwner;

  /// No description provided for @lsRecordsSince.
  ///
  /// In en, this message translates to:
  /// **'Records kept since'**
  String get lsRecordsSince;

  /// No description provided for @lsKeyFigures.
  ///
  /// In en, this message translates to:
  /// **'Key figures'**
  String get lsKeyFigures;

  /// No description provided for @lsAveragesNote.
  ///
  /// In en, this message translates to:
  /// **'Monthly averages are over the {count} finished months of the period.'**
  String lsAveragesNote(String count);

  /// No description provided for @lsAvgIncome.
  ///
  /// In en, this message translates to:
  /// **'Average monthly income'**
  String get lsAvgIncome;

  /// No description provided for @lsAvgExpenses.
  ///
  /// In en, this message translates to:
  /// **'Average monthly expenses'**
  String get lsAvgExpenses;

  /// No description provided for @lsAvgProfit.
  ///
  /// In en, this message translates to:
  /// **'Average monthly profit'**
  String get lsAvgProfit;

  /// No description provided for @lsAvgWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'Average monthly owner withdrawals'**
  String get lsAvgWithdrawals;

  /// No description provided for @lsAvgSurplus.
  ///
  /// In en, this message translates to:
  /// **'Average monthly cash left after withdrawals'**
  String get lsAvgSurplus;

  /// No description provided for @lsProfitableMonths.
  ///
  /// In en, this message translates to:
  /// **'Profitable months'**
  String get lsProfitableMonths;

  /// No description provided for @lsOutOf.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total}'**
  String lsOutOf(String count, String total);

  /// No description provided for @lsRunway.
  ///
  /// In en, this message translates to:
  /// **'Cash runway'**
  String get lsRunway;

  /// No description provided for @lsDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String lsDays(String days);

  /// No description provided for @lsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly results'**
  String get lsMonthly;

  /// No description provided for @lsIncomeSources.
  ///
  /// In en, this message translates to:
  /// **'Main income sources'**
  String get lsIncomeSources;

  /// No description provided for @lsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get lsShare;

  /// No description provided for @lsCommitments.
  ///
  /// In en, this message translates to:
  /// **'Regular monthly payments (including existing loans)'**
  String get lsCommitments;

  /// No description provided for @lsCommitmentsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total per month'**
  String get lsCommitmentsTotal;

  /// No description provided for @lsNoCommitments.
  ///
  /// In en, this message translates to:
  /// **'No regular monthly payments were found in the records.'**
  String get lsNoCommitments;

  /// No description provided for @lsDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Usual day'**
  String get lsDayOfMonth;

  /// No description provided for @lsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Prepared by the business owner from their own records using SME Financial Copilot. Figures are on a cash basis and have not been audited.'**
  String get lsDisclaimer;
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
