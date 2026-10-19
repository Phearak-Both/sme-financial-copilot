import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sme_financial_copilot/core/money/currency.dart';
import 'package:sme_financial_copilot/data/cloud_store.dart';
import 'package:sme_financial_copilot/data/demo_data.dart';
import 'package:sme_financial_copilot/data/ledger_repository.dart';
import 'package:sme_financial_copilot/features/export/report_pdfs.dart';
import 'package:sme_financial_copilot/features/ledger/ledger_export.dart';
import 'package:sme_financial_copilot/finance_core/reports.dart';
import 'package:sme_financial_copilot/l10n/app_localizations.dart';

void main() {
  final today = DateTime(2026, 10, 16);
  // The app gets these from its localization delegates.
  setUpAll(initializeDateFormatting);

  for (final lang in ['en', 'km']) {
    testWidgets('every report renders a PDF in $lang', (tester) async {
      await tester.runAsync(() async {
        final repo = LedgerRepository(MemoryCloudStore(), clock: () => today);
        await loadDemoData(repo, today: today);
        final rows = await repo.watchEntries(const LedgerFilter()).first;
        final entries = rows.map(toLedgerEntry).toList();
        final openings = await repo.watchOpeningBalances().first;
        final categories = {
          for (final c in await repo.watchCategories().first) c.id: c,
        };
        final l10n = lookupAppLocalizations(Locale(lang));
        final ctx = ReportContext(
          l10n: l10n,
          locale: lang,
          categoryName: (id) => categories[id]?.nameEn ?? l10n.uncategorized,
          today: today,
          generatedAt: today,
        );
        final opening =
            openings.firstWhere((o) => o.currency == Currency.usd);
        final year = ReportRange.last12Months.rangeFor(today);

        final pdfs = [
          await renderGeneralLedgerPdf(
            buildGeneralLedger(
              entries: rows,
              openings: openings,
              categories: categories,
              currency: Currency.usd,
              range: ReportRange.thisMonth.rangeFor(today),
              today: today,
              l10n: l10n,
              isKhmer: lang == 'km',
            ),
            l10n: l10n,
            locale: lang,
            generatedAt: today,
            title: l10n.reportAccountStatement,
          ),
          await renderIncomeStatementPdf(
            buildIncomeStatement(entries, Currency.usd,
                ReportRange.lastMonth.rangeFor(today)),
            ctx,
          ),
          await renderCashFlowPdf(
            buildCashFlow(entries, Currency.khr,
                ReportRange.last3Months.rangeFor(today)),
            ctx,
          ),
          await renderLoanSummaryPdf(
            buildLoanSummary(entries, Currency.usd, year,
                today: today, opening: opening),
            ctx,
            businessName: 'Sokha Shop',
            ownerName: 'Sokha',
          ),
        ];
        for (final pdf in pdfs) {
          expect(ascii.decode(pdf.sublist(0, 5)), '%PDF-');
          expect(pdf.length, greaterThan(2000));
        }
      });
    });
  }
}
