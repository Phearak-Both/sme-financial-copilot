import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Language names are shown in their own script so either is recognisable.
  static const _languageNames = {'km': 'ខ្មែរ', 'en': 'English'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(localeProvider).value ?? defaultLocale;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
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
        ],
      ),
    );
  }
}
