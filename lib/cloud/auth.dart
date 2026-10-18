import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

GoTrueClient get _auth => Supabase.instance.client.auth;

/// The signed-in user, or null. Always null when Supabase isn't set up.
final currentUserProvider = StreamProvider<User?>((ref) async* {
  if (!supabaseReady) {
    yield null;
    return;
  }
  yield _auth.currentUser;
  yield* _auth.onAuthStateChange.map((s) => s.session?.user);
});

/// Whether the app should ask the user to sign in.
bool get signInRequired => supabaseReady && _auth.currentSession == null;

/// Tells the router to re-check [signInRequired] when the user signs in or
/// out.
class AuthRefresh extends ChangeNotifier {
  AuthRefresh() {
    if (supabaseReady) {
      _sub = _auth.onAuthStateChange.listen((_) => notifyListeners());
    }
  }

  StreamSubscription<AuthState>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Why signing in or up failed, for a message the user can act on.
enum AuthProblem {
  wrongCredentials,
  emailNotConfirmed,
  userExists,
  emailRejected,
  weakPassword,
  rateLimited,
  network,
  other,
}

/// Result of [signUp]: signed in straight away, or a confirmation email was
/// sent first.
enum SignUpResult { signedIn, confirmEmail }

class AuthFailure implements Exception {
  const AuthFailure(this.problem, [this.detail]);
  final AuthProblem problem;
  final String? detail;

  @override
  String toString() => 'AuthFailure($problem, $detail)';
}

// ------------------------------------------------------------ phone numbers
//
// Phone accounts sign in with a password, without SMS codes, because SMS
// needs a paid provider. Supabase's email sign-in is used underneath: each
// phone number maps to a fixed address on example.com, a domain reserved so
// it never receives mail. Users only ever see their phone number.

/// Country code assumed for numbers written the local way, e.g. 012 345 678.
const defaultCountryCode = '855';

/// The number as international digits, e.g. `85512345678`, or null if it
/// doesn't look like a phone number. Accepts `012 345 678`, `12345678`,
/// `+855 12 345 678` and `855-12-345-678`.
String? normalizePhone(String input) {
  final trimmed = input.trim();
  final digits = trimmed.replaceAll(RegExp(r'[\s\-().]'), '');
  if (!RegExp(r'^\+?\d+$').hasMatch(digits)) return null;
  final String international;
  if (digits.startsWith('+')) {
    international = digits.substring(1);
  } else if (digits.startsWith('00')) {
    international = digits.substring(2);
  } else if (digits.startsWith(defaultCountryCode) && digits.length >= 11) {
    international = digits;
  } else {
    final national = digits.startsWith('0') ? digits.substring(1) : digits;
    if (national.length < 8 || national.length > 9) return null;
    international = '$defaultCountryCode$national';
  }
  if (international.startsWith('${defaultCountryCode}0')) {
    // +855 012 ... : drop the local trunk 0.
    return normalizePhone('+$defaultCountryCode${international.substring(4)}');
  }
  if (international.length < 8 || international.length > 15) return null;
  return international;
}

/// The hidden sign-in address for a normalized phone number.
String phoneLoginEmail(String phone) => 'phone-$phone@example.com';

/// `+855 12 345 678` for display.
String formatPhone(String phone) {
  if (phone.startsWith(defaultCountryCode)) {
    // 12 345 678 or 97 123 4567.
    final n = phone.substring(defaultCountryCode.length);
    return '+$defaultCountryCode ${n.substring(0, 2)} ${n.substring(2, 5)} '
        '${n.substring(5)}';
  }
  return '+$phone';
}

// ---------------------------------------------------------------- sign in/up

Future<void> signIn(String email, String password) => _guard(
      () => _auth.signInWithPassword(email: email, password: password),
    );

/// [phone] is set for phone accounts and kept in the user's profile.
Future<SignUpResult> signUp(
  String name,
  String email,
  String password, {
  String? phone,
}) async {
  final response = await _guard(
    () => _auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name, 'phone': ?phone},
    ),
  );
  // With email confirmation on, Supabase returns no session. It also returns
  // a user with no identities for an address that is already registered.
  if (response.user?.identities?.isEmpty ?? false) {
    throw const AuthFailure(AuthProblem.userExists);
  }
  return response.session == null
      ? SignUpResult.confirmEmail
      : SignUpResult.signedIn;
}

Future<void> signOut() => _auth.signOut();

Future<T> _guard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on AuthException catch (e) {
    debugPrint('[cloud] auth failed: ${e.code} ${e.message}');
    throw AuthFailure(
      switch (e.code) {
        'invalid_credentials' => AuthProblem.wrongCredentials,
        'email_not_confirmed' => AuthProblem.emailNotConfirmed,
        'user_already_exists' || 'email_exists' => AuthProblem.userExists,
        'email_address_invalid' ||
        'email_address_not_authorized' => AuthProblem.emailRejected,
        'weak_password' => AuthProblem.weakPassword,
        'over_email_send_rate_limit' ||
        'over_request_rate_limit' => AuthProblem.rateLimited,
        _ when e is AuthRetryableFetchException => AuthProblem.network,
        _ => AuthProblem.other,
      },
      e.message,
    );
  } catch (e) {
    debugPrint('[cloud] auth failed: $e');
    throw AuthFailure(AuthProblem.network, '$e');
  }
}
