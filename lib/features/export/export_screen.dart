import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../cloud/auth.dart';
import '../../core/date_only.dart';
import '../../core/money/currency.dart';
import '../../data/ledger_repository.dart';
import '../../finance_core/reports.dart';
import '../../l10n/app_localizations.dart';
import '../ledger/ledger_export.dart';
import 'pdf_kit.dart';
import 'report_pdfs.dart';

/// The reports that can be exported.
enum ReportKind { accountStatement, incomeStatement, cashFlow, loanSummary }

extension on ReportKind {
  String title(AppLocalizations l10n) => switch (this) {
        ReportKind.accountStatement => l10n.reportAccountStatement,
        ReportKind.incomeStatement => l10n.reportIncomeStatement,
        ReportKind.cashFlow => l10n.reportCashFlow,
        ReportKind.loanSummary => l10n.reportLoanSummary,
      };

  String description(AppLocalizations l10n) => switch (this) {
        ReportKind.accountStatement => l10n.reportAccountStatementDesc,
        ReportKind.incomeStatement => l10n.reportIncomeStatementDesc,
        ReportKind.cashFlow => l10n.reportCashFlowDesc,
        ReportKind.loanSummary => l10n.reportLoanSummaryDesc,
      };

  IconData get icon => switch (this) {
        ReportKind.accountStatement => Icons.receipt_long_outlined,
        ReportKind.incomeStatement => Icons.stacked_bar_chart_rounded,
        ReportKind.cashFlow => Icons.swap_vert_rounded,
        ReportKind.loanSummary => Icons.account_balance_outlined,
      };

  /// The period each report usually covers.
  ReportRange get defaultRange => switch (this) {
        ReportKind.accountStatement => ReportRange.thisMonth,
        ReportKind.incomeStatement => ReportRange.lastMonth,
        ReportKind.cashFlow => ReportRange.last3Months,
        ReportKind.loanSummary => ReportRange.last12Months,
      };

  /// For file names.
  String get slug => switch (this) {
        ReportKind.accountStatement => 'account-statement',
        ReportKind.incomeStatement => 'income-statement',
        ReportKind.cashFlow => 'cash-flow',
        ReportKind.loanSummary => 'loan-summary',
      };
}

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportPageTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            l10n.exportPageIntro,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            // Two columns on phones, four on wide windows. Cards in a row
            // share the height of the tallest, which grows with its text.
            final columns = constraints.maxWidth >= 720 ? 4 : 2;
            const gap = 12.0;
            const kinds = ReportKind.values;
            return Column(
              children: [
                for (var i = 0; i < kinds.length; i += columns)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var j = i; j < i + columns; j++) ...[
                            if (j > i) const SizedBox(width: gap),
                            Expanded(
                              child: j < kinds.length
                                  ? _ReportCard(kinds[j])
                                  : const SizedBox(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard(this.kind);

  final ReportKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _ReportOptionsSheet(kind),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(kind.icon, color: scheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                kind.title(l10n),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                kind.description(l10n),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.download_outlined,
                      size: 16, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'PDF',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Options for one report, then generate and save.
class _ReportOptionsSheet extends ConsumerStatefulWidget {
  const _ReportOptionsSheet(this.kind);

  final ReportKind kind;

  @override
  ConsumerState<_ReportOptionsSheet> createState() =>
      _ReportOptionsSheetState();
}

class _ReportOptionsSheetState extends ConsumerState<_ReportOptionsSheet> {
  Currency _currency = Currency.usd;
  late ReportRange? _preset = widget.kind.defaultRange;
  DateRange? _custom;
  late String _language = ref.read(localeProvider).value?.languageCode ??
      defaultLocale.languageCode;
  final _business = TextEditingController();
  final _owner = TextEditingController();
  bool _busy = false;

  // Language names are shown in their own script so either is recognisable.
  static const _languageNames = {'km': 'ខ្មែរ', 'en': 'English'};

  @override
  void initState() {
    super.initState();
    if (widget.kind == ReportKind.loanSummary) {
      final user = ref.read(currentUserProvider).value;
      _owner.text = (user?.userMetadata?['full_name'] as String?)?.trim() ?? '';
      ref.read(settingsStoreProvider).get(businessNameSettingKey).then((v) {
        if (mounted && v != null && _business.text.isEmpty) _business.text = v;
      });
    }
  }

  @override
  void dispose() {
    _business.dispose();
    _owner.dispose();
    super.dispose();
  }

  DateRange get _range => _custom ?? _preset!.rangeFor(DateTime.now());

  Future<void> _pickDates() async {
    final today = dateOnly(DateTime.now());
    final current = _range;
    final last = addDays(current.end, -1);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDateRange: DateTimeRange(
        start: current.start.isAfter(today) ? today : current.start,
        end: last.isAfter(today) ? today : last,
      ),
    );
    if (picked == null) return;
    setState(() {
      _preset = null;
      _custom = DateRange(picked.start, addDays(picked.end, 1));
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      if (widget.kind == ReportKind.loanSummary &&
          _business.text.trim().isNotEmpty) {
        await ref
            .read(settingsStoreProvider)
            .set(businessNameSettingKey, _business.text.trim());
      }
      final pdf = await _build();
      final range = _range;
      final filename = '${widget.kind.slug}-${_currency.code}-'
          '${range.startKey}_${toDateKey(addDays(range.end, -1))}.pdf';
      final saved = await savePdf(pdf, filename);
      if (saved) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.exportSaved)));
        navigator.pop();
      }
    } catch (e, stack) {
      debugPrint('[export] failed: $e\n$stack');
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Builds the chosen report in the chosen language.
  Future<Uint8List> _build() async {
    final repo = ref.read(ledgerRepositoryProvider);
    final pdfL10n = lookupAppLocalizations(Locale(_language));
    final isKhmer = _language == 'km';
    final now = DateTime.now();
    final range = _range;
    final rows = await repo.watchEntries(const LedgerFilter()).first;
    final openings = await repo.watchOpeningBalances().first;
    final categories = {
      for (final c in await repo.watchCategories().first) c.id: c,
    };
    final opening = openings.where((o) => o.currency == _currency).firstOrNull;
    final entries = rows.map(toLedgerEntry).toList();
    final ctx = ReportContext(
      l10n: pdfL10n,
      locale: _language,
      categoryName: (id) {
        final c = categories[id];
        if (c == null) return pdfL10n.uncategorized;
        return isKhmer ? c.nameKm : c.nameEn;
      },
      today: now,
      generatedAt: now,
    );

    return switch (widget.kind) {
      ReportKind.accountStatement => renderGeneralLedgerPdf(
          buildGeneralLedger(
            entries: rows,
            openings: openings,
            categories: categories,
            currency: _currency,
            range: range,
            today: now,
            l10n: pdfL10n,
            isKhmer: isKhmer,
          ),
          l10n: pdfL10n,
          locale: _language,
          generatedAt: now,
          title: pdfL10n.reportAccountStatement,
        ),
      ReportKind.incomeStatement => renderIncomeStatementPdf(
          buildIncomeStatement(entries, _currency, range),
          ctx,
        ),
      ReportKind.cashFlow => renderCashFlowPdf(
          buildCashFlow(entries, _currency, range, opening: opening),
          ctx,
        ),
      ReportKind.loanSummary => renderLoanSummaryPdf(
          buildLoanSummary(entries, _currency, range,
              today: now, opening: opening),
          ctx,
          businessName: _business.text,
          ownerName: _owner.text,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final range = _range;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(widget.kind.icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.kind.title(l10n),
                        style: theme.textTheme.titleLarge),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _Label(l10n.exportCurrency),
              SegmentedButton<Currency>(
                showSelectedIcon: false,
                segments: [
                  for (final c in Currency.values)
                    ButtonSegment(value: c, label: Text('${c.code} (${c.symbol})')),
                ],
                selected: {_currency},
                onSelectionChanged: _busy
                    ? null
                    : (value) => setState(() => _currency = value.single),
              ),
              const SizedBox(height: 20),
              _Label(l10n.exportPeriod),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in ReportRange.values)
                    ChoiceChip(
                      label: Text(l10n.reportRangeLabel(r)),
                      selected: _preset == r,
                      onSelected: _busy
                          ? null
                          : (_) => setState(() {
                                _preset = r;
                                _custom = null;
                              }),
                    ),
                  ChoiceChip(
                    avatar: const Icon(Icons.date_range_outlined, size: 18),
                    label: Text(l10n.pickDates),
                    selected: _custom != null,
                    onSelected: _busy ? null : (_) => _pickDates(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                // Reports stop at today.
                context.rangeLabel(DateRange(
                  range.start,
                  range.end.isAfter(addDays(dateOnly(DateTime.now()), 1))
                      ? addDays(dateOnly(DateTime.now()), 1)
                      : range.end,
                )),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _Label(l10n.reportLanguage),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final locale in supportedAppLocales)
                    ButtonSegment(
                      value: locale.languageCode,
                      label: Text(_languageNames[locale.languageCode]!),
                    ),
                ],
                selected: {_language},
                onSelectionChanged: _busy
                    ? null
                    : (value) => setState(() => _language = value.single),
              ),
              if (widget.kind == ReportKind.loanSummary) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _business,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.businessName),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _owner,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l10n.ownerName),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(l10n.savePdf),
                onPressed: _busy ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}
