import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Preferences for this device, such as the language. They stay on the
/// device (not in the account) so they apply before anyone signs in.
class SettingsStore {
  SettingsStore([Future<SharedPreferences>? prefs])
      : _prefs = prefs ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefs;
  final _changed = StreamController<String>.broadcast();

  static const _prefix = 'setting.';

  Stream<String?> watch(String key) async* {
    yield (await _prefs).getString('$_prefix$key');
    await for (final _ in _changed.stream.where((k) => k == key)) {
      yield (await _prefs).getString('$_prefix$key');
    }
  }

  Future<String?> get(String key) async =>
      (await _prefs).getString('$_prefix$key');

  Future<void> set(String key, String value) async {
    await (await _prefs).setString('$_prefix$key', value);
    _changed.add(key);
  }

  void dispose() => _changed.close();
}
