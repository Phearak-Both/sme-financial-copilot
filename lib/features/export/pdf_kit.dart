import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/date_only.dart';
import '../../core/money/currency.dart';
import '../../core/money/money.dart';
import '../../l10n/app_localizations.dart';

// Shared pieces for the exported PDFs: brand colours, Khmer-capable text,
// tables and saving.

const pdfForest = PdfColor.fromInt(0xFF1E4D3B);
const pdfBeige = PdfColor.fromInt(0xFFF4EEE3);
const pdfIvory = PdfColor.fromInt(0xFFFAF7F1);
const pdfLine = PdfColor.fromInt(0xFFC9C2B4);
const pdfMuted = PdfColor.fromInt(0xFF555555);
const pdfGreen = PdfColor.fromInt(0xFF2E7D4F);
const pdfRed = PdfColor.fromInt(0xFFA63D2A);

/// Amount without a symbol (the report names the currency), e.g.
/// `1,234.50` for USD or `50,000` for KHR.
String pdfAmount(int minor, Currency currency) {
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

/// `dd/MM/yyyy`, the same in both languages.
String pdfDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

/// Builds PDF text. Text with non-Latin characters (Khmer) is drawn by
/// Flutter's text engine and embedded as an image, because the PDF library
/// can't shape Khmer (stacked consonants, vowel order). Numbers and dates
/// stay real PDF text.
class PdfText {
  PdfText();

  final regular = pw.Font.helvetica();
  final bold = pw.Font.helveticaBold();

  Future<pw.Widget> text(
    String value, {
    double size = 8.5,
    bool isBold = false,
    PdfColor color = PdfColors.black,
    double? maxWidth,
  }) async {
    if (!_needsShaping(value)) {
      return latinLine(
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

  /// Right-aligned Latin text, for amounts.
  pw.Widget number(
    String value, {
    bool isBold = false,
    double size = 8.5,
    PdfColor color = PdfColors.black,
  }) =>
      latinLine(
        size,
        pw.Text(
          value,
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            font: isBold ? bold : regular,
            fontSize: size,
            color: color,
          ),
        ),
      );

  pw.Widget cell(pw.Widget child, {bool right = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: right
            ? pw.Align(alignment: pw.Alignment.topRight, child: child)
            : child,
      );

  /// Title, period and generation time at the top of a report.
  Future<List<pw.Widget>> header({
    required String title,
    required List<String> lines,
  }) async =>
      [
        await text(title, size: 18, isBold: true, color: pdfForest),
        pw.SizedBox(height: 4),
        for (final line in lines)
          await text(line, color: pdfMuted, size: 9, maxWidth: 520),
        pw.SizedBox(height: 14),
      ];

  Future<pw.Widget> heading(String value) async => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
        child: await text(value, size: 12, isBold: true, color: pdfForest),
      );

  /// A bordered table. The first column is a label (Khmer allowed) that
  /// takes the remaining width; the others are amounts of [amountWidth].
  /// [shaded] rows (totals) get a tinted background and bold text.
  Future<pw.Widget> table({
    required List<String> columns,
    required List<List<String>> rows,
    Set<int> shaded = const {},
    double amountWidth = 78,
    double labelWidth = 220,
    Map<(int, int), PdfColor> colors = const {},
  }) async {
    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(),
      for (var i = 1; i < columns.length; i++)
        i: pw.FixedColumnWidth(amountWidth),
    };
    final tableRows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: pdfBeige),
        children: [
          for (final (i, h) in columns.indexed)
            cell(
              await text(
                h,
                isBold: true,
                maxWidth: i == 0 ? labelWidth : amountWidth - 8,
              ),
              right: i > 0,
            ),
        ],
      ),
    ];
    for (final (r, row) in rows.indexed) {
      final isShaded = shaded.contains(r);
      tableRows.add(
        pw.TableRow(
          decoration: isShaded ? const pw.BoxDecoration(color: pdfIvory) : null,
          children: [
            for (final (i, value) in row.indexed)
              i == 0
                  ? cell(await text(value, isBold: isShaded, maxWidth: labelWidth))
                  : cell(
                      number(
                        value,
                        isBold: isShaded,
                        color: colors[(r, i)] ?? PdfColors.black,
                      ),
                      right: true,
                    ),
          ],
        ),
      );
    }
    return pw.Table(
      columnWidths: widths,
      border: pw.TableBorder.all(color: pdfLine, width: 0.6),
      children: tableRows,
    );
  }

  /// A small grid of labelled figures, two per row.
  Future<pw.Widget> figures(List<(String, String)> items) async {
    final cells = <pw.Widget>[
      for (final (label, value) in items)
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: pw.BoxDecoration(
            color: pdfIvory,
            border: pw.Border.all(color: pdfLine, width: 0.6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              await text(label, color: pdfMuted, size: 8, maxWidth: 240),
              await text(value, size: 12, isBold: true, maxWidth: 240),
            ],
          ),
        ),
    ];
    return pw.Column(
      children: [
        for (var i = 0; i < cells.length; i += 2)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: cells[i]),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: i + 1 < cells.length ? cells[i + 1] : pw.SizedBox(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// An A4 document with page numbers.
  Future<Uint8List> document(String title, List<pw.Widget> body) {
    final doc = pw.Document(title: title);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 34, vertical: 40),
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(font: regular, fontSize: 8, color: pdfMuted),
          ),
        ),
        build: (_) => body,
      ),
    );
    return doc.save();
  }
}

/// Pads plain PDF text so its baseline lines up with shaped (image) text
/// of the same [size], which carries extra leading and margin.
pw.Widget latinLine(double size, pw.Widget child) => pw.Padding(
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

/// Saves [pdf]: a Save dialog on desktop, the share sheet (which has
/// "Save to Files") on phones. Returns false if the user cancelled.
Future<bool> savePdf(Uint8List pdf, String filename) async {
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
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
    if (location == null) return false;
    await File(location.path).writeAsBytes(pdf, flush: true);
    return true;
  }
  await Printing.sharePdf(bytes: pdf, filename: filename);
  return true;
}

/// Lines under a report title: period, currency and when it was made.
List<String> reportLines(
  AppLocalizations l10n,
  DateRange range,
  DateTime today,
  Currency currency,
  DateTime generatedAt,
  String locale,
) {
  final last = addDays(range.end, -1);
  final shownEnd = dateOnly(today).isBefore(last) ? dateOnly(today) : last;
  return [
    l10n.glPeriod(pdfDate(range.start), pdfDate(shownEnd)),
    '${l10n.exportCurrency}: ${currency.code} (${currency.symbol})',
    l10n.glGenerated(DateFormat.yMMMd(locale).add_Hm().format(generatedAt)),
  ];
}

/// A signed amount for tables, e.g. `-12.50`.
String pdfMoney(Money m) => pdfAmount(m.minor, m.currency);
