import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../domain/enums.dart';
import '../../finance_core/insights.dart';
import 'dashboard_screen.dart';

/// Short observations about the selected period, from `buildInsights`.
class InsightsCard extends ConsumerWidget {
  const InsightsCard(this.data, {super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // How long cash lasts is shown on the cash card.
    final insights = data.insights
        .where((i) => i is! RunwayInsight && i is! RunwayStatusInsight)
        .toList();
    if (insights.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final categories = ref.watch(categoriesByIdProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(context.l10n.insightsTitle, style: textTheme.titleMedium),
          ),
          for (final (i, insight) in insights.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 64, endIndent: 16),
            _InsightRow(
              insight: insight,
              text: _describe(context, insight, (id) =>
                  context.categoryName(categories[id])),
              onTap: _target(insight) == null
                  ? null
                  : () => _target(insight)!(context, ref),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Opens the ledger entries behind an insight, where that makes sense.
  void Function(BuildContext, WidgetRef)? _target(Insight insight) =>
      switch (insight) {
        WithdrawalInsight() => (context, ref) => openLedgerFor(context, ref,
            data: data, type: EntryType.ownerWithdrawal),
        WithdrawalOkInsight(:final withdrawn) when withdrawn.minor > 0 =>
          (context, ref) => openLedgerFor(context, ref,
              data: data, type: EntryType.ownerWithdrawal),
        RunwayStatusInsight(status: RunwayStatus.needsOpeningCash) =>
          (context, ref) => context.go('/settings'),
        CategoryIncreaseInsight(:final categoryId) => (context, ref) =>
            openLedgerFor(context, ref,
                data: data, type: EntryType.expense, categoryId: categoryId),
        TopIncomeInsight(:final categoryId) => (context, ref) =>
            openLedgerFor(context, ref,
                data: data, type: EntryType.income, categoryId: categoryId),
        _ => null,
      };
}

(String, String) _describe(
  BuildContext context,
  Insight insight,
  String Function(String?) categoryName,
) {
  final l10n = context.l10n;
  String money(Money m) => formatMoney(m, locale: context.localeTag);
  return switch (insight) {
    MarginInsight(:final percent) => (
        l10n.insightMarginTitle('$percent'),
        l10n.insightMarginBody('$percent'),
      ),
    LossInsight(:final loss) => (
        l10n.insightLossTitle,
        l10n.insightLossBody(money(loss)),
      ),
    WithdrawalInsight(:final withdrawn, :final profit) => (
        l10n.insightWithdrawTitle,
        l10n.insightWithdrawBody(money(withdrawn), money(profit)),
      ),
    RunwayInsight(:final days) => (
        l10n.insightRunwayTitle('$days'),
        insight.tone == InsightTone.warning
            ? l10n.insightRunwayLowBody
            : l10n.insightRunwayBody,
      ),
    ForecastInsight(:final profit) => (
        l10n.insightForecastTitle(
          formatMoney(profit, locale: context.localeTag, signed: true),
        ),
        l10n.insightForecastBody,
      ),
    CategoryIncreaseInsight(:final categoryId, :final percent, :final increase) => (
        l10n.insightCategoryTitle(categoryName(categoryId), '$percent'),
        l10n.insightCategoryBody(money(increase)),
      ),
    NoIncomeInsight(:final forSource) => (
        l10n.insightNoIncomeTitle,
        forSource
            ? l10n.insightNoIncomeSourceBody
            : l10n.insightNoIncomeMarginBody,
      ),
    WithdrawalOkInsight(:final withdrawn, :final profit) => withdrawn.isZero
        ? (l10n.insightNoWithdrawTitle, l10n.insightNoWithdrawBody)
        : (
            l10n.insightWithdrawOkTitle,
            l10n.insightWithdrawOkBody(money(withdrawn), money(profit)),
          ),
    RunwayStatusInsight(:final status) => switch (status) {
        RunwayStatus.needsOpeningCash => (
            l10n.insightRunwaySetupTitle,
            l10n.insightRunwaySetupBody,
          ),
        RunwayStatus.noRecentSpending => (
            l10n.insightRunwayNoSpendTitle,
            l10n.insightRunwayNoSpendBody,
          ),
        RunwayStatus.overAYear => (
            l10n.insightRunwayLongTitle,
            l10n.insightRunwayBody,
          ),
      },
    ForecastStatusInsight(:final status) => (
        l10n.insightForecastWaitTitle,
        status == ForecastStatus.tooEarly
            ? l10n.insightForecastEarlyBody
            : l10n.insightForecastDoneBody,
      ),
    NoCategoryIncreaseInsight() => (
        l10n.insightNoIncreaseTitle,
        l10n.insightNoIncreaseBody,
      ),
    TopIncomeInsight(:final categoryId, :final percent) => (
        l10n.insightTopIncomeTitle(categoryName(categoryId), '$percent'),
        insight.concentrated
            ? l10n.insightTopIncomeRiskBody
            : l10n.insightTopIncomeBody,
      ),
  };
}

IconData _icon(Insight insight) => switch (insight) {
      MarginInsight() => Icons.percent_rounded,
      LossInsight() => Icons.trending_down_rounded,
      NoIncomeInsight(:final forSource) =>
        forSource ? Icons.star_outline_rounded : Icons.percent_rounded,
      WithdrawalInsight() ||
      WithdrawalOkInsight() => Icons.person_remove_alt_1_outlined,
      RunwayInsight() ||
      RunwayStatusInsight() => Icons.hourglass_bottom_rounded,
      ForecastInsight() ||
      ForecastStatusInsight() => Icons.query_stats_rounded,
      CategoryIncreaseInsight() => Icons.north_east_rounded,
      NoCategoryIncreaseInsight() => Icons.check_rounded,
      TopIncomeInsight() => Icons.star_outline_rounded,
    };

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight, required this.text, this.onTap});

  final Insight insight;
  final (String, String) text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = switch (insight.tone) {
      InsightTone.good => MoneyColors.moneyIn(context),
      InsightTone.warning => MoneyColors.moneyOut(context),
      InsightTone.neutral => scheme.primary,
      InsightTone.muted => scheme.onSurfaceVariant,
    };
    final (title, body) = text;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(insight), size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: Icon(Icons.chevron_right,
                    size: 20, color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
