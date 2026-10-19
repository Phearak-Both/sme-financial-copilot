import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';
import '../../finance_core/insights.dart';

/// Cash on hand for [currency], or a prompt to set opening cash.
///
/// No balance is ever shown without an opening balance, because the ledger
/// alone can't tell how much cash the business started with.
class CashBalanceCard extends ConsumerWidget {
  const CashBalanceCard({super.key, required this.currency, this.runway});

  final Currency currency;

  /// How long the cash lasts, from the dashboard insights.
  final Insight? runway;

  /// The runway bar is full at this many days.
  static const runwayScaleDays = 90;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final balances = ref.watch(cashBalancesProvider).value;
    if (balances == null) return const SizedBox.shrink();

    final balance = balances[currency];
    if (balance == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.account_balance_wallet_outlined),
          title: Text(l10n.cashOnHand),
          subtitle: Text(l10n.cashOnHandHint),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/settings'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.cashOnHand, style: textTheme.titleMedium)),
                Text(
                  formatMoney(balance, locale: context.localeTag),
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            ..._runway(context),
            if (balance.isNegative) ...[
              const SizedBox(height: 8),
              Text(
                l10n.negativeBalanceWarning,
                style: textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _runway(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (int days, String title, String body) = switch (runway) {
      RunwayInsight(:final days) => (
          days,
          l10n.insightRunwayTitle('$days'),
          days < runwayWarningDays
              ? l10n.insightRunwayLowBody
              : l10n.insightRunwayBody,
        ),
      RunwayStatusInsight(status: RunwayStatus.overAYear) => (
          366,
          l10n.insightRunwayLongTitle,
          l10n.insightRunwayBody,
        ),
      _ => (-1, '', ''),
    };
    if (days < 0) return const [];
    final low = days < runwayWarningDays;
    final color = low ? MoneyColors.moneyOut(context) : MoneyColors.moneyIn(context);
    final shown = days > runwayScaleDays ? runwayScaleDays : days;

    return [
      const SizedBox(height: 14),
      Row(
        children: [
          Icon(
            low ? Icons.warning_amber_rounded : Icons.hourglass_bottom_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: shown / runwayScaleDays,
          minHeight: 8,
          color: color,
          backgroundColor: color.withValues(alpha: 0.14),
          semanticsLabel: title,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '${l10n.runwayScale('$shown${days > runwayScaleDays ? '+' : ''}', '$runwayScaleDays')} · $body',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    ];
  }
}
