import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../app/labels.dart';
import '../../core/date_only.dart';
import '../../core/money/currency.dart';
import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../finance_core/period_math.dart';
import '../../l10n/app_localizations.dart';
import '../export/pdf_kit.dart';

// ------------------------------------------------------------------ model

class GlRow {
  const GlRow({
    this.no,
    required this.day,
    required this.description,
    this.category = '',
    this.debit,
    this.credit,
    this.balance,
    this.isOpening = false,
  });

  final int? no;

  /// `yyyy-MM-dd`.
  final String day;
  final String description;
  final String category;

  /// Minor units. Debit is money in, credit is money out (cash account).
  final int? debit;
  final int? credit;

  /// Running balance, or null for entries before the opening cash date
  /// (cash math doesn't count those).
  final int? balance;
  final bool isOpening;
}

class GeneralLedger {
  const GeneralLedger({
    required this.currency,
    required this.firstDay,
    required this.lastDay,
    required this.rows,
    required this.entryCount,
    required this.totalDebit,
    required this.totalCredit,
    required this.closing,
  });

  final Currency currency;

  /// The period shown, `yyyy-MM-dd`, both inclusive.
  final String firstDay;
  final String lastDay;
  final List<GlRow> rows;
  final int entryCount;
  final int totalDebit;
  final int totalCredit;

  /// Null when the opening cash date is after the period, so no balance
  /// is known yet.
  final int? closing;
}

/// The cash account for [currency] over [range]: an opening balance row
/// (cash brought into the period), the period's active entries in date
/// order, and running balances matching the app's cash-on-hand math.
/// Voided entries are left out.
GeneralLedger buildGeneralLedger({
  required List<EntryRow> entries,
  required List<OpeningBalance> openings,
  required Map<String, CategoryRow> categories,
  required Currency currency,
  required DateRange range,
  required DateTime today,
  required AppLocalizations l10n,
  required bool isKhmer,
}) {
  final start = toDateKey(range.start);
  final end = toDateKey(range.end); // exclusive
  final active =
      entries
          .where(
            (e) =>
                e.status == EntryStatus.active && e.currency == currency.code,
          )
          .toList()
        ..sort((a, b) {
          final byDate = a.occurredOn.compareTo(b.occurredOn);
          return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
        });
  int net(Iterable<EntryRow> list) => list.fold(
    0,
    (sum, e) => sum + (e.type.isMoneyIn ? e.amountMinor : -e.amountMinor),
  );

  final opening = openings.where((o) => o.currency == currency).firstOrNull;
  final rows = <GlRow>[];
  int? balance;
  void addOpening(String day, int amount) {
    balance = amount;
    rows.add(
      GlRow(
        day: day,
        description: l10n.glOpening,
        balance: amount,
        isOpening: true,
      ),
    );
  }

  // Cash brought into the period. With an opening cash amount, count from
  // its date; without one, from the first entry.
  var openingPending = false;
  if (opening == null) {
    addOpening(
      start,
      net(active.where((e) => e.occurredOn.compareTo(start) < 0)),
    );
  } else if (opening.asOf.compareTo(start) <= 0) {
    addOpening(
      start,
      opening.amountMinor +
          net(
            active.where(
              (e) =>
                  e.occurredOn.compareTo(opening.asOf) >= 0 &&
                  e.occurredOn.compareTo(start) < 0,
            ),
          ),
    );
  } else {
    openingPending = true;
  }

  var no = 0;
  var debit = 0;
  var credit = 0;
  final inPeriod = active.where(
    (e) =>
        e.occurredOn.compareTo(start) >= 0 && e.occurredOn.compareTo(end) < 0,
  );
  for (final e in inPeriod) {
    // An opening cash date inside the period: its row goes just before the
    // first entry it applies to; earlier entries have no known balance.
    if (openingPending && e.occurredOn.compareTo(opening!.asOf) >= 0) {
      openingPending = false;
      addOpening(opening.asOf, opening.amountMinor);
    }
    final moneyIn = e.type.isMoneyIn;
    if (moneyIn) {
      debit += e.amountMinor;
    } else {
      credit += e.amountMinor;
    }
    if (balance != null) {
      balance = balance! + (moneyIn ? e.amountMinor : -e.amountMinor);
    }

    final type = l10n.entryType(e.type);
    final category = categories[e.categoryId];
    rows.add(
      GlRow(
        no: ++no,
        day: e.occurredOn,
        description: e.description.trim().isEmpty ? type : e.description.trim(),
        category: e.type.categoryKind == null
            ? type
            : category == null
            ? l10n.uncategorized
            : (isKhmer ? category.nameKm : category.nameEn),
        debit: moneyIn ? e.amountMinor : null,
        credit: moneyIn ? null : e.amountMinor,
        balance: balance,
      ),
    );
  }
  if (openingPending && opening!.asOf.compareTo(end) < 0) {
    addOpening(opening.asOf, opening.amountMinor);
  }

  final lastDay = addDays(range.end, -1);
  return GeneralLedger(
    currency: currency,
    firstDay: start,
    lastDay: toDateKey(
      dateOnly(today).isBefore(lastDay) ? dateOnly(today) : lastDay,
    ),
    rows: rows,
    entryCount: no,
    totalDebit: debit,
    totalCredit: credit,
    closing: balance,
  );
}

/// Amount without a symbol (the account heading names the currency), e.g.
/// `1,234.50` for USD or `50,000` for KHR.
String glAmount(int minor, Currency currency) => pdfAmount(minor, currency);

// ----------------------------------------------------------------- render

/// Lays out the ledger as an A4 PDF.
///
/// Text with non-Latin characters (Khmer) is drawn by Flutter's text engine
/// and embedded as an image, because the PDF library can't shape Khmer
/// (stacked consonants, vowel order). Numbers and dates stay real PDF text.
Future<Uint8List> renderGeneralLedgerPdf(
  GeneralLedger ledger, {
  required AppLocalizations l10n,
  required String locale,
  required DateTime generatedAt,
  String? title,
}) async {
  final kit = PdfText();
  final text = kit.text;
  final number = kit.number;
  final cell = kit.cell;
  final day = DateFormat('dd/MM/yyyy');
  String date(String key) => day.format(fromDateKey(key));
  final c = ledger.currency;

  // Column widths in points; description takes the rest of the page.
  const descriptionWidth = 140.0;
  const categoryWidth = 84.0;
  const widths = {
    0: pw.FixedColumnWidth(24),
    1: pw.FixedColumnWidth(56),
    2: pw.FlexColumnWidth(),
    3: pw.FixedColumnWidth(categoryWidth + 8),
    4: pw.FixedColumnWidth(66),
    5: pw.FixedColumnWidth(66),
    6: pw.FixedColumnWidth(70),
  };

  // Room for each heading inside its column (column width minus padding),
  // so long Khmer headings wrap instead of running over.
  const headerWidths = [
    16.0,
    48.0,
    descriptionWidth,
    categoryWidth,
    58.0,
    58.0,
    62.0,
  ];
  final header = [
    l10n.glNo,
    l10n.date,
    l10n.description,
    l10n.category,
    l10n.glDebit,
    l10n.glCredit,
    l10n.glBalance,
  ];

  final rows = <pw.TableRow>[
    pw.TableRow(
      repeat: true,
      decoration: const pw.BoxDecoration(color: pdfBeige),
      children: [
        for (final (i, h) in header.indexed)
          cell(
            await text(h, isBold: true, maxWidth: headerWidths[i]),
            right: i >= 4,
          ),
      ],
    ),
  ];
  for (final r in ledger.rows) {
    rows.add(
      pw.TableRow(
        decoration: r.isOpening ? const pw.BoxDecoration(color: pdfIvory) : null,
        children: [
          cell(number(r.no?.toString() ?? ''), right: true),
          cell(number(date(r.day))),
          cell(
            await text(
              r.description,
              isBold: r.isOpening,
              maxWidth: descriptionWidth,
            ),
          ),
          cell(await text(r.category, maxWidth: categoryWidth)),
          cell(
            number(r.debit == null ? '' : glAmount(r.debit!, c)),
            right: true,
          ),
          cell(
            number(r.credit == null ? '' : glAmount(r.credit!, c)),
            right: true,
          ),
          cell(
            number(
              r.balance == null ? '-' : glAmount(r.balance!, c),
              isBold: r.isOpening,
            ),
            right: true,
          ),
        ],
      ),
    );
  }
  // Totals sit in a second table attached below, whose first column spans
  // No. to Category, so the labels start at the left edge.
  final totalRows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: pdfIvory),
      children: [
        cell(await text(l10n.glTotals, isBold: true)),
        cell(number(glAmount(ledger.totalDebit, c), isBold: true), right: true),
        cell(
          number(glAmount(ledger.totalCredit, c), isBold: true),
          right: true,
        ),
        pw.SizedBox(),
      ],
    ),
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: pdfIvory),
      children: [
        cell(await text(l10n.glClosing, isBold: true)),
        pw.SizedBox(),
        pw.SizedBox(),
        cell(
          number(
            ledger.closing == null ? '-' : glAmount(ledger.closing!, c),
            isBold: true,
          ),
          right: true,
        ),
      ],
    ),
  ];

  final body = <pw.Widget>[
    await text(title ?? l10n.glTitle, size: 18, isBold: true, color: pdfForest),
    pw.SizedBox(height: 4),
    await text(
      l10n.glPeriod(date(ledger.firstDay), date(ledger.lastDay)),
      color: pdfMuted,
      size: 9,
    ),
    await text(
      l10n.glGenerated(DateFormat.yMMMd(locale).add_Hm().format(generatedAt)),
      color: pdfMuted,
      size: 9,
    ),
    pw.SizedBox(height: 16),
    await text(l10n.glAccount(c.code), size: 12, isBold: true, color: pdfForest),
    pw.SizedBox(height: 6),
    pw.Table(
      columnWidths: widths,
      border: pw.TableBorder.all(color: pdfLine, width: 0.6),
      children: rows,
    ),
    pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(),
        1: widths[4]!,
        2: widths[5]!,
        3: widths[6]!,
      },
      border: const pw.TableBorder(
        left: pw.BorderSide(color: pdfLine, width: 0.6),
        right: pw.BorderSide(color: pdfLine, width: 0.6),
        bottom: pw.BorderSide(color: pdfLine, width: 0.6),
        horizontalInside: pw.BorderSide(color: pdfLine, width: 0.6),
        verticalInside: pw.BorderSide(color: pdfLine, width: 0.6),
      ),
      children: totalRows,
    ),
    if (ledger.entryCount == 0) ...[
      pw.SizedBox(height: 10),
      await text(l10n.glNoEntries, color: pdfMuted),
    ],
    pw.SizedBox(height: 14),
    await text(l10n.glVoidedNote, color: pdfMuted, size: 8, maxWidth: 520),
  ];

  return kit.document(title ?? l10n.glTitle, body);
}
