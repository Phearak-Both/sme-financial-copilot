import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../core/money/currency.dart';
import '../../core/money/money_format.dart';

/// Cash on hand for [currency], or a prompt to set opening cash.
///
/// No balance is ever shown without an opening balance, because the ledger
/// alone can't tell how much cash the business started with.
class CashBalanceCard extends ConsumerWidget {
  const CashBalanceCard({super.key, required this.currency});

  final Currency currency;

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
}
