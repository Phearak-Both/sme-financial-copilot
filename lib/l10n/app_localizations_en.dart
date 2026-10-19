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
  String get profitCash => 'Profit';

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
  String get trendTitle => 'Money in and out';

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
      'Bar chart of money in and money out for the selected period.';

  @override
  String percentOfTotal(int percent) {
    return '$percent% of money out';
  }

  @override
  String filterActiveRange(String start, String end) {
    return '$start – $end';
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

  @override
  String get exportFailed => 'Couldn\'t create the PDF. Please try again.';

  @override
  String get glTitle => 'General Ledger';

  @override
  String glAccount(String currency) {
    return 'Cash account ($currency)';
  }

  @override
  String get glNo => 'No.';

  @override
  String get glDebit => 'Debit (in)';

  @override
  String get glCredit => 'Credit (out)';

  @override
  String get glBalance => 'Balance';

  @override
  String get glOpening => 'Opening balance';

  @override
  String get glTotals => 'Totals';

  @override
  String get glClosing => 'Closing balance';

  @override
  String glPeriod(String from, String to) {
    return 'Period: $from – $to';
  }

  @override
  String glGenerated(String date) {
    return 'Generated: $date';
  }

  @override
  String get glVoidedNote =>
      'Voided entries are not included. KHR and USD are kept in separate accounts.';

  @override
  String get glNoEntries => 'No records yet.';

  @override
  String get exportTitle => 'Export general ledger';

  @override
  String get exportCurrency => 'Currency';

  @override
  String get exportPeriod => 'Period';

  @override
  String get periodLast6Months => 'Last 6 months';

  @override
  String get periodLastYear => 'Last year';

  @override
  String get exportSaved => 'PDF saved';

  @override
  String get insightsTitle => 'Insights';

  @override
  String insightMarginTitle(String percent) {
    return 'Profit margin $percent%';
  }

  @override
  String insightMarginBody(String percent) {
    return 'Out of every 100 you earn, you keep $percent as profit.';
  }

  @override
  String get insightLossTitle => 'Spending more than you earn';

  @override
  String insightLossBody(String amount) {
    return 'Money out is $amount more than money in for this period.';
  }

  @override
  String get insightWithdrawTitle => 'Withdrawals exceed profit';

  @override
  String insightWithdrawBody(String withdrawn, String profit) {
    return 'You took out $withdrawn while profit was $profit, which lowers the business\'s cash.';
  }

  @override
  String insightRunwayTitle(String days) {
    return 'Cash lasts about $days days';
  }

  @override
  String get insightRunwayBody =>
      'At your average spending over the last 30 days.';

  @override
  String get insightRunwayLowBody =>
      'At your average spending over the last 30 days. Consider keeping a bigger cash buffer.';

  @override
  String insightForecastTitle(String amount) {
    return 'Projected profit: $amount';
  }

  @override
  String get insightForecastBody =>
      'If the pace so far continues to the end of the period.';

  @override
  String insightCategoryTitle(String category, String percent) {
    return '$category spending up $percent%';
  }

  @override
  String insightCategoryBody(String amount) {
    return '$amount more than the previous period.';
  }

  @override
  String insightTopIncomeTitle(String category, String percent) {
    return '$category: $percent% of income';
  }

  @override
  String get insightTopIncomeBody =>
      'Your biggest source of income in this period.';

  @override
  String get insightTopIncomeRiskBody =>
      'Most of your income depends on one source. Adding others lowers the risk.';

  @override
  String get insightNoIncomeTitle => 'No income yet';

  @override
  String get insightNoIncomeMarginBody =>
      'Profit margin appears once you record income.';

  @override
  String get insightNoIncomeSourceBody =>
      'Your main income source appears once you record income.';

  @override
  String get insightWithdrawOkTitle => 'Withdrawals within profit';

  @override
  String insightWithdrawOkBody(String withdrawn, String profit) {
    return 'You took out $withdrawn of $profit profit.';
  }

  @override
  String get insightNoWithdrawTitle => 'No owner withdrawals';

  @override
  String get insightNoWithdrawBody =>
      'No money was taken out of the business in this period.';

  @override
  String get insightRunwaySetupTitle => 'How long will your cash last?';

  @override
  String get insightRunwaySetupBody => 'Set opening cash in Settings to see.';

  @override
  String get insightRunwayNoSpendTitle => 'No spending in the last 30 days';

  @override
  String get insightRunwayNoSpendBody =>
      'Cash runway is estimated from recent spending.';

  @override
  String get insightRunwayLongTitle => 'Cash lasts over a year';

  @override
  String get insightForecastWaitTitle => 'Projected profit';

  @override
  String get insightForecastEarlyBody =>
      'Available after the first 7 days of the period.';

  @override
  String get insightForecastDoneBody =>
      'This period has ended. The final profit is shown above.';

  @override
  String get insightNoIncreaseTitle => 'No sharp rise in spending';

  @override
  String get insightNoIncreaseBody =>
      'No expense category grew by 20% or more compared with the previous period.';

  @override
  String get chatHistory => 'History';

  @override
  String get noChats => 'No conversations yet';

  @override
  String get photoChat => 'Receipt photo';

  @override
  String get delete => 'Delete';

  @override
  String get deleteChatTitle => 'Delete this conversation?';

  @override
  String get deleteChatBody =>
      'It will be removed for good. Entries you saved from it stay in the ledger.';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get last30Days => 'Last 30 days';

  @override
  String get pickDates => 'Pick dates';

  @override
  String get noChatsInRange => 'No conversations in this period';

  @override
  String get authLogInSubtitle => 'Log in to keep your records safe.';

  @override
  String get authSignUpSubtitle => 'Create an account for your business.';

  @override
  String get logIn => 'Log in';

  @override
  String get signUp => 'Sign up';

  @override
  String get fullName => 'Name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get nameRequired => 'Enter your name';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get passwordTooShort => 'Use at least 6 characters';

  @override
  String get passwordMismatch => 'Passwords don\'t match';

  @override
  String get authWrongCredentials => 'Wrong email or password.';

  @override
  String get authEmailNotConfirmed =>
      'Please confirm your email first. Check your inbox.';

  @override
  String get authUserExists =>
      'This email already has an account. Log in instead.';

  @override
  String get authWeakPassword => 'Choose a stronger password.';

  @override
  String get authRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get authNetwork =>
      'Couldn\'t connect. Check your internet and try again.';

  @override
  String get authOther => 'Couldn\'t complete that. Please try again.';

  @override
  String get checkEmailTitle => 'Check your email';

  @override
  String checkEmailBody(String email) {
    return 'We sent a confirmation link to $email. Open it, then log in here.';
  }

  @override
  String get ok => 'OK';

  @override
  String get account => 'Account';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutTitle => 'Log out?';

  @override
  String get logOutBody => 'Your records stay on this device.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get authEmailRejected =>
      'This email address wasn\'t accepted. Please use an email you can receive mail at.';

  @override
  String get phone => 'Phone';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneInvalid => 'Enter a valid phone number';

  @override
  String get authWrongCredentialsPhone => 'Wrong phone number or password.';

  @override
  String get authUserExistsPhone =>
      'This phone number already has an account. Log in instead.';

  @override
  String askHelloName(String name) {
    return 'Hello, $name!';
  }

  @override
  String get saveFailed =>
      'Couldn\'t save. Check your internet connection and try again.';

  @override
  String get loadFailed =>
      'Couldn\'t load your records. Check your internet connection.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get patternsTitle => 'Patterns from your history';

  @override
  String get patternsSubtitle =>
      'Worked out from months of records, not only the period above.';

  @override
  String runwayScale(String days, String max) {
    return '$days of $max days';
  }

  @override
  String get chartOther => 'Other';

  @override
  String get expenseTotal => 'Total spent';

  @override
  String get usualTitle => 'This month vs your usual';

  @override
  String get usualSubtitle =>
      'Spending from the 1st to today, against the average of the same days in the last 3 months. Regular bills are left out.';

  @override
  String get usualThisMonth => 'This month';

  @override
  String get usualAverage => 'Usual';

  @override
  String usualAlert(String category, String percent) {
    return '$category is $percent% higher than usual';
  }

  @override
  String usualAlertBody(String amount, String usual) {
    return '$amount more than the usual $usual for this point in the month.';
  }

  @override
  String get usualNoAlert => 'No category is far above its usual level.';

  @override
  String get usualNoHistory => 'Shown once you have a month of records.';

  @override
  String get usualNew => 'New';

  @override
  String get recurringTitle => 'Regular payments';

  @override
  String get recurringSubtitle =>
      'Expenses you pay about once a month. They aren\'t counted as surprises above.';

  @override
  String recurringUpcoming(String amount) {
    return 'Due in the next 7 days: $amount';
  }

  @override
  String get recurringNoneSoon => 'Nothing due in the next 7 days.';

  @override
  String get recurringDueToday => 'Due today';

  @override
  String get recurringDueTomorrow => 'Due tomorrow';

  @override
  String recurringDueIn(String days) {
    return 'In $days days';
  }

  @override
  String get recurringLate => 'Not paid yet';

  @override
  String get recurringPaid => 'Paid';

  @override
  String recurringEvery(String amount, String day) {
    return 'About $amount around day $day';
  }

  @override
  String get recurringNone =>
      'Regular payments appear after about 3 months of records.';

  @override
  String get withdrawChartTitle => 'Profit vs money taken out';

  @override
  String get chartProfit => 'Profit';

  @override
  String get chartWithdrawn => 'Taken out';

  @override
  String withdrawThisMonth(String withdrawn, String profit) {
    return 'This month you took out $withdrawn but the business made $profit profit.';
  }

  @override
  String withdrawMonthsOver(String count) {
    return 'In $count of the last 6 months you took out more than the business made.';
  }

  @override
  String get withdrawNeverOver =>
      'In the last 6 months you never took out more than the business made.';

  @override
  String get weekdayTitle => 'Best and worst days';

  @override
  String get weekdaySubtitle => 'Average income on each day, last 12 weeks.';

  @override
  String weekdayRatio(String best, String ratio, String worst) {
    return '$best brings in $ratio× the income of $worst.';
  }

  @override
  String weekdayNoIncome(String best, String worst) {
    return '$best brings in the most; $worst usually has none.';
  }

  @override
  String get seasonTitle => 'Income through the year';

  @override
  String seasonPeaks(String peak, String low) {
    return 'Income peaks in $peak and is lowest in $low. Save during the busy months for the lean ones.';
  }

  @override
  String get seasonNeedYear =>
      'Busy and lean months are named after a full year of records.';

  @override
  String get sampleData => 'Sample data';

  @override
  String get loadSampleData => 'Load sample data';

  @override
  String get loadSampleHelp =>
      'Adds two years of example records for a shop with a rice field, so every dashboard chart has something to show.';

  @override
  String get loadSampleTitle => 'Add sample data?';

  @override
  String loadSampleBody(String count) {
    return 'This adds about $count example entries to this account. Entries can be voided but not deleted, so use a test account to keep your real records clean.';
  }

  @override
  String loadSampleDone(String count) {
    return 'Added $count sample entries.';
  }

  @override
  String get add => 'Add';

  @override
  String get incomeTotal => 'Total income';

  @override
  String get topSellersTitle => 'Top sellers';

  @override
  String get topSellersSubtitle =>
      'Income by item, from the description of each entry.';

  @override
  String topSellerShare(String item, String percent) {
    return '$item brings in $percent% of your income.';
  }

  @override
  String topSellerRising(String item, String change) {
    return '$item grew the most: $change vs the previous period.';
  }

  @override
  String salesCount(String count) {
    return 'sold $count times';
  }

  @override
  String otherItems(String count) {
    return '$count other items';
  }

  @override
  String get topSellersEmpty =>
      'When you record income, add a description such as \"Rice\" or \"Drinks\" to see what sells best.';

  @override
  String get navExport => 'Export';

  @override
  String get exportPageTitle => 'Export reports';

  @override
  String get exportPageIntro =>
      'Choose a report, pick the options and save it as a PDF.';

  @override
  String get reportAccountStatement => 'Account statement';

  @override
  String get reportAccountStatementDesc =>
      'Every entry with the running cash balance.';

  @override
  String get reportIncomeStatement => 'Income statement';

  @override
  String get reportIncomeStatementDesc =>
      'Income, expenses and profit by category.';

  @override
  String get reportCashFlow => 'Cash flow report';

  @override
  String get reportCashFlowDesc => 'Cash in and out, month by month.';

  @override
  String get reportLoanSummary => 'Loan-ready financial summary';

  @override
  String get reportLoanSummaryDesc =>
      'The key figures a bank or microfinance lender asks for.';

  @override
  String get reportLanguage => 'Report language';

  @override
  String get periodLast12Months => 'Last 12 months';

  @override
  String get businessName => 'Business name';

  @override
  String get ownerName => 'Owner name';

  @override
  String get savePdf => 'Save PDF';

  @override
  String get isIncome => 'Income';

  @override
  String get isExpenses => 'Expenses';

  @override
  String get isTotalExpenses => 'Total expenses';

  @override
  String get isNetProfit => 'Net profit (loss)';

  @override
  String get isMargin => 'Profit margin';

  @override
  String get colThisPeriod => 'This period';

  @override
  String get colPrevious => 'Previous period';

  @override
  String get colChange => 'Change';

  @override
  String isComparedWith(String from, String to) {
    return 'Previous period: $from – $to';
  }

  @override
  String isOwnerNote(String contributed, String withdrawn) {
    return 'Owner contributions ($contributed) and withdrawals ($withdrawn) move cash but are not business income or expenses, so they are not included above.';
  }

  @override
  String get reportBasisNote =>
      'Cash basis: income and expenses are counted on the day money is received or paid. Voided entries are left out. Prepared from the owner\'s own records; not audited.';

  @override
  String get cfOpening => 'Opening cash';

  @override
  String get cfCashIn => 'Cash in';

  @override
  String get cfCashOut => 'Cash out';

  @override
  String get cfOwnerIn => 'Owner contributions';

  @override
  String get cfOwnerOut => 'Owner withdrawals';

  @override
  String get cfTotalIn => 'Total cash in';

  @override
  String get cfTotalOut => 'Total cash out';

  @override
  String get cfNet => 'Net change in cash';

  @override
  String get cfClosing => 'Closing cash';

  @override
  String get cfByMonth => 'Month by month';

  @override
  String get colMonth => 'Month';

  @override
  String get colNet => 'Net';

  @override
  String get cfNoOpening =>
      'Opening and closing cash need an opening cash amount dated on or before the start of the period (Settings → Opening cash).';

  @override
  String get lsBusiness => 'Business';

  @override
  String get lsOwner => 'Owner';

  @override
  String get lsRecordsSince => 'Records kept since';

  @override
  String get lsKeyFigures => 'Key figures';

  @override
  String lsAveragesNote(String count) {
    return 'Monthly averages are over the $count finished months of the period.';
  }

  @override
  String get lsAvgIncome => 'Average monthly income';

  @override
  String get lsAvgExpenses => 'Average monthly expenses';

  @override
  String get lsAvgProfit => 'Average monthly profit';

  @override
  String get lsAvgWithdrawals => 'Average monthly owner withdrawals';

  @override
  String get lsAvgSurplus => 'Average monthly cash left after withdrawals';

  @override
  String get lsProfitableMonths => 'Profitable months';

  @override
  String lsOutOf(String count, String total) {
    return '$count of $total';
  }

  @override
  String get lsRunway => 'Cash runway';

  @override
  String lsDays(String days) {
    return '$days days';
  }

  @override
  String get lsMonthly => 'Monthly results';

  @override
  String get lsIncomeSources => 'Main income sources';

  @override
  String get lsShare => 'Share';

  @override
  String get lsCommitments =>
      'Regular monthly payments (including existing loans)';

  @override
  String get lsCommitmentsTotal => 'Total per month';

  @override
  String get lsNoCommitments =>
      'No regular monthly payments were found in the records.';

  @override
  String get lsDayOfMonth => 'Usual day';

  @override
  String get lsDisclaimer =>
      'Prepared by the business owner from their own records using SME Financial Copilot. Figures are on a cash basis and have not been audited.';
}
