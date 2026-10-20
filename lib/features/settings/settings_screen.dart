import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../cloud/auth.dart';
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
    final current = ref.watch(localeProvider).value ?? defaultLocale;
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.light;
    final openings = {
      for (final o in ref.watch(openingBalancesProvider).value ?? const [])
        o.currency: o,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const _AccountSection(),
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
                .read(settingsStoreProvider)
                .set(localeSettingKey, selection.first),
          ),
          _SectionHeader(l10n.appearance),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.themeDark),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) => ref
                .read(settingsStoreProvider)
                .set(themeModeSettingKey, selection.first.name),
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
          _SectionHeader(l10n.sampleData),
          const _SampleDataTile(),
          _SectionNote(l10n.loadSampleHelp),
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
    try {
      await ref.read(ledgerRepositoryProvider).setOpeningBalance(
            widget.currency,
            isZero ? 0 : parsed.minor!,
            _asOf,
          );
    } catch (_) {
      if (mounted) setState(() => _error = l10n.saveFailed);
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clear() async {
    try {
      await ref
          .read(ledgerRepositoryProvider)
          .clearOpeningBalance(widget.currency);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.saveFailed);
      return;
    }
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

/// Who is signed in, with a way to log out. Hidden without Supabase.
class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final name = (user.userMetadata?['full_name'] as String?)?.trim() ?? '';
    // Phone accounts sign in with a hidden address; show the number instead.
    final phone = user.userMetadata?['phone'] as String?;
    final contact = phone != null ? formatPhone(phone) : (user.email ?? '');
    final initial =
        (name.isNotEmpty ? name : contact).characters.firstOrNull ?? '?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(l10n.account),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: CircleAvatar(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  child: Text(initial.toUpperCase()),
                ),
                title: Text(name.isNotEmpty ? name : contact),
                subtitle: name.isNotEmpty ? Text(contact) : null,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: Icon(Icons.logout, color: scheme.error),
                title: Text(l10n.logOut, style: TextStyle(color: scheme.error)),
                onTap: () => _confirmLogOut(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogOut(BuildContext context) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logOutTitle),
        content: Text(l10n.logOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
    if (ok == true) await signOut();
  }
}

/// Adds example records so every dashboard view has something to show.
class _SampleDataTile extends ConsumerStatefulWidget {
  const _SampleDataTile();

  @override
  ConsumerState<_SampleDataTile> createState() => _SampleDataTileState();
}

class _SampleDataTileState extends ConsumerState<_SampleDataTile> {
  bool _loading = false;

  Future<void> _load() async {
    final l10n = context.l10n;
    final count = demoDrafts(DateTime.now()).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.loadSampleTitle),
        content: Text(l10n.loadSampleBody('$count')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.add),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      final added = await loadDemoData(ref.read(ledgerRepositoryProvider));
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.loadSampleDone('$added'))),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const Icon(Icons.dataset_outlined),
      title: Text(context.l10n.loadSampleData),
      trailing: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _loading ? null : _load,
    ),
  );
}
