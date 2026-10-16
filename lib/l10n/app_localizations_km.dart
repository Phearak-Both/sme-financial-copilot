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
  String get navHome => 'ទំព័រដើម';

  @override
  String get navLedger => 'បញ្ជីប្រាក់';

  @override
  String get navSettings => 'ការកំណត់';

  @override
  String get thisMonth => 'ខែនេះ';

  @override
  String get moneyIn => 'ប្រាក់ចូល';

  @override
  String get moneyOut => 'ប្រាក់ចេញ';

  @override
  String get profitCash => 'ប្រាក់ចំណេញ (សាច់ប្រាក់)';

  @override
  String get netCashFlow => 'លំហូរសាច់ប្រាក់សុទ្ធ';

  @override
  String get ownerMovements => 'ម្ចាស់ដាក់ចូល / ដកចេញ';

  @override
  String get summaryFootnote =>
      'សរុបត្រូវបានបង្ហាញតាមរូបិយប័ណ្ណនីមួយៗ។ ប្រាក់រៀល និងដុល្លារ មិនត្រូវបានបូកបញ្ចូលគ្នាទេ។';

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count កំណត់ត្រា',
    );
    return '$_temp0';
  }

  @override
  String get homeEmptyTitle => 'មិនទាន់មានកំណត់ត្រានៅឡើយ';

  @override
  String get homeEmptyBody =>
      'កត់ត្រាការលក់ ឬការចំណាយដំបូងរបស់អ្នក ដើម្បីមើលប្រាក់ចូល ប្រាក់ចេញ និងប្រាក់ចំណេញក្នុងខែនេះ។';

  @override
  String get recent => 'ថ្មីៗ';

  @override
  String get viewAll => 'មើលទាំងអស់';

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
  String get voidReason => 'មូលហេតុ (ស្រេចចិត្ត)';

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
  String get searchHint => 'ស្វែងរកការពិពណ៌នា ឬកំណត់សម្គាល់';

  @override
  String get filterAll => 'ទាំងអស់';

  @override
  String get showVoided => 'បង្ហាញមោឃៈ';

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
}
