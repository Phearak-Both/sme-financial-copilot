import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_financial_copilot/app/providers.dart';
import 'package:sme_financial_copilot/data/settings_store.dart';

void main() {
  late ProviderContainer container;

  Future<ThemeMode> modeFor(Map<String, Object> saved) async {
    SharedPreferences.setMockInitialValues(saved);
    container = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(SettingsStore())],
    );
    addTearDown(container.dispose);
    // Riverpod pauses providers nobody listens to.
    container.listen(themeModeProvider, (_, _) {});
    return container.read(themeModeProvider.future);
  }

  test('starts light', () async {
    expect(await modeFor({}), ThemeMode.light);
  });

  test('keeps a saved dark choice', () async {
    expect(await modeFor({'setting.themeMode': 'dark'}), ThemeMode.dark);
  });

  test('a saved "system" choice from an earlier version becomes light',
      () async {
    expect(await modeFor({'setting.themeMode': 'system'}), ThemeMode.light);
  });

  test('switching updates the theme', () async {
    await modeFor({});
    final seen = <ThemeMode>[];
    container.listen(
      themeModeProvider,
      (_, next) => next.whenData(seen.add),
      fireImmediately: true,
    );
    await container.read(settingsStoreProvider).set(themeModeSettingKey, 'dark');
    await pumpEventQueue();
    expect(seen.last, ThemeMode.dark);
  });
}
