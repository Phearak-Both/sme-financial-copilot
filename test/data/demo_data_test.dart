import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/data/cloud_store.dart';
import 'package:sme_financial_copilot/core/date_only.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/core/money/money.dart';
import 'package:sme_financial_copilot/domain/enums.dart';
import 'package:sme_financial_copilot/data/demo_data.dart';
import 'package:sme_financial_copilot/data/ledger_repository.dart';
import 'package:sme_financial_copilot/finance_core/ledger_math.dart';
import 'package:sme_financial_copilot/finance_core/patterns.dart';
import 'package:sme_financial_copilot/finance_core/period_math.dart';
import 'package:sme_financial_copilot/finance_core/sales.dart';

void main() {
  final today = DateTime(2026, 10, 16);

  test('sample data loads through validation and gives sane totals', () async {
    final db = MemoryCloudStore();
    final repo = LedgerRepository(db, clock: () => today);

    final count = await loadDemoData(repo, today: today);
    expect(count, greaterThan(1000));

    final range = DateRange(DateTime(2024, 11), addDays(today, 1));
    final entries = await repo.watchLedgerEntries(range).first;
    expect(entries, hasLength(count));

    final summary = summarize(entries, range);
    expect(summary.byCurrency.keys, [Currency.usd, Currency.khr]);
    expect(summary.byCurrency[Currency.usd]!.profit.isNegative, isFalse);

    final balances = cashBalances(await repo.watchOpeningBalances().first, entries);
    expect(balances[Currency.usd]!.isNegative, isFalse);
    expect(balances[Currency.khr]!.isNegative, isFalse);
  });

  test('sample data gives every dashboard pattern something to show', () {
    final drafts = demoDrafts(today);
    final entries = [
      for (final (i, d) in drafts.indexed)
        LedgerEntry(
          id: '$i',
          type: d.type,
          amountMinor: d.amountMinor,
          currency: d.currency,
          occurredOn: d.occurredOnKey,
          status: EntryStatus.active,
          categoryId: d.categoryId,
          description: d.description,
        ),
    ];
    const usd = Currency.usd;

    final recurring = detectRecurring(entries, usd, today);
    expect(recurring.map((r) => r.description), containsAll([
      'Shop rent',
      'Market stall fee',
      'Phone & internet top-up',
      'Microfinance loan payment',
      'Shop helper wages (1st half)',
      'Shop helper wages (2nd half)',
    ]));
    expect(recurring.where((r) => r.daysUntil(today) <= 7), isNotEmpty);

    final spending = compareWithUsual(entries, usd, today,
        recurringKeys: {for (final r in recurring) r.key});
    final total = Money(spending.fold(0, (s, r) => s + r.usual.minor), usd);
    final alerts = spending.where((r) => r.isAlert(total)).toList();
    expect(alerts.map((r) => r.categoryId), contains('transport'));

    final seasons = seasonality(entries, usd, today)!;
    expect(seasons.peakMonths, [11, 12]);
    expect(seasons.lowMonths, [4, 5]);

    final weekdays = weekdayIncome(entries, usd, today)!;
    expect(weekdays.best, DateTime.saturday);
    expect(weekdays.worst, DateTime.tuesday);

    final month = DateRange.monthOf(today);
    final sellers = topSellers(entries, usd, month, DateRange.previousMonthOf(today));
    expect(sellers.first.name, 'Rice (by the bag)');
    expect(sellers.map((s) => s.name), containsAll(['Drinks', 'Snacks', 'Cooking oil']));

    final withdrawals = profitVsWithdrawals(entries, usd, today);
    expect(withdrawals.last.overdrawn, isTrue);
    expect(withdrawals.where((m) => !m.overdrawn), isNotEmpty);
  });
}
