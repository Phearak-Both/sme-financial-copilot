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
import '../../finance_core/period_math.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Language names are shown in their own script so either is recognisable.
  static const _languageNames = {'km': 'ខ្មែរ', 'en': 'English'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(localeProvider).value ?? defaultLocale;
    final openings = {
      for (final o in ref.watch(openingBalancesProvider).value ?? const [])
        o.currency: o,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _SectionHeader(l10n.language),
          SegmentedButton<String>(
            showSelectedIcon: false,
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
          _SectionHeader(l10n.openingCash),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, currency) in Currency.values.indexed) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    shape: const RoundedRectangleBorder(),
                    leading: CircleAvatar(
                      radius: 18,
                      child: Text(currency.symbol),
                    ),
                    title: Text(currency.code),
                    subtitle: Text(
                      openings[currency] == null
                          ? l10n.notSet
                          : l10n.asOfValue(
                              formatMoney(
                                Money(
                                  openings[currency]!.amountMinor,
                                  currency,
                                ),
                                locale: context.localeTag,
                              ),
                              context.dayLabel(openings[currency]!.asOf),
                            ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => _OpeningCashDialog(
                        currency: currency,
                        existing: openings[currency],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _SectionNote(l10n.openingCashHelp),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _SectionNote extends StatelessWidget {
  const _SectionNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
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
