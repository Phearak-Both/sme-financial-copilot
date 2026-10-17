import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sme_financial_copilot/core/date_only.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/data/database.dart';
import 'package:sme_financial_copilot/data/demo_data.dart';
import 'package:sme_financial_copilot/data/ledger_repository.dart';
import 'package:sme_financial_copilot/finance_core/ledger_math.dart';
import 'package:sme_financial_copilot/finance_core/period_math.dart';

void main() {
  test('sample data loads through validation and gives sane totals', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final today = DateTime(2026, 10, 16);
    final repo = LedgerRepository(db, clock: () => today);

    final count = await loadDemoData(repo, today: today);
    expect(count, greaterThan(150));

    final range = DateRange(addDays(today, -89), addDays(today, 1));
    final entries = await repo.watchLedgerEntries(range).first;
    expect(entries, hasLength(count));

    final summary = summarize(entries, range);
    expect(summary.byCurrency.keys, [Currency.usd, Currency.khr]);
    expect(summary.byCurrency[Currency.usd]!.profit.isNegative, isFalse);

    final balances = cashBalances(await repo.watchOpeningBalances().first, entries);
    expect(balances[Currency.usd]!.isNegative, isFalse);
    expect(balances[Currency.khr]!.isNegative, isFalse);
    await db.close();
  });
}
