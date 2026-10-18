import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../core/money/currency.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../data/database.dart';
import '../../domain/enums.dart';

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final entry = ref.watch(entryProvider(entryId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.entryDetails),
        actions: [
          if (entry.value?.status == EntryStatus.active) ...[
            IconButton(
              tooltip: l10n.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/entry/$entryId/edit'),
            ),
            IconButton(
              tooltip: l10n.voidAction,
              icon: const Icon(Icons.block),
              onPressed: () => _confirmVoid(context, ref),
            ),
          ],
        ],
      ),
      body: entry.when(
        data: (row) => row == null
            ? Center(child: Text(l10n.entryNotFound))
            : _Details(row),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.somethingWrong)),
      ),
    );
  }

  Future<void> _confirmVoid(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.voidTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.voidBody),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              decoration: InputDecoration(labelText: l10n.voidReason),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.voidAction),
          ),
        ],
      ),
    );
    final reasonText = reason.text;
    reason.dispose();
    if (confirmed != true) return;

    try {
      await ref
          .read(ledgerRepositoryProvider)
          .voidEntry(entryId, reason: reasonText);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.voidedMessage)));
    }
  }
}

class _Details extends ConsumerWidget {
  const _Details(this.entry);

  final EntryRow entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final category = ref.watch(categoriesByIdProvider)[entry.categoryId];
    final revisions = ref.watch(revisionsProvider(entry.id)).value ?? const [];
    final isVoided = entry.status == EntryStatus.voided;
    final isIn = entry.type.isMoneyIn;
    final amount = Money(
      isIn ? entry.amountMinor : -entry.amountMinor,
      Currency.fromCode(entry.currency),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(entryTypeIcon(entry.type),
                color: isIn
                    ? MoneyColors.moneyIn(context)
                    : MoneyColors.moneyOut(context)),
            const SizedBox(width: 8),
            Text(l10n.entryType(entry.type), style: textTheme.titleMedium),
            const Spacer(),
            if (isVoided)
              Chip(
                label: Text(l10n.voided),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          formatMoney(amount, locale: context.localeTag, signed: true),
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            decoration: isVoided ? TextDecoration.lineThrough : null,
          ),
        ),
        if (isVoided && entry.voidReason != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${l10n.voidReason}: ${entry.voidReason}'),
          ),
        const SizedBox(height: 16),
        if (!entry.type.isOwnerMovement)
          _Field(l10n.category, context.categoryName(category)),
        _Field(l10n.date, context.dayLabel(entry.occurredOn)),
        if (entry.description.isNotEmpty)
          _Field(l10n.description, entry.description),
        _Field(
          l10n.paymentMethod,
          entry.paymentMethod == null
              ? l10n.notSet
              : l10n.paymentMethodLabel(entry.paymentMethod!),
        ),
        if (entry.note != null) _Field(l10n.note, entry.note!),
        _Field(l10n.source, l10n.sourceLabel(entry.source)),
        const SizedBox(height: 24),
        Text(l10n.history, style: textTheme.titleMedium),
        for (final revision in revisions) _RevisionTile(revision),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
          ),
          Expanded(child: Text(value, style: textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

/// One history row: what changed, when, and the amount at that version.
class _RevisionTile extends StatelessWidget {
  const _RevisionTile(this.revision);

  final RevisionRow revision;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snapshot = jsonDecode(revision.snapshot) as Map<String, dynamic>;
    final amount = Money(
      // Cloud snapshots use the column name amount_minor.
      ((snapshot['amount_minor'] ?? snapshot['amountMinor']) as num).toInt(),
      Currency.fromCode(snapshot['currency'] as String),
    );
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history),
      title: Text(
        '${l10n.revisionLabel(revision.kind)} · '
        '${formatMoney(amount, locale: context.localeTag)}',
      ),
      subtitle: Text(
        '${context.dateTimeLabel(revision.changedAt)} · '
        '${l10n.versionLabel(revision.version)}',
      ),
    );
  }
}
