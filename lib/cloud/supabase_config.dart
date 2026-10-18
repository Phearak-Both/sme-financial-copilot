import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase project, set at build time in `env/dev.json`. The publishable
/// key is safe to ship in the app; data is protected by Row-Level Security.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

bool get supabaseConfigured =>
    supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

/// True once [initSupabase] succeeded. Sign-in is only required then.
bool get supabaseReady => _ready;
bool _ready = false;

/// Connects to Supabase when configured. The app stays fully usable offline
/// and without it, so a failure here is logged, not fatal.
Future<void> initSupabase() async {
  if (!supabaseConfigured) return;
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
    _ready = true;
    debugPrint('[cloud] Supabase ready');
  } catch (e) {
    debugPrint('[cloud] Supabase init failed: $e');
  }
}
