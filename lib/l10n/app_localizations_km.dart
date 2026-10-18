// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appTitle => 'SME Copilot';

  @override
  String get navLedger => 'បញ្ជីប្រាក់';

  @override
  String get navSettings => 'ការកំណត់';

  @override
  String get moneyIn => 'ប្រាក់ចូល';

  @override
  String get moneyOut => 'ប្រាក់ចេញ';

  @override
  String get profitCash => 'ប្រាក់ចំណេញ';

  @override
  String get netCashFlow => 'លំហូរសាច់ប្រាក់សុទ្ធ';

  @override
  String get summaryFootnote =>
      'សរុបត្រូវបានបង្ហាញតាមរូបិយប័ណ្ណនីមួយៗ។ ប្រាក់រៀល និងដុល្លារ មិនត្រូវបានបូកបញ្ចូលគ្នាទេ។';

  @override
  String get typeIncome => 'ចំណូល';

  @override
  String get typeExpense => 'ចំណាយ';

  @override
  String get typeOwnerContribution => 'ម្ចាស់ដាក់ប្រាក់ចូល';

  @override
  String get typeOwnerWithdrawal => 'ម្ចាស់ដកប្រាក់ចេញ';

  @override
  String get ownerHelp =>
      'ប្រាក់ផ្ទាល់ខ្លួនដែលដាក់ចូល ឬដកចេញពីអាជីវកម្ម។ វាប៉ះពាល់សាច់ប្រាក់ ប៉ុន្តែមិនរាប់ជាប្រាក់ចំណេញទេ។';

  @override
  String get newEntry => 'កំណត់ត្រាថ្មី';

  @override
  String get editEntry => 'កែកំណត់ត្រា';

  @override
  String get entryDetails => 'ព័ត៌មានលម្អិត';

  @override
  String get amount => 'ចំនួនទឹកប្រាក់';

  @override
  String get currency => 'រូបិយប័ណ្ណ';

  @override
  String get category => 'ប្រភេទ';

  @override
  String get date => 'កាលបរិច្ឆេទ';

  @override
  String get description => 'ការពិពណ៌នា';

  @override
  String get descriptionHint => 'ឧ. ទិញជី';

  @override
  String get note => 'កំណត់សម្គាល់';

  @override
  String get paymentMethod => 'បង់តាម';

  @override
  String get pmCash => 'សាច់ប្រាក់';

  @override
  String get pmBank => 'ធនាគារ';

  @override
  String get pmMobileWallet => 'កាបូបអេឡិចត្រូនិក';

  @override
  String get pmOther => 'ផ្សេងៗ';

  @override
  String get notSet => 'មិនបានកំណត់';

  @override
  String get uncategorized => 'គ្មានប្រភេទ';

  @override
  String get save => 'រក្សាទុក';

  @override
  String get cancel => 'បោះបង់';

  @override
  String get edit => 'កែ';

  @override
  String get voidAction => 'ទុកជាមោឃៈ';

  @override
  String get voidTitle => 'ទុកកំណត់ត្រានេះជាមោឃៈ?';

  @override
  String get voidBody =>
      'វានៅតែមានក្នុងប្រវត្តិ ប៉ុន្តែលែងរាប់បញ្ចូលក្នុងសរុបទៀតហើយ។';

  @override
  String get voidReason => 'មូលហេតុ';

  @override
  String get voided => 'មោឃៈ';

  @override
  String get errorAmountEmpty => 'សូមបញ្ចូលចំនួនទឹកប្រាក់';

  @override
  String get errorAmountInvalid => 'សូមបញ្ចូលលេខឱ្យបានត្រឹមត្រូវ';

  @override
  String errorAmountDecimals(String currency) {
    return 'ខ្ទង់ទសភាគច្រើនពេកសម្រាប់ $currency';
  }

  @override
  String get errorAmountPositive => 'ចំនួនទឹកប្រាក់ត្រូវតែធំជាងសូន្យ';

  @override
  String get errorAmountTooLarge => 'ចំនួនទឹកប្រាក់ធំពេក';

  @override
  String get errorFutureDate => 'កាលបរិច្ឆេទមិនអាចនៅថ្ងៃអនាគតបានទេ';

  @override
  String get errorCategory => 'សូមជ្រើសរើសប្រភេទ';

  @override
  String get duplicateTitle => 'អាចស្ទួនគ្នា';

  @override
  String duplicateBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'មានកំណត់ត្រា $count ដែលមានចំនួនទឹកប្រាក់ រូបិយប័ណ្ណ និងកាលបរិច្ឆេទដូចគ្នារួចហើយ។',
    );
    return '$_temp0 នៅតែរក្សាទុក?';
  }

  @override
  String get saveAnyway => 'នៅតែរក្សាទុក';

  @override
  String get savedMessage => 'បានរក្សាទុក';

  @override
  String get updatedMessage => 'បានកែប្រែ';

  @override
  String get voidedMessage => 'បានទុកជាមោឃៈ';

  @override
  String get searchHint => 'ស្វែងរក';

  @override
  String get filterAll => 'ទាំងអស់';

  @override
  String get ledgerEmptyFiltered => 'គ្មានកំណត់ត្រាត្រូវនឹងតម្រងនេះទេ។';

  @override
  String get ledgerEmpty => 'មិនទាន់មានកំណត់ត្រា។ ចុច + ដើម្បីកត់ត្រា។';

  @override
  String get clearFilters => 'សម្អាតតម្រង';

  @override
  String get history => 'ប្រវត្តិ';

  @override
  String get revisionCreate => 'បានបង្កើត';

  @override
  String get revisionEdit => 'បានកែប្រែ';

  @override
  String get revisionVoided => 'បានទុកជាមោឃៈ';

  @override
  String versionLabel(int version) {
    return 'កំណែទី $version';
  }

  @override
  String get source => 'ប្រភព';

  @override
  String get sourceManual => 'បញ្ចូលដោយដៃ';

  @override
  String get sourceText => 'វាយទៅជំនួយការ';

  @override
  String get sourceVoice => 'សំឡេង';

  @override
  String get sourceReceipt => 'រូបថតវិក្កយបត្រ';

  @override
  String get language => 'ភាសា';

  @override
  String get today => 'ថ្ងៃនេះ';

  @override
  String get yesterday => 'ម្សិលមិញ';

  @override
  String get somethingWrong => 'មានបញ្ហាកើតឡើង។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get entryNotFound => 'កំណត់ត្រានេះលែងមានទៀតហើយ។';

  @override
  String get navDashboard => 'សង្ខេប';

  @override
  String get periodThisMonth => 'ខែនេះ';

  @override
  String get periodLastMonth => 'ខែមុន';

  @override
  String get periodLast3Months => '៣ ខែចុងក្រោយ';

  @override
  String get periodThisYear => 'ឆ្នាំនេះ';

  @override
  String get cashOnHand => 'សាច់ប្រាក់នៅសល់';

  @override
  String get cashOnHandHint =>
      'កំណត់សាច់ប្រាក់ដើមគ្រា ដើម្បីមើលថាអាជីវកម្មមានប្រាក់ប៉ុន្មាននៅពេលនេះ។';

  @override
  String get openingCash => 'សាច់ប្រាក់ដើមគ្រា';

  @override
  String get openingCashHelp =>
      'ចំនួនសាច់ប្រាក់ដែលអាជីវកម្មមាននៅដើមថ្ងៃណាមួយ។ សាច់ប្រាក់នៅសល់ = សាច់ប្រាក់ដើមគ្រា + ប្រាក់ចូល − ប្រាក់ចេញ ចាប់ពីថ្ងៃនោះ។';

  @override
  String get asOf => 'គិតត្រឹម';

  @override
  String asOfValue(String amount, String date) {
    return '$amount គិតត្រឹម $date';
  }

  @override
  String get clear => 'សម្អាត';

  @override
  String get negativeBalanceWarning =>
      'សាច់ប្រាក់ដែលបានកត់ត្រាតិចជាងសូន្យ។ ប្រហែលជាខ្វះកំណត់ត្រាប្រាក់ចូល ឬសាច់ប្រាក់ដើមគ្រាមិនត្រឹមត្រូវ។';

  @override
  String vsComparison(String change) {
    return '$change ធៀបនឹងចំនួនថ្ងៃដូចគ្នាមុននេះ';
  }

  @override
  String vsComparisonFull(String change) {
    return '$change ធៀបនឹងរយៈពេលមុន';
  }

  @override
  String get noComparison => 'គ្មានកំណត់ត្រាមុននេះសម្រាប់ប្រៀបធៀប';

  @override
  String get trendTitle => 'ប្រាក់ចូល និងប្រាក់ចេញ';

  @override
  String get expenseBreakdown => 'ប្រាក់ចេញទៅណាខ្លះ';

  @override
  String get noExpenses => 'គ្មានការចំណាយក្នុងរយៈពេលនេះទេ។';

  @override
  String dashboardEmpty(String currency) {
    return 'គ្មានកំណត់ត្រា $currency ក្នុងរយៈពេលនេះទេ។';
  }

  @override
  String otherCurrencyHint(String currency) {
    return 'មានកំណត់ត្រា $currency ក្នុងរយៈពេលនេះ។';
  }

  @override
  String showCurrency(String currency) {
    return 'បង្ហាញ $currency';
  }

  @override
  String get dashboardFootnote =>
      'គិតតាមសាច់ប្រាក់៖ ប្រាក់ត្រូវបានរាប់នៅថ្ងៃដែលទទួល ឬបង់។ ប្រាក់ដែលម្ចាស់ដាក់ចូល ឬដកចេញ មិនរាប់ជាប្រាក់ចំណេញទេ។';

  @override
  String get trendSemantics =>
      'ក្រាហ្វប្រាក់ចូល និងប្រាក់ចេញ សម្រាប់រយៈពេលដែលបានជ្រើស។';

  @override
  String percentOfTotal(int percent) {
    return '$percent% នៃប្រាក់ចេញ';
  }

  @override
  String filterActiveRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get navAsk => 'ជំនួយការ';

  @override
  String get askTitle => 'ជំនួយការ';

  @override
  String get askWelcomeTitle => 'សួស្តី!\nតើខ្ញុំអាចជួយអ្វីបាន?';

  @override
  String get askHint => 'កត់ត្រា ឬសួរ…';

  @override
  String get askSend => 'ផ្ញើ';

  @override
  String get askMicTooltip => 'ថតសារជាសំឡេង';

  @override
  String get askPhotoTooltip => 'រូបថតវិក្កយបត្រ';

  @override
  String get askTakePhoto => 'ថតរូប';

  @override
  String get askChoosePhoto => 'ជ្រើសពីរូបថត';

  @override
  String get askMicDenied =>
      'មីក្រូហ្វូនត្រូវបានបិទ។ សូមអនុញ្ញាតក្នុងការកំណត់ប្រព័ន្ធ ដើម្បីប្រើសំឡេង។';

  @override
  String get askThinking => 'កំពុងគិត…';

  @override
  String get askAmountMissing => 'រកមិនឃើញចំនួនទឹកប្រាក់';

  @override
  String get askCurrencyUnknown =>
      'មិនបានបញ្ជាក់រូបិយប័ណ្ណ។ អ្នកនឹងជ្រើសនៅអេក្រង់បន្ទាប់។';

  @override
  String get askNoRecords => 'មិនទាន់មានកំណត់ត្រាក្នុងរយៈពេលនេះទេ។';

  @override
  String get askCashUnknown =>
      'មិនដឹងសាច់ប្រាក់ក្នុងដៃទេ។ សូមកំណត់សាច់ប្រាក់ដំបូងក្នុងការកំណត់ជាមុនសិន។';

  @override
  String askCalculatedFrom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'គណនាពីកំណត់ត្រា $count',
      zero: 'មិនបានប្រើកំណត់ត្រា',
    );
    return '$_temp0';
  }

  @override
  String get askNewChat => 'ការសន្ទនាថ្មី';

  @override
  String get askError =>
      'សូមទោស មានបញ្ហា។ សូមពិនិត្យអ៊ីនធឺណិត ហើយព្យាយាមម្តងទៀត។';

  @override
  String get askQuota =>
      'បានដល់កម្រិត AI ឥតគិតថ្លៃហើយ។ សូមរង់ចាំមួយនាទី រួចព្យាយាមម្តងទៀត។';

  @override
  String get askNotConfigured =>
      'AI មិនទាន់បានរៀបចំទេ។ សូមដំណើរការកម្មវិធីជាមួយ --dart-define-from-file=env/dev.json។';

  @override
  String get aiConsentTitle => 'មុនពេលប្រើជំនួយការ';

  @override
  String get aiConsentBody =>
      'ដើម្បីយល់ពីអ្នក អត្ថបទ ការថតសំឡេង ឬរូបថតដែលអ្នកផ្ញើ នឹងត្រូវដំណើរការដោយ Google Gemini។ មានតែចំនួនសរុបដែលត្រូវការសម្រាប់ឆ្លើយសំណួរប៉ុណ្ណោះដែលត្រូវបានផ្ញើ មិនមែនបញ្ជីទាំងមូលទេ។ ក្នុងកម្រិតឥតគិតថ្លៃ Google អាចប្រើទិន្នន័យនេះដើម្បីកែលម្អផលិតផលរបស់ខ្លួន ដូច្នេះសូមប្រើទិន្នន័យសាកល្បងសិន។';

  @override
  String get aiConsentAgree => 'ខ្ញុំយល់ហើយ';

  @override
  String get proposalReviewHint =>
      'បំពេញដោយជំនួយការ។ សូមពិនិត្យគ្រប់ចន្លោះ រួចរក្សាទុក។';

  @override
  String get confirmCurrency => 'សូមជ្រើសរូបិយប័ណ្ណ។';

  @override
  String get askRecordingFailed =>
      'មិនអាចរក្សាទុកការថតបានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get askTranscribing => 'កំពុងបម្លែងសំឡេងទៅជាអក្សរ…';

  @override
  String get askTranscribeFailed =>
      'មិនអាចបម្លែងការថតទៅជាអក្សរបានទេ។ សូមព្យាយាមម្តងទៀត ឬវាយអក្សរ។';

  @override
  String get askNothingHeard => 'ខ្ញុំមិនឮអ្វីទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get askListening => 'កំពុងស្តាប់… សូមនិយាយ';

  @override
  String get askDoneTalking => 'និយាយរួចហើយ';

  @override
  String askRead(String text) {
    return 'បានអាន៖ «$text»';
  }

  @override
  String get exportPdf => 'ទាញយក PDF';

  @override
  String get exportFailed => 'មិនអាចបង្កើត PDF បានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get glTitle => 'សៀវភៅគណនី';

  @override
  String glAccount(String currency) {
    return 'គណនីសាច់ប្រាក់ ($currency)';
  }

  @override
  String get glNo => 'ល.រ';

  @override
  String get glDebit => 'ឥណពន្ធ (ចូល)';

  @override
  String get glCredit => 'ឥណទាន (ចេញ)';

  @override
  String get glBalance => 'សមតុល្យ';

  @override
  String get glOpening => 'សមតុល្យដើមគ្រា';

  @override
  String get glTotals => 'សរុប';

  @override
  String get glClosing => 'សមតុល្យចុងគ្រា';

  @override
  String glPeriod(String from, String to) {
    return 'រយៈពេល៖ $from – $to';
  }

  @override
  String glGenerated(String date) {
    return 'បង្កើតនៅ៖ $date';
  }

  @override
  String get glVoidedNote =>
      'មិនរាប់បញ្ចូលកំណត់ត្រាមោឃៈ។ ប្រាក់រៀល និងដុល្លារ ត្រូវបានកត់ក្នុងគណនីដាច់ដោយឡែក។';

  @override
  String get glNoEntries => 'មិនទាន់មានកំណត់ត្រានៅឡើយ។';

  @override
  String get exportTitle => 'ទាញយកសៀវភៅគណនី';

  @override
  String get exportCurrency => 'រូបិយប័ណ្ណ';

  @override
  String get exportPeriod => 'រយៈពេល';

  @override
  String get periodLast6Months => '៦ ខែចុងក្រោយ';

  @override
  String get periodLastYear => '១ ឆ្នាំចុងក្រោយ';

  @override
  String get exportSaved => 'បានរក្សាទុក PDF';

  @override
  String get insightsTitle => 'ការវិភាគ';

  @override
  String insightMarginTitle(String percent) {
    return 'អត្រាប្រាក់ចំណេញ $percent%';
  }

  @override
  String insightMarginBody(String percent) {
    return 'ក្នុងប្រាក់ចូលរាល់ 100 អ្នករក្សាទុកបាន $percent ជាប្រាក់ចំណេញ។';
  }

  @override
  String get insightLossTitle => 'ចំណាយលើសប្រាក់ចូល';

  @override
  String insightLossBody(String amount) {
    return 'ក្នុងរយៈពេលនេះ ប្រាក់ចេញច្រើនជាងប្រាក់ចូល $amount។';
  }

  @override
  String get insightWithdrawTitle => 'ដកប្រាក់លើសប្រាក់ចំណេញ';

  @override
  String insightWithdrawBody(String withdrawn, String profit) {
    return 'អ្នកបានដកប្រាក់ $withdrawn ខណៈប្រាក់ចំណេញមាន $profit ដែលធ្វើឱ្យសាច់ប្រាក់អាជីវកម្មថយចុះ។';
  }

  @override
  String insightRunwayTitle(String days) {
    return 'សាច់ប្រាក់គ្រប់គ្រាន់ប្រហែល $days ថ្ងៃ';
  }

  @override
  String get insightRunwayBody => 'តាមការចំណាយជាមធ្យមក្នុង 30 ថ្ងៃចុងក្រោយ។';

  @override
  String get insightRunwayLowBody =>
      'តាមការចំណាយជាមធ្យមក្នុង 30 ថ្ងៃចុងក្រោយ។ គួររក្សាសាច់ប្រាក់បម្រុងឱ្យបានច្រើនជាងនេះ។';

  @override
  String insightForecastTitle(String amount) {
    return 'ប្រាក់ចំណេញប៉ាន់ស្មាន៖ $amount';
  }

  @override
  String get insightForecastBody =>
      'ប្រសិនបើល្បឿនបច្ចុប្បន្នបន្តរហូតដល់ចុងរយៈពេល។';

  @override
  String insightCategoryTitle(String category, String percent) {
    return 'ចំណាយលើ$category កើនឡើង $percent%';
  }

  @override
  String insightCategoryBody(String amount) {
    return 'ច្រើនជាងរយៈពេលមុន $amount។';
  }

  @override
  String insightTopIncomeTitle(String category, String percent) {
    return '$category៖ $percent% នៃប្រាក់ចូល';
  }

  @override
  String get insightTopIncomeBody => 'ជាប្រភពប្រាក់ចូលធំបំផុតក្នុងរយៈពេលនេះ។';

  @override
  String get insightTopIncomeRiskBody =>
      'ប្រាក់ចូលភាគច្រើនពឹងលើប្រភពតែមួយ។ ការបន្ថែមប្រភពផ្សេងទៀតជួយកាត់បន្ថយហានិភ័យ។';

  @override
  String get insightNoIncomeTitle => 'មិនទាន់មានប្រាក់ចូល';

  @override
  String get insightNoIncomeMarginBody =>
      'អត្រាប្រាក់ចំណេញនឹងបង្ហាញ នៅពេលអ្នកកត់ត្រាប្រាក់ចូល។';

  @override
  String get insightNoIncomeSourceBody =>
      'ប្រភពប្រាក់ចូលសំខាន់នឹងបង្ហាញ នៅពេលអ្នកកត់ត្រាប្រាក់ចូល។';

  @override
  String get insightWithdrawOkTitle => 'ការដកប្រាក់មិនលើសប្រាក់ចំណេញ';

  @override
  String insightWithdrawOkBody(String withdrawn, String profit) {
    return 'អ្នកបានដកប្រាក់ $withdrawn ក្នុងប្រាក់ចំណេញ $profit។';
  }

  @override
  String get insightNoWithdrawTitle => 'មិនមានការដកប្រាក់ដោយម្ចាស់';

  @override
  String get insightNoWithdrawBody =>
      'មិនមានប្រាក់ត្រូវបានដកចេញពីអាជីវកម្មក្នុងរយៈពេលនេះទេ។';

  @override
  String get insightRunwaySetupTitle => 'សាច់ប្រាក់អាចប្រើបានរយៈពេលប៉ុន្មាន?';

  @override
  String get insightRunwaySetupBody =>
      'កំណត់សាច់ប្រាក់ដើមគ្រា ក្នុងការកំណត់ ដើម្បីមើល។';

  @override
  String get insightRunwayNoSpendTitle => 'គ្មានការចំណាយក្នុង 30 ថ្ងៃចុងក្រោយ';

  @override
  String get insightRunwayNoSpendBody =>
      'រយៈពេលសាច់ប្រាក់ត្រូវបានប៉ាន់ស្មានពីការចំណាយថ្មីៗ។';

  @override
  String get insightRunwayLongTitle => 'សាច់ប្រាក់គ្រប់គ្រាន់លើសពីមួយឆ្នាំ';

  @override
  String get insightForecastWaitTitle => 'ប្រាក់ចំណេញប៉ាន់ស្មាន';

  @override
  String get insightForecastEarlyBody => 'អាចមើលបានក្រោយ 7 ថ្ងៃដំបូងនៃរយៈពេល។';

  @override
  String get insightForecastDoneBody =>
      'រយៈពេលនេះបានបញ្ចប់ហើយ។ ប្រាក់ចំណេញចុងក្រោយបង្ហាញនៅខាងលើ។';

  @override
  String get insightNoIncreaseTitle => 'គ្មានការចំណាយកើនឡើងខ្លាំង';

  @override
  String get insightNoIncreaseBody =>
      'គ្មានប្រភេទចំណាយណាកើនឡើង 20% ឬច្រើនជាងនេះ បើធៀបនឹងរយៈពេលមុន។';

  @override
  String get chatHistory => 'ប្រវត្តិ';

  @override
  String get noChats => 'មិនទាន់មានការសន្ទនា';

  @override
  String get photoChat => 'រូបថតបង្កាន់ដៃ';

  @override
  String get delete => 'លុប';

  @override
  String get deleteChatTitle => 'លុបការសន្ទនានេះ?';

  @override
  String get deleteChatBody =>
      'ការសន្ទនានេះនឹងត្រូវលុបជាអចិន្ត្រៃយ៍។ កំណត់ត្រាដែលបានរក្សាទុករួច នៅតែមានក្នុងបញ្ជីប្រាក់។';

  @override
  String get last7Days => '7 ថ្ងៃចុងក្រោយ';

  @override
  String get last30Days => '30 ថ្ងៃចុងក្រោយ';

  @override
  String get pickDates => 'ជ្រើសកាលបរិច្ឆេទ';

  @override
  String get noChatsInRange => 'គ្មានការសន្ទនាក្នុងរយៈពេលនេះ';

  @override
  String get authLogInSubtitle =>
      'ចូលគណនី ដើម្បីរក្សាកំណត់ត្រារបស់អ្នកឱ្យមានសុវត្ថិភាព។';

  @override
  String get authSignUpSubtitle => 'បង្កើតគណនីសម្រាប់អាជីវកម្មរបស់អ្នក។';

  @override
  String get logIn => 'ចូលគណនី';

  @override
  String get signUp => 'បង្កើតគណនី';

  @override
  String get fullName => 'ឈ្មោះ';

  @override
  String get email => 'អ៊ីមែល';

  @override
  String get password => 'ពាក្យសម្ងាត់';

  @override
  String get confirmPassword => 'បញ្ជាក់ពាក្យសម្ងាត់';

  @override
  String get noAccount => 'មិនទាន់មានគណនី?';

  @override
  String get haveAccount => 'មានគណនីរួចហើយ?';

  @override
  String get nameRequired => 'សូមបញ្ចូលឈ្មោះ';

  @override
  String get emailInvalid => 'សូមបញ្ចូលអ៊ីមែលឱ្យបានត្រឹមត្រូវ';

  @override
  String get passwordTooShort => 'ប្រើយ៉ាងតិច 6 តួអក្សរ';

  @override
  String get passwordMismatch => 'ពាក្យសម្ងាត់មិនដូចគ្នា';

  @override
  String get authWrongCredentials => 'អ៊ីមែល ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ។';

  @override
  String get authEmailNotConfirmed =>
      'សូមបញ្ជាក់អ៊ីមែលរបស់អ្នកជាមុនសិន។ សូមពិនិត្យប្រអប់សំបុត្រ។';

  @override
  String get authUserExists => 'អ៊ីមែលនេះមានគណនីរួចហើយ។ សូមចូលគណនីវិញ។';

  @override
  String get authWeakPassword => 'សូមជ្រើសពាក្យសម្ងាត់ដែលរឹងមាំជាងនេះ។';

  @override
  String get authRateLimited =>
      'ព្យាយាមច្រើនដងពេក។ សូមរង់ចាំបន្តិច ហើយព្យាយាមម្តងទៀត។';

  @override
  String get authNetwork =>
      'មិនអាចភ្ជាប់បាន។ សូមពិនិត្យអ៊ីនធឺណិត ហើយព្យាយាមម្តងទៀត។';

  @override
  String get authOther => 'មិនអាចបញ្ចប់បានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get checkEmailTitle => 'សូមពិនិត្យអ៊ីមែល';

  @override
  String checkEmailBody(String email) {
    return 'យើងបានផ្ញើតំណបញ្ជាក់ទៅ $email។ សូមបើកតំណនោះ រួចចូលគណនីនៅទីនេះ។';
  }

  @override
  String get ok => 'យល់ព្រម';

  @override
  String get account => 'គណនី';

  @override
  String get logOut => 'ចាកចេញ';

  @override
  String get logOutTitle => 'ចាកចេញពីគណនី?';

  @override
  String get logOutBody => 'កំណត់ត្រារបស់អ្នកនៅតែមាននៅលើឧបករណ៍នេះ។';

  @override
  String get showPassword => 'បង្ហាញពាក្យសម្ងាត់';

  @override
  String get hidePassword => 'លាក់ពាក្យសម្ងាត់';

  @override
  String get authEmailRejected =>
      'អ៊ីមែលនេះមិនត្រូវបានទទួលយកទេ។ សូមប្រើអ៊ីមែលពិតដែលអ្នកអាចទទួលសំបុត្របាន។';

  @override
  String get phone => 'ទូរស័ព្ទ';

  @override
  String get phoneNumber => 'លេខទូរស័ព្ទ';

  @override
  String get phoneInvalid => 'សូមបញ្ចូលលេខទូរស័ព្ទឱ្យបានត្រឹមត្រូវ';

  @override
  String get authWrongCredentialsPhone =>
      'លេខទូរស័ព្ទ ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ។';

  @override
  String get authUserExistsPhone =>
      'លេខទូរស័ព្ទនេះមានគណនីរួចហើយ។ សូមចូលគណនីវិញ។';

  @override
  String askHelloName(String name) {
    return 'សួស្តី $name!';
  }
}
