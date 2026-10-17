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

/// One ledger entry in a list. Tapping opens its details.
class EntryTile extends ConsumerWidget {
  const EntryTile({super.key, required this.entry, this.showDate = false});

  final EntryRow entry;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final category = ref.watch(categoriesByIdProvider)[entry.categoryId];
    final isVoided = entry.status == EntryStatus.voided;
    final isIn = entry.type.isMoneyIn;
    final color = isVoided
        ? Theme.of(context).disabledColor
        : (isIn ? MoneyColors.moneyIn(context) : MoneyColors.moneyOut(context));

    final heading = entry.type.isOwnerMovement
        ? l10n.entryType(entry.type)
        : context.categoryName(category);
    final title = entry.description.isNotEmpty ? entry.description : heading;
    final subtitleParts = [
      if (entry.description.isNotEmpty) heading,
      if (showDate) context.dayLabel(entry.occurredOn),
      if (isVoided) l10n.voided,
    ];

    final amount = Money(
      isIn ? entry.amountMinor : -entry.amountMinor,
      Currency.fromCode(entry.currency),
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: () => context.push('/entry/${entry.id}'),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        child: Icon(entryTypeIcon(entry.type)),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isVoided
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: subtitleParts.isEmpty
          ? null
          : Text(subtitleParts.join(' · '), maxLines: 1),
      trailing: Text(
        formatMoney(amount, locale: context.localeTag, signed: true),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              decoration: isVoided ? TextDecoration.lineThrough : null,
            ),
      ),
    );
  }
}
