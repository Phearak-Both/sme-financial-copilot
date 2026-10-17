import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../core/date_only.dart';
import '../../core/money/currency.dart';
import '../../data/database.dart';
import '../../data/ledger_repository.dart';
import '../../domain/enums.dart';
import '../../finance_core/period_math.dart';
import '../../l10n/app_localizations.dart';

/// Periods offered for export. Whole calendar months, including the
/// current one (like the dashboard's "last 3 months").
enum ExportPeriod {
  thisMonth(1),
  last3Months(3),
  last6Months(6),
  lastYear(12);

  const ExportPeriod(this.months);
  final int months;

  DateRange rangeFor(DateTime today) => DateRange(
    DateTime(today.year, today.month - (months - 1)),
    DateTime(today.year, today.month + 1),
  );
}

// ------------------------------------------------------------ options UI

/// Asks which currency and period to export, then exports.
Future<void> showExportSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ExportSheet(),
    );

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet();

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  Currency _currency = Currency.usd;
  ExportPeriod _period = ExportPeriod.thisMonth;
  bool _busy = false;

  String _periodLabel(AppLocalizations l10n, ExportPeriod period) =>
      switch (period) {
        ExportPeriod.thisMonth => l10n.periodThisMonth,
        ExportPeriod.last3Months => l10n.periodLast3Months,
        ExportPeriod.last6Months => l10n.periodLast6Months,
        ExportPeriod.lastYear => l10n.periodLastYear,
      };

  Future<void> _export() async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    await exportGeneralLedger(context, ref, _currency, _period);
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final today = dateOnly(DateTime.now());
    final dates = DateFormat('dd/MM/yyyy');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.exportTitle, style: textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(l10n.exportCurrency, style: textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<Currency>(
              segments: [
                for (final c in Currency.values)
                  ButtonSegment(
                    value: c,
                    label: Text('${c.code} (${c.symbol})'),
                  ),
              ],
              selected: {_currency},
              onSelectionChanged: _busy
                  ? null
                  : (value) => setState(() => _currency = value.single),
            ),
            const SizedBox(height: 16),
            Text(l10n.exportPeriod, style: textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final period in ExportPeriod.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: !_busy,
                selected: period == _period,
                title: Text(_periodLabel(l10n, period)),
                subtitle: Text(
                  '${dates.format(period.rangeFor(today).start)} – '
                  '${dates.format(today)}',
                ),
                trailing: Icon(
                  period == _period
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                onTap: () => setState(() => _period = period),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share),
              label: Text(l10n.exportPdf),
              onPressed: _busy ? null : _export,
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds the general ledger PDF for [currency] over [period] and opens
/// the share sheet (save to Files, AirDrop, print, ...).
Future<void> exportGeneralLedger(
  BuildContext context,
  WidgetRef ref,
  Currency currency,
  ExportPeriod period,
) async {
  final l10n = context.l10n;
  final locale = context.localeTag;
  final isKhmer = context.isKhmer;
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(ledgerRepositoryProvider);
  try {
    final now = DateTime.now();
    final ledger = buildGeneralLedger(
      entries: await repo.watchEntries(const LedgerFilter()).first,
      openings: await repo.watchOpeningBalances().first,
      categories: {for (final c in await repo.watchCategories().first) c.id: c},
      currency: currency,
      range: period.rangeFor(now),
      today: now,
      l10n: l10n,
      isKhmer: isKhmer,
    );
    final pdf = await renderGeneralLedgerPdf(
      ledger,
      l10n: l10n,
      locale: locale,
      generatedAt: now,
    );
    final filename = 'general-ledger-${currency.code}-${toDateKey(now)}.pdf';
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      // Desktop: a normal Save dialog that writes a .pdf file.
      final location = await getSaveLocation(
        suggestedName: filename,
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'PDF',
            extensions: ['pdf'],
            mimeTypes: ['application/pdf'],
            uniformTypeIdentifiers: ['com.adobe.pdf'],
          ),
        ],
      );
      if (location == null) return; // cancelled
      await File(location.path).writeAsBytes(pdf, flush: true);
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportSaved)));
    } else {
      // Phones: the share sheet, which has "Save to Files" as well.
      await Printing.sharePdf(bytes: pdf, filename: filename);
    }
  } catch (e, stack) {
    debugPrint('[export] failed: $e\n$stack');
    messenger.showSnackBar(SnackBar(content: Text(l10n.exportFailed)));
  }
}

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
String glAmount(int minor, Currency currency) {
  final format = NumberFormat.decimalPatternDigits(
    locale: 'en',
    decimalDigits: currency.exponent,
  );
  var value = minor.abs().toDouble();
  for (var i = 0; i < currency.exponent; i++) {
    value /= 10;
  }
  return '${minor < 0 ? '-' : ''}${format.format(value)}';
}

// ----------------------------------------------------------------- render

const _forest = PdfColor.fromInt(0xFF1E4D3B);
const _beige = PdfColor.fromInt(0xFFF4EEE3);
const _ivory = PdfColor.fromInt(0xFFFAF7F1);
const _line = PdfColor.fromInt(0xFFC9C2B4);
const _muted = PdfColor.fromInt(0xFF555555);

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
}) async {
  final regular = pw.Font.helvetica();
  final bold = pw.Font.helveticaBold();
  final day = DateFormat('dd/MM/yyyy');
  String date(String key) => day.format(fromDateKey(key));
  final c = ledger.currency;

  Future<pw.Widget> text(
    String value, {
    double size = 8.5,
    bool isBold = false,
    PdfColor color = PdfColors.black,
    double? maxWidth,
  }) async {
    if (!_needsShaping(value)) {
      return _latinLine(
        size,
        pw.Text(
          value,
          style: pw.TextStyle(
            font: isBold ? bold : regular,
            fontSize: size,
            color: color,
          ),
        ),
      );
    }
    return _shapedText(
      value,
      size: size,
      bold: isBold,
      color: Color(color.toInt()),
      maxWidth: maxWidth,
    );
  }

  pw.Widget number(String value, {bool isBold = false}) => _latinLine(
    8.5,
    pw.Text(
      value,
      textAlign: pw.TextAlign.right,
      style: pw.TextStyle(font: isBold ? bold : regular, fontSize: 8.5),
    ),
  );

  pw.Widget cell(pw.Widget child, {bool right = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    child: right
        ? pw.Align(alignment: pw.Alignment.topRight, child: child)
        : child,
  );

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
      decoration: const pw.BoxDecoration(color: _beige),
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
        decoration: r.isOpening ? const pw.BoxDecoration(color: _ivory) : null,
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
      decoration: const pw.BoxDecoration(color: _ivory),
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
      decoration: const pw.BoxDecoration(color: _ivory),
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
    await text(l10n.glTitle, size: 18, isBold: true, color: _forest),
    pw.SizedBox(height: 4),
    await text(
      l10n.glPeriod(date(ledger.firstDay), date(ledger.lastDay)),
      color: _muted,
      size: 9,
    ),
    await text(
      l10n.glGenerated(DateFormat.yMMMd(locale).add_Hm().format(generatedAt)),
      color: _muted,
      size: 9,
    ),
    pw.SizedBox(height: 16),
    await text(l10n.glAccount(c.code), size: 12, isBold: true, color: _forest),
    pw.SizedBox(height: 6),
    pw.Table(
      columnWidths: widths,
      border: pw.TableBorder.all(color: _line, width: 0.6),
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
        left: pw.BorderSide(color: _line, width: 0.6),
        right: pw.BorderSide(color: _line, width: 0.6),
        bottom: pw.BorderSide(color: _line, width: 0.6),
        horizontalInside: pw.BorderSide(color: _line, width: 0.6),
        verticalInside: pw.BorderSide(color: _line, width: 0.6),
      ),
      children: totalRows,
    ),
    if (ledger.entryCount == 0) ...[
      pw.SizedBox(height: 10),
      await text(l10n.glNoEntries, color: _muted),
    ],
    pw.SizedBox(height: 14),
    await text(l10n.glVoidedNote, color: _muted, size: 8, maxWidth: 520),
  ];

  final doc = pw.Document(title: l10n.glTitle);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 34, vertical: 40),
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: pw.TextStyle(font: regular, fontSize: 8, color: _muted),
        ),
      ),
      build: (_) => body,
    ),
  );
  return doc.save();
}

/// Pads plain PDF text so its baseline lines up with shaped (image) text
/// of the same [size], which carries extra leading and margin.
pw.Widget _latinLine(double size, pw.Widget child) => pw.Padding(
  padding: pw.EdgeInsets.only(top: size * 0.48, bottom: size * 0.42),
  child: child,
);

/// Anything beyond Latin-1 (Khmer, ៛, curly quotes) needs Flutter's shaping.
bool _needsShaping(String value) => value.runes.any((r) => r > 0xFF);

/// Draws [value] with Flutter's text engine at 4x and wraps it as a PDF
/// image sized in points.
Future<pw.Widget> _shapedText(
  String value, {
  required double size,
  required bool bold,
  required Color color,
  double? maxWidth,
}) async {
  // Khmer vowels and subscript consonants reach well above and below the
  // line, so lines get generous, evenly split leading plus a margin around
  // the image; otherwise the tops and bottoms get cropped.
  final padX = 1.0;
  final padY = size * 0.3;
  final painter = TextPainter(
    text: TextSpan(
      text: value,
      style: TextStyle(
        fontSize: size,
        height: 1.7,
        leadingDistribution: TextLeadingDistribution.even,
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  )..layout(maxWidth: maxWidth == null ? double.infinity : maxWidth - 2 * padX);
  final width = painter.width + 2 * padX;
  final height = painter.height + 2 * padY;

  const scale = 4.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(scale);
  painter.paint(canvas, Offset(padX, padY));
  painter.dispose();
  final image = await recorder.endRecording().toImage(
    (width * scale).ceil().clamp(1, 100000),
    (height * scale).ceil().clamp(1, 100000),
  );
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return pw.Image(
    pw.MemoryImage(png!.buffer.asUint8List()),
    width: width,
    height: height,
  );
}
