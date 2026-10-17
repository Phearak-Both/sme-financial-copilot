import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../core/date_only.dart';
import '../../core/money/currency.dart';
import '../../core/money/money_parser.dart';
import '../../data/database.dart';
import '../../domain/entry_draft.dart';
import '../../domain/entry_proposal.dart';
import '../../domain/enums.dart';

const lastCurrencySettingKey = 'last_currency';

/// Add a new entry, or edit [initial] when given. A [proposal] from the
/// assistant pre-fills a new entry for the user to check and save.
class EntryFormScreen extends ConsumerStatefulWidget {
  const EntryFormScreen({
    super.key,
    this.initial,
    this.initialType,
    this.proposal,
  });

  final EntryRow? initial;
  final EntryType? initialType;
  final EntryProposal? proposal;

  @override
  ConsumerState<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends ConsumerState<EntryFormScreen> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _note = TextEditingController();

  late EntryType _type;
  Currency _currency = Currency.usd;
  String? _categoryId;
  DateTime _date = dateOnly(DateTime.now());
  PaymentMethod? _paymentMethod;

  String? _amountError;
  bool _categoryError = false;
  bool _dateError = false;
  bool _saving = false;

  /// True while the assistant didn't know the currency and the user
  /// hasn't picked one yet.
  bool _currencyUnconfirmed = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _type = initial.type;
      _currency = Currency.fromCode(initial.currency);
      _amount.text = minorToInputString(initial.amountMinor, _currency);
      _categoryId = initial.categoryId;
      _date = fromDateKey(initial.occurredOn);
      _description.text = initial.description;
      _note.text = initial.note ?? '';
      _paymentMethod = initial.paymentMethod;
    } else if (widget.proposal case final proposal?) {
      _type = proposal.type;
      _amount.text = proposal.amountText ?? '';
      _categoryId = proposal.categoryId;
      _date = proposal.occurredOn ?? _date;
      _description.text = proposal.description;
      _note.text = proposal.rawInput ?? '';
      _paymentMethod = proposal.paymentMethod;
      if (proposal.currency case final currency?) {
        _currency = currency;
      } else {
        _currencyUnconfirmed = true;
        _loadLastCurrency();
      }
    } else {
      _type = widget.initialType ?? EntryType.expense;
      _loadLastCurrency();
    }
  }

  Future<void> _loadLastCurrency() async {
    final code = await ref
        .read(ledgerRepositoryProvider)
        .watchSetting(lastCurrencySettingKey)
        .first;
    if (!mounted || code == null) return;
    setState(() => _currency = Currency.fromCode(code));
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _note.dispose();
    super.dispose();
  }

  void _setType(EntryType type) {
    setState(() {
      if (type.categoryKind != _type.categoryKind) _categoryId = null;
      _type = type;
      _categoryError = false;
    });
  }

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked != null) {
      setState(() {
        _date = dateOnly(picked);
        _dateError = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = context.l10n;
    final repo = ref.read(ledgerRepositoryProvider);
    final categories = ref.read(categoriesByIdProvider);

    final parsed = parseAmount(_amount.text, _currency);
    final draft = EntryDraft(
      type: _type,
      amountMinor: parsed.minor ?? 0,
      currency: _currency,
      occurredOn: _date,
      categoryId: _categoryId,
      categoryKind: categories[_categoryId]?.kind,
      description: _description.text,
      note: _note.text,
      paymentMethod: _paymentMethod,
      source: widget.proposal?.source ?? EntrySource.manual,
    );
    final errors = validateDraft(draft, today: DateTime.now());

    setState(() {
      _amountError = parsed.isOk
          ? null
          : l10n.amountError(parsed.error!, _currency.code);
      _categoryError =
          errors.contains(DraftError.categoryRequired) ||
          errors.contains(DraftError.categoryMismatch);
      _dateError = errors.contains(DraftError.futureDate);
    });
    if (!parsed.isOk || errors.isNotEmpty || _currencyUnconfirmed) return;

    setState(() => _saving = true);
    try {
      final duplicates = await repo.findPossibleDuplicates(
        draft,
        excludeId: widget.initial?.id,
      );
      if (duplicates.isNotEmpty && mounted) {
        final proceed = await _confirmDuplicate(duplicates.length);
        if (!proceed) return;
      }

      if (_isEdit) {
        await repo.update(widget.initial!.id, draft);
      } else {
        await repo.create(draft);
      }
      await repo.setSetting(lastCurrencySettingKey, _currency.code);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEdit ? l10n.updatedMessage : l10n.savedMessage),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.somethingWrong)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDuplicate(int count) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.duplicateTitle),
        content: Text(l10n.duplicateBody(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.saveAnyway),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final kind = _type.categoryKind;
    final visibleCategories = kind == null
        ? const <CategoryRow>[]
        : categories.where((c) => c.kind == kind);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.editEntry : l10n.newEntry)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.proposal != null) ...[
              Card(
                margin: EdgeInsets.zero,
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: Text(l10n.proposalReviewHint),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in EntryType.values)
                  ChoiceChip(
                    avatar: Icon(entryTypeIcon(type), size: 18),
                    label: Text(l10n.entryType(type)),
                    selected: _type == type,
                    onSelected: (_) => _setType(type),
                  ),
              ],
            ),
            if (_type.isOwnerMovement) ...[
              const SizedBox(height: 8),
              Text(l10n.ownerHelp, style: textTheme.bodySmall),
            ],
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    autofocus: !_isEdit,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: _currency.exponent > 0,
                    ),
                    style: textTheme.headlineSmall,
                    decoration: InputDecoration(
                      labelText: l10n.amount,
                      errorText: _amountError,
                      border: const OutlineInputBorder(),
                      suffixText: _currency.symbol,
                    ),
                    onChanged: (_) {
                      if (_amountError != null) {
                        setState(() => _amountError = null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<Currency>(
                  segments: [
                    for (final c in Currency.values)
                      ButtonSegment(value: c, label: Text(c.code)),
                  ],
                  selected: {_currency},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) => setState(() {
                    _currency = selection.first;
                    _amountError = null;
                    _currencyUnconfirmed = false;
                  }),
                ),
              ],
            ),
            if (_currencyUnconfirmed)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.confirmCurrency,
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            if (kind != null) ...[
              const SizedBox(height: 20),
              Text(l10n.category, style: textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in visibleCategories)
                    ChoiceChip(
                      label: Text(context.categoryName(category)),
                      selected: _categoryId == category.id,
                      onSelected: (_) => setState(() {
                        _categoryId = category.id;
                        _categoryError = false;
                      }),
                    ),
                ],
              ),
              if (_categoryError)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.errorCategory,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(l10n.date),
              subtitle: _dateError
                  ? Text(
                      l10n.errorFutureDate,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  : null,
              trailing: Text(
                DateFormat.yMMMd(context.localeTag).format(_date),
                style: textTheme.bodyLarge,
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.description,
                hintText: l10n.descriptionHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.paymentMethod, style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final method in PaymentMethod.values)
                  ChoiceChip(
                    label: Text(l10n.paymentMethodLabel(method)),
                    selected: _paymentMethod == method,
                    onSelected: (selected) => setState(
                      () => _paymentMethod = selected ? method : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _note,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: l10n.note,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
