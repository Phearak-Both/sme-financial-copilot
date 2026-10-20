import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../cloud/auth.dart';
import '../../l10n/app_localizations.dart';

/// Log in or sign up with email and password.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _signingUp = false;

  /// Phone number or email as the login.
  bool _usePhone = true;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _switchMode() => setState(() {
        _signingUp = !_signingUp;
        _error = null;
        _form.currentState?.reset();
      });

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    final l10n = context.l10n;
    final phone = _usePhone ? normalizePhone(_phone.text) : null;
    final email = phone != null ? phoneLoginEmail(phone) : _email.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_signingUp) {
        final result = await signUp(
          _name.text.trim(),
          email,
          _password.text,
          phone: phone,
        );
        if (result == SignUpResult.confirmEmail && phone != null) {
          // Phone accounts can't receive a confirmation email.
          throw const AuthFailure(AuthProblem.other, 'confirm email is on');
        }
        if (result == SignUpResult.confirmEmail && mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.mark_email_unread_outlined),
              title: Text(l10n.checkEmailTitle),
              content: Text(l10n.checkEmailBody(email)),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.ok),
                ),
              ],
            ),
          );
          if (mounted) {
            setState(() {
              _signingUp = false;
              _password.clear();
              _confirm.clear();
            });
          }
        }
      } else {
        await signIn(email, _password.text);
      }
      // A successful sign-in moves the router on to the app.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = _message(l10n, e.problem));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(AppLocalizations l10n, AuthProblem problem) =>
      switch (problem) {
        AuthProblem.wrongCredentials => _usePhone
            ? l10n.authWrongCredentialsPhone
            : l10n.authWrongCredentials,
        AuthProblem.emailNotConfirmed => l10n.authEmailNotConfirmed,
        AuthProblem.userExists =>
          _usePhone ? l10n.authUserExistsPhone : l10n.authUserExists,
        AuthProblem.emailRejected => l10n.authEmailRejected,
        AuthProblem.weakPassword => l10n.authWeakPassword,
        AuthProblem.rateLimited => l10n.authRateLimited,
        AuthProblem.network => l10n.authNetwork,
        AuthProblem.other => l10n.authOther,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    final passwordToggle = IconButton(
      tooltip: _showPassword ? l10n.hidePassword : l10n.showPassword,
      icon: Icon(
        _showPassword
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
      ),
      onPressed: () => setState(() => _showPassword = !_showPassword),
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _form,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: dark ? Brand.nightRaised : Brand.forest,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 36,
                                color: dark ? Brand.mint : Brand.ivory,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.appTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _signingUp
                                ? l10n.authSignUpSubtitle
                                : l10n.authLogInSubtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: true,
                                icon: const Icon(Icons.phone_outlined),
                                label: Text(l10n.phone),
                              ),
                              ButtonSegment(
                                value: false,
                                icon: const Icon(Icons.mail_outline),
                                label: Text(l10n.email),
                              ),
                            ],
                            selected: {_usePhone},
                            onSelectionChanged: _busy
                                ? null
                                : (s) => setState(() {
                                      _usePhone = s.first;
                                      _error = null;
                                    }),
                          ),
                          const SizedBox(height: 20),
                          if (_signingUp) ...[
                            TextFormField(
                              controller: _name,
                              enabled: !_busy,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.name],
                              decoration: InputDecoration(
                                labelText: l10n.fullName,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? l10n.nameRequired
                                  : null,
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (_usePhone)
                            TextFormField(
                              key: const ValueKey('phone'),
                              controller: _phone,
                              enabled: !_busy,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.telephoneNumber],
                              decoration: InputDecoration(
                                labelText: l10n.phoneNumber,
                                hintText: '012 345 678',
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                              validator: (v) => normalizePhone(v ?? '') == null
                                  ? l10n.phoneInvalid
                                  : null,
                            )
                          else
                            TextFormField(
                              key: const ValueKey('email'),
                              controller: _email,
                              enabled: !_busy,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              autofillHints: const [AutofillHints.email],
                              decoration: InputDecoration(
                                labelText: l10n.email,
                                prefixIcon: const Icon(Icons.mail_outline),
                              ),
                              validator: (v) =>
                                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                      .hasMatch((v ?? '').trim())
                                  ? null
                                  : l10n.emailInvalid,
                            ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _password,
                            enabled: !_busy,
                            obscureText: !_showPassword,
                            textInputAction: _signingUp
                                ? TextInputAction.next
                                : TextInputAction.done,
                            autofillHints: [
                              _signingUp
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: passwordToggle,
                            ),
                            validator: (v) => (v ?? '').length < 6
                                ? l10n.passwordTooShort
                                : null,
                            onFieldSubmitted: (_) {
                              if (!_signingUp) _submit();
                            },
                          ),
                          if (_signingUp) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirm,
                              enabled: !_busy,
                              obscureText: !_showPassword,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: l10n.confirmPassword,
                                prefixIcon: const Icon(Icons.lock_outline),
                              ),
                              validator: (v) => v != _password.text
                                  ? l10n.passwordMismatch
                                  : null,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: scheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 20, color: scheme.onErrorContainer),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: scheme.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2.5),
                                  )
                                : Text(_signingUp ? l10n.signUp : l10n.logIn),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _signingUp ? l10n.haveAccount : l10n.noAccount,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              TextButton(
                                onPressed: _busy ? null : _switchMode,
                                child: Text(_signingUp ? l10n.logIn : l10n.signUp),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 8,
              right: 8,
              child: Row(children: [_ThemeButton(), _LanguageButton()]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Switches between light and dark before signing in.
class _ThemeButton extends ConsumerWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    return IconButton(
      tooltip: dark ? l10n.themeLight : l10n.themeDark,
      // Icon of the mode you switch to.
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ref
          .read(settingsStoreProvider)
          .set(
            themeModeSettingKey,
            (dark ? ThemeMode.light : ThemeMode.dark).name,
          ),
    );
  }
}

/// Switches between Khmer and English before signing in.
class _LanguageButton extends ConsumerWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Each language is named in its own script so either is recognisable.
    final other = context.isKhmer ? 'en' : 'km';
    return TextButton.icon(
      onPressed: () => ref
          .read(settingsStoreProvider)
          .set(localeSettingKey, other),
      // An icon, not a flag: emoji would make the web app fetch a large
      // emoji font before the sign-in page settles.
      icon: const Icon(Icons.translate, size: 18),
      label: Text(other == 'en' ? 'English' : 'ខ្មែរ'),
    );
  }
}
