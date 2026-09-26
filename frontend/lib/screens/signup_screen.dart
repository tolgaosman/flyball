import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flyball_core/flyball_core.dart';

import '../data/account/account_api.dart';
import '../data/account/session_controller.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show sessionController;
import '../routing/app_routes.dart';
import '../widgets/auth_widgets.dart';

/// Create a Flyball account (username + password, optional display name).
/// Validates with the same [AccountRules] the backend enforces, then signs
/// straight in on success.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.session});

  /// Defaults to the app-wide [sessionController]; tests pass their own.
  final SessionController? session;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _displayNameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _busy = false;

  /// An [AccountException.code] from the last attempt, shown as a banner.
  String? _errorCode;

  SessionController get _session => widget.session ?? sessionController;

  @override
  void dispose() {
    for (final c in [_username, _displayName, _password, _confirm]) {
      c.dispose();
    }
    for (final f in [_displayNameFocus, _passwordFocus, _confirmFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _errorCode = null;
    });
    try {
      await _session.register(
        username: _username.text.trim(),
        password: _password.text,
        displayName: _displayName.text.trim(),
      );
      if (!mounted) return;
      TextInput.finishAutofillContext();
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authWelcome(_session.value!.displayName))),
      );
      Navigator.of(context).pop(true);
    } on AccountException catch (e) {
      if (mounted) setState(() => _errorCode = e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authSignUpTitle)),
      body: !_session.isAvailable
          ? const AuthUnavailableView()
          : Form(
              key: _formKey,
              child: AutofillGroup(
                child: AuthPageBody(
                  icon: Icons.emoji_events_rounded,
                  headline: l10n.authSignUpHeadline,
                  subtitle: l10n.authSignUpSubtitle,
                  children: [
                    AuthTextField(
                      controller: _username,
                      label: l10n.authUsernameLabel,
                      icon: Icons.alternate_email_rounded,
                      enabled: !_busy,
                      maxLength: AccountRules.usernameMaxLength,
                      autofillHints: const [AutofillHints.newUsername],
                      onSubmitted: (_) => _displayNameFocus.requestFocus(),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return l10n.authUsernameRequired;
                        return AccountRules.validateUsername(value) == null
                            ? null
                            : authErrorMessage(l10n, AccountErrors.invalidUsername);
                      },
                    ),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _displayName,
                      focusNode: _displayNameFocus,
                      label: l10n.authDisplayNameLabel,
                      icon: Icons.badge_rounded,
                      enabled: !_busy,
                      maxLength: AccountRules.displayNameMaxLength,
                      autofillHints: const [AutofillHints.nickname],
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _password,
                      focusNode: _passwordFocus,
                      label: l10n.authPasswordLabel,
                      icon: Icons.lock_rounded,
                      obscure: true,
                      enabled: !_busy,
                      maxLength: AccountRules.passwordMaxLength,
                      autofillHints: const [AutofillHints.newPassword],
                      onSubmitted: (_) => _confirmFocus.requestFocus(),
                      validator: (v) {
                        final value = v ?? '';
                        if (value.isEmpty) return l10n.authPasswordRequired;
                        return AccountRules.validatePassword(value) == null
                            ? null
                            : authErrorMessage(l10n, AccountErrors.weakPassword);
                      },
                    ),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _confirm,
                      focusNode: _confirmFocus,
                      label: l10n.authConfirmPasswordLabel,
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                      enabled: !_busy,
                      maxLength: AccountRules.passwordMaxLength,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) =>
                          v == _password.text ? null : l10n.authPasswordsDontMatch,
                    ),
                    if (_errorCode != null) ...[
                      const SizedBox(height: 16),
                      AuthErrorBanner(message: authErrorMessage(l10n, _errorCode!)),
                    ],
                    const SizedBox(height: 24),
                    AuthSubmitButton(
                      label: l10n.authSignUpButton,
                      busy: _busy,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 8),
                    AuthSwitchLink(
                      prompt: l10n.authHaveAccount,
                      action: l10n.authGoToSignIn,
                      onTap: _busy
                          ? null
                          : () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
