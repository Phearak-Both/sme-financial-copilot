import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/date_only.dart';
import '../core/money/money_parser.dart';
import '../data/database.dart';
import '../domain/enums.dart';
import '../finance_core/period_math.dart';
import '../l10n/app_localizations.dart';

/// Localised labels for domain values.
extension DomainLabels on AppLocalizations {
  String entryType(EntryType type) => switch (type) {
    EntryType.income => typeIncome,
    EntryType.expense => typeExpense,
    EntryType.ownerContribution => typeOwnerContribution,
    EntryType.ownerWithdrawal => typeOwnerWithdrawal,
  };

  String paymentMethodLabel(PaymentMethod method) => switch (method) {
    PaymentMethod.cash => pmCash,
    PaymentMethod.bank => pmBank,
    PaymentMethod.mobileWallet => pmMobileWallet,
    PaymentMethod.other => pmOther,
  };

  String sourceLabel(EntrySource source) => switch (source) {
    EntrySource.manual => sourceManual,
    EntrySource.text => sourceText,
    EntrySource.voice => sourceVoice,
    EntrySource.receipt => sourceReceipt,
  };

  String revisionLabel(RevisionKind kind) => switch (kind) {
    RevisionKind.create => revisionCreate,
    RevisionKind.edit => revisionEdit,
    RevisionKind.voided => revisionVoided,
  };

  String periodLabel(ReportPeriod period) => switch (period) {
    ReportPeriod.thisMonth => periodThisMonth,
    ReportPeriod.lastMonth => periodLastMonth,
    ReportPeriod.last3Months => periodLast3Months,
    ReportPeriod.thisYear => periodThisYear,
  };

  String amountError(AmountError error, String currencyCode) => switch (error) {
    AmountError.empty => errorAmountEmpty,
    AmountError.invalid => errorAmountInvalid,
    AmountError.tooManyDecimals => errorAmountDecimals(currencyCode),
    AmountError.notPositive => errorAmountPositive,
    AmountError.tooLarge => errorAmountTooLarge,
  };
}

extension ContextHelpers on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String get localeTag => Localizations.localeOf(this).toLanguageTag();

  bool get isKhmer => Localizations.localeOf(this).languageCode == 'km';

  String categoryName(CategoryRow? category) => category == null
      ? l10n.uncategorized
      : (isKhmer ? category.nameKm : category.nameEn);

  /// "Today", "Yesterday" or a medium date such as "Oct 14, 2026".
  String dayLabel(String dateKey) {
    final date = fromDateKey(dateKey);
    final today = dateOnly(DateTime.now());
    if (date == today) return l10n.today;
    if (date == addDays(today, -1)) return l10n.yesterday;
    return DateFormat.yMMMd(localeTag).format(date);
  }

  /// "Oct 1, 2026 – Oct 31, 2026" for a range (end shown inclusive).
  String rangeLabel(DateRange range) => l10n.filterActiveRange(
    dayLabel(range.startKey),
    dayLabel(toDateKey(addDays(range.end, -1))),
  );

  String dateTimeLabel(DateTime value) =>
      DateFormat.yMMMd(localeTag).add_Hm().format(value.toLocal());
}

/// Colours for money direction. Always paired with a sign or icon so meaning
/// never depends on colour alone.
class MoneyColors {
  static Color moneyIn(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF8FD1A8)
      : const Color(0xFF2E7D4F);

  static Color moneyOut(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFF0A48F)
      : const Color(0xFFA63D2A);
}

IconData entryTypeIcon(EntryType type) => switch (type) {
  EntryType.income => Icons.south_west,
  EntryType.expense => Icons.north_east,
  EntryType.ownerContribution => Icons.person_add_alt,
  EntryType.ownerWithdrawal => Icons.person_remove_alt_1,
};
