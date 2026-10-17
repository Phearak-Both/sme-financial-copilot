import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../core/date_only.dart';
import '../../core/money/currency.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../core/money/money_parser.dart';
import '../../data/demo_data.dart';
import '../../finance_core/period_math.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Language names are shown in their own script so either is recognisable.
  static const _languageNames = {'km': 'ខ្មែរ', 'en': 'English'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final current = ref.watch(localeProvider).value ?? defaultLocale;
    final ledgerIsEmpty =
        ref.watch(recentEntriesProvider).value?.isEmpty ?? false;
    final openings = {
      for (final o in ref.watch(openingBalancesProvider).value ?? const [])
        o.currency: o,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.language, style: textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              for (final locale in supportedAppLocales)
                ButtonSegment(
                  value: locale.languageCode,
                  label: Text(_languageNames[locale.languageCode]!),
                ),
            ],
            selected: {current.languageCode},
            onSelectionChanged: (selection) => ref
                .read(ledgerRepositoryProvider)
                .setSetting(localeSettingKey, selection.first),
          ),
          const SizedBox(height: 32),
          Text(l10n.openingCash, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.openingCashHelp, style: textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final currency in Currency.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(currency.symbol)),
              title: Text(currency.code),
              subtitle: Text(
                openings[currency] == null
                    ? l10n.notSet
                    : l10n.asOfValue(
                        formatMoney(
                          Money(openings[currency]!.amountMinor, currency),
                          locale: context.localeTag,
                        ),
                        context.dayLabel(openings[currency]!.asOf),
                      ),
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => _OpeningCashDialog(
                  currency: currency,
                  existing: openings[currency],
                ),
              ),
            ),
          const SizedBox(height: 32),
          Text(l10n.demoSection, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.loadSampleDataBody, style: textTheme.bodySmall),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(l10n.loadSampleData),
              onPressed: ledgerIsEmpty
                  ? () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final count =
                          await loadDemoData(ref.read(ledgerRepositoryProvider));
                      messenger.showSnackBar(SnackBar(
                        content: Text(l10n.sampleDataLoaded(count)),
                      ));
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpeningCashDialog extends ConsumerStatefulWidget {
  const _OpeningCashDialog({required this.currency, this.existing});

  final Currency currency;
  final OpeningBalance? existing;

  @override
  ConsumerState<_OpeningCashDialog> createState() => _OpeningCashDialogState();
}

class _OpeningCashDialogState extends ConsumerState<_OpeningCashDialog> {
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : minorToInputString(widget.existing!.amountMinor, widget.currency),
  );
  late DateTime _asOf = widget.existing == null
      ? DateTime(DateTime.now().year, DateTime.now().month)
      : fromDateKey(widget.existing!.asOf);
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOf.isAfter(today) ? today : _asOf,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked != null) setState(() => _asOf = dateOnly(picked));
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final text = _amount.text.trim();
    // Zero is a valid opening balance, which parseAmount rejects.
    final isZero = RegExp(r'^[0០]+([.][0០]*)?$').hasMatch(text);
    final parsed = parseAmount(text, widget.currency);
    if (!isZero && !parsed.isOk) {
      setState(() => _error = l10n.amountError(parsed.error!, widget.currency.code));
      return;
    }
    await ref.read(ledgerRepositoryProvider).setOpeningBalance(
          widget.currency,
          isZero ? 0 : parsed.minor!,
          _asOf,
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clear() async {
    await ref.read(ledgerRepositoryProvider).clearOpeningBalance(widget.currency);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text('${l10n.openingCash} (${widget.currency.code})'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(
              decimal: widget.currency.exponent > 0,
            ),
            decoration: InputDecoration(
              labelText: l10n.amount,
              suffixText: widget.currency.symbol,
              errorText: _error,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(l10n.asOf),
            trailing: Text(DateFormat.yMMMd(context.localeTag).format(_asOf)),
            onTap: _pickDate,
          ),
        ],
      ),
      actions: [
        if (widget.existing != null)
          TextButton(onPressed: _clear, child: Text(l10n.clear)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
