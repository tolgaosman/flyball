import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/account/account_api.dart';
import '../data/account/session_controller.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show sessionController;
import '../routing/app_routes.dart';
import '../widgets/auth_widgets.dart';

/// Sign in to an existing Flyball account. On success, shows a welcome
/// snackbar and pops back to wherever it was opened from.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.session});

  /// Defaults to the app-wide [sessionController]; tests pass their own.
  final SessionController? session;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _busy = false;

  /// An [AccountException.code] from the last attempt, shown as a banner.
  String? _errorCode;

  SessionController get _session => widget.session ?? sessionController;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
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
      await _session.login(username: _username.text.trim(), password: _password.text);
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
      appBar: AppBar(title: Text(l10n.authSignInTitle)),
      body: !_session.isAvailable
          ? const AuthUnavailableView()
          : Form(
              key: _formKey,
              child: AutofillGroup(
                child: AuthPageBody(
                  icon: Icons.sports_soccer_rounded,
                  headline: l10n.authSignInHeadline,
                  subtitle: l10n.authSignInSubtitle,
                  children: [
                    AuthTextField(
                      controller: _username,
                      label: l10n.authUsernameLabel,
                      icon: Icons.person_rounded,
                      enabled: !_busy,
                      autofillHints: const [AutofillHints.username],
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l10n.authUsernameRequired : null,
                    ),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _password,
                      focusNode: _passwordFocus,
                      label: l10n.authPasswordLabel,
                      icon: Icons.lock_rounded,
                      obscure: true,
                      enabled: !_busy,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? l10n.authPasswordRequired : null,
                    ),
                    if (_errorCode != null) ...[
                      const SizedBox(height: 16),
                      AuthErrorBanner(message: authErrorMessage(l10n, _errorCode!)),
                    ],
                    const SizedBox(height: 24),
                    AuthSubmitButton(
                      label: l10n.authSignInButton,
                      busy: _busy,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 8),
                    AuthSwitchLink(
                      prompt: l10n.authNoAccount,
                      action: l10n.authGoToSignUp,
                      onTap: _busy
                          ? null
                          : () => Navigator.of(context).pushReplacementNamed(AppRoutes.signup),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
