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

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

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

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

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
  /// **'Profit (cash)'**
  String get profitCash;

  /// No description provided for @netCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Net cash flow'**
  String get netCashFlow;

  /// No description provided for @ownerMovements.
  ///
  /// In en, this message translates to:
  /// **'Owner in / out'**
  String get ownerMovements;

  /// No description provided for @summaryFootnote.
  ///
  /// In en, this message translates to:
  /// **'Totals are shown per currency. KHR and USD are never added together.'**
  String get summaryFootnote;

  /// No description provided for @entriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record} other{{count} records}}'**
  String entriesCount(int count);

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Record your first sale or expense to see this month\'s money in, money out and profit.'**
  String get homeEmptyBody;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

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
  /// **'Reason (optional)'**
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
  /// **'Search description or note'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @showVoided.
  ///
  /// In en, this message translates to:
  /// **'Show voided'**
  String get showVoided;

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

  /// No description provided for @setOpeningCash.
  ///
  /// In en, this message translates to:
  /// **'Set opening cash'**
  String get setOpeningCash;

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
  /// **'Last 6 months'**
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
  /// **'Bar chart of money in and money out for the last 6 months.'**
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
