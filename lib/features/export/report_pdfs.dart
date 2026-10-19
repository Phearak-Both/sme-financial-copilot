import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/date_only.dart';
import '../../core/money/money.dart';
import '../../finance_core/insights.dart';
import '../../finance_core/period_math.dart';
import '../../finance_core/reports.dart';
import '../../l10n/app_localizations.dart';
import 'pdf_kit.dart';

/// What every report needs to put text on the page in the chosen language.
class ReportContext {
  const ReportContext({
    required this.l10n,
    required this.locale,
    required this.categoryName,
    required this.today,
    required this.generatedAt,
  });

  final AppLocalizations l10n;

  /// Language tag for month names and dates, e.g. `km` or `en`.
  final String locale;
  final String Function(String? categoryId) categoryName;
  final DateTime today;
  final DateTime generatedAt;

  String month(DateRange range) {
    final name = DateFormat.yMMM(locale).format(range.start);
    // A month cut short by the period says which days it covers.
    if (DateRange.monthOf(range.start) == range) return name;
    return '$name (${range.start.day}–${addDays(range.end, -1).day})';
  }
}

String _change(Money current, Money previous) {
  final p = percentChange(current, previous);
  return p == null ? '-' : '${p > 0 ? '+' : ''}$p%';
}

PdfColor? _sign(Money m) =>
    m.isNegative ? pdfRed : (m.minor > 0 ? pdfGreen : null);

// -------------------------------------------------------- income statement

Future<Uint8List> renderIncomeStatementPdf(
  IncomeStatement s,
  ReportContext ctx,
) async {
  final l10n = ctx.l10n;
  final kit = PdfText();
  final last = addDays(s.comparison.end, -1);
  final columns = [
    l10n.category,
    l10n.colThisPeriod,
    l10n.colPrevious,
    l10n.colChange,
  ];

  List<String> row(String label, Money now, Money before) =>
      [label, pdfMoney(now), pdfMoney(before), _change(now, before)];

  final profit = s.current.profit;
  final previousProfit = s.previous.profit;
  final rows = <List<String>>[
    [l10n.isIncome, '', '', ''],
    for (final line in s.income)
      row('   ${ctx.categoryName(line.categoryId)}', line.current, line.previous),
    row(l10n.incomeTotal, s.current.income, s.previous.income),
    [l10n.isExpenses, '', '', ''],
    for (final line in s.expenses)
      row('   ${ctx.categoryName(line.categoryId)}', line.current, line.previous),
    row(l10n.isTotalExpenses, s.current.expense, s.previous.expense),
    row(l10n.isNetProfit, profit, previousProfit),
  ];
  final incomeHeader = 0;
  final incomeTotal = s.income.length + 1;
  final expenseHeader = incomeTotal + 1;
  final expenseTotal = expenseHeader + s.expenses.length + 1;
  final profitRow = expenseTotal + 1;

  final body = <pw.Widget>[
    ...await kit.header(
      title: l10n.reportIncomeStatement,
      lines: [
        ...reportLines(l10n, s.range, ctx.today, s.currency, ctx.generatedAt, ctx.locale),
        l10n.isComparedWith(pdfDate(s.comparison.start), pdfDate(last)),
      ],
    ),
    await kit.table(
      columns: columns,
      rows: rows,
      shaded: {incomeHeader, incomeTotal, expenseHeader, expenseTotal, profitRow},
      colors: {
        if (_sign(profit) != null) (profitRow, 1): _sign(profit)!,
        if (_sign(previousProfit) != null) (profitRow, 2): _sign(previousProfit)!,
      },
    ),
    pw.SizedBox(height: 10),
    await kit.figures([
      (
        l10n.isMargin,
        s.marginPercent == null ? '-' : '${s.marginPercent}%',
      ),
      (l10n.isNetProfit, '${pdfMoney(profit)} ${s.currency.code}'),
    ]),
    pw.SizedBox(height: 6),
    await kit.text(
      l10n.isOwnerNote(
        pdfMoney(s.current.ownerContribution),
        pdfMoney(s.current.ownerWithdrawal),
      ),
      color: pdfMuted,
      size: 8,
      maxWidth: 520,
    ),
    await kit.text(l10n.reportBasisNote, color: pdfMuted, size: 8, maxWidth: 520),
  ];
  return kit.document(l10n.reportIncomeStatement, body);
}

// ------------------------------------------------------------- cash flow

Future<Uint8List> renderCashFlowPdf(
  CashFlowReport r,
  ReportContext ctx,
) async {
  final l10n = ctx.l10n;
  final kit = PdfText();
  String known(Money? m) => m == null ? '-' : pdfMoney(m);

  final summaryRows = <List<String>>[
    [l10n.cfOpening, known(r.opening)],
    [l10n.cfCashIn, ''],
    for (final MapEntry(:key, :value) in r.incomeByCategory)
      ['   ${ctx.categoryName(key)}', pdfMoney(value)],
    if (!r.totals.ownerContribution.isZero)
      ['   ${l10n.cfOwnerIn}', pdfMoney(r.totals.ownerContribution)],
    [l10n.cfTotalIn, pdfMoney(r.cashIn)],
    [l10n.cfCashOut, ''],
    for (final MapEntry(:key, :value) in r.expensesByCategory)
      ['   ${ctx.categoryName(key)}', pdfMoney(value)],
    if (!r.totals.ownerWithdrawal.isZero)
      ['   ${l10n.cfOwnerOut}', pdfMoney(r.totals.ownerWithdrawal)],
    [l10n.cfTotalOut, pdfMoney(r.cashOut)],
    [l10n.cfNet, pdfMoney(r.cashIn - r.cashOut)],
    [l10n.cfClosing, known(r.closing)],
  ];
  final shaded = <int>{
    for (final (i, row) in summaryRows.indexed)
      if (i == 0 ||
          row[1].isEmpty ||
          row[0] == l10n.cfTotalIn ||
          row[0] == l10n.cfTotalOut ||
          row[0] == l10n.cfNet ||
          row[0] == l10n.cfClosing)
        i,
  };
  final net = r.cashIn - r.cashOut;

  final body = <pw.Widget>[
    ...await kit.header(
      title: l10n.reportCashFlow,
      lines: reportLines(l10n, r.range, ctx.today, r.currency, ctx.generatedAt, ctx.locale),
    ),
    await kit.table(
      columns: [l10n.category, l10n.amount],
      rows: summaryRows,
      shaded: shaded,
      amountWidth: 110,
      colors: {
        if (_sign(net) != null) (summaryRows.length - 2, 1): _sign(net)!,
      },
    ),
    if (r.opening == null) ...[
      pw.SizedBox(height: 6),
      await kit.text(l10n.cfNoOpening, color: pdfMuted, size: 8, maxWidth: 520),
    ],
    await kit.heading(l10n.cfByMonth),
    await kit.table(
      columns: [l10n.colMonth, l10n.cfCashIn, l10n.cfCashOut, l10n.colNet, l10n.cfClosing],
      rows: [
        for (final m in r.months)
          [ctx.month(m.range), pdfMoney(m.cashIn), pdfMoney(m.cashOut), pdfMoney(m.net), known(m.closing)],
        [l10n.glTotals, pdfMoney(r.cashIn), pdfMoney(r.cashOut), pdfMoney(net), known(r.closing)],
      ],
      shaded: {r.months.length},
      colors: {
        for (final (i, m) in r.months.indexed)
          if (_sign(m.net) != null) (i, 3): _sign(m.net)!,
      },
    ),
    pw.SizedBox(height: 10),
    await kit.text(l10n.reportBasisNote, color: pdfMuted, size: 8, maxWidth: 520),
  ];
  return kit.document(l10n.reportCashFlow, body);
}

// ---------------------------------------------------------- loan summary

Future<Uint8List> renderLoanSummaryPdf(
  LoanSummary s,
  ReportContext ctx, {
  required String businessName,
  required String ownerName,
}) async {
  final l10n = ctx.l10n;
  final kit = PdfText();
  final code = s.currency.code;
  String money(Money m) => '${pdfMoney(m)} $code';

  final profile = <(String, String)>[
    if (businessName.trim().isNotEmpty) (l10n.lsBusiness, businessName.trim()),
    if (ownerName.trim().isNotEmpty) (l10n.lsOwner, ownerName.trim()),
    if (s.firstRecord != null)
      (l10n.lsRecordsSince, pdfDate(fromDateKey(s.firstRecord!))),
    (l10n.cashOnHand, s.cash == null ? l10n.notSet : money(s.cash!)),
  ];

  final figures = <(String, String)>[
    (l10n.lsAvgIncome, money(s.averageIncome)),
    (l10n.lsAvgExpenses, money(s.averageExpenses)),
    (l10n.lsAvgProfit, money(s.averageProfit)),
    (l10n.lsAvgWithdrawals, money(s.averageWithdrawals)),
    (l10n.lsAvgSurplus, money(s.averageSurplus)),
    (l10n.isMargin, s.marginPercent == null ? '-' : '${s.marginPercent}%'),
    (
      l10n.lsProfitableMonths,
      l10n.lsOutOf('${s.profitableMonths}', '${s.averagedMonths}'),
    ),
    (
      l10n.lsRunway,
      s.runwayDays == null
          ? '-'
          : l10n.lsDays(s.runwayDays! > 365 ? '365+' : '${s.runwayDays}'),
    ),
  ];

  final totalIncome = s.current.income;
  final body = <pw.Widget>[
    ...await kit.header(
      title: l10n.reportLoanSummary,
      lines: reportLines(l10n, s.range, ctx.today, s.currency, ctx.generatedAt, ctx.locale),
    ),
    await kit.figures(profile),
    await kit.heading(l10n.lsKeyFigures),
    await kit.figures(figures),
    await kit.text(
      l10n.lsAveragesNote('${s.averagedMonths}'),
      color: pdfMuted,
      size: 8,
      maxWidth: 520,
    ),
    await kit.heading(l10n.lsMonthly),
    await kit.table(
      columns: [l10n.colMonth, l10n.isIncome, l10n.isExpenses, l10n.chartProfit, l10n.cfOwnerOut],
      rows: [
        for (final m in s.months)
          [
            ctx.month(m.range),
            pdfMoney(m.totals.income),
            pdfMoney(m.totals.expense),
            pdfMoney(m.totals.profit),
            pdfMoney(m.totals.ownerWithdrawal),
          ],
        [
          l10n.glTotals,
          pdfMoney(s.current.income),
          pdfMoney(s.current.expense),
          pdfMoney(s.current.profit),
          pdfMoney(s.current.ownerWithdrawal),
        ],
      ],
      shaded: {s.months.length},
      colors: {
        for (final (i, m) in s.months.indexed)
          if (_sign(m.totals.profit) != null) (i, 3): _sign(m.totals.profit)!,
      },
    ),
    await kit.heading(l10n.lsIncomeSources),
    await kit.table(
      columns: [l10n.category, l10n.amount, l10n.lsShare],
      rows: [
        for (final MapEntry(:key, :value) in s.incomeSources)
          [
            ctx.categoryName(key),
            pdfMoney(value),
            '${roundedPercent(value.minor, totalIncome.minor)}%',
          ],
      ],
    ),
    await kit.heading(l10n.lsCommitments),
    if (s.commitments.isEmpty)
      await kit.text(l10n.lsNoCommitments, color: pdfMuted)
    else
      await kit.table(
        columns: [l10n.description, l10n.lsDayOfMonth, l10n.amount],
        rows: [
          for (final r in s.commitments)
            [r.description, '${r.dayOfMonth}', pdfMoney(r.typical)],
          [l10n.lsCommitmentsTotal, '', pdfMoney(s.commitmentsPerMonth)],
        ],
        shaded: {s.commitments.length},
      ),
    pw.SizedBox(height: 14),
    await kit.text(l10n.lsDisclaimer, color: pdfMuted, size: 8, maxWidth: 520),
  ];
  return kit.document(l10n.reportLoanSummary, body);
}
