import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'labels.dart';
import 'providers.dart';

/// Shown when records can't be loaded from the cloud, with a way to retry.
///
/// Riverpod keeps retrying a failed provider in the background and reports
/// it as loading meanwhile, so screens check [AsyncValue.hasError] first
/// rather than relying on `when`.
class LoadError extends ConsumerWidget {
  const LoadError({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(l10n.loadFailed, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              // A fresh repository loads everything again.
              onPressed: () => ref.invalidate(ledgerRepositoryProvider),
              child: Text(l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
