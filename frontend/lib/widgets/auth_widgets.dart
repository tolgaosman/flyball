import 'package:flutter/material.dart';
import 'package:flyball_core/flyball_core.dart';

import '../data/account/account_api.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'animations.dart';
import 'premium_button.dart';
import 'premium_card.dart';
import 'states.dart';

/// Localized text for an [AccountException.code] from the backend.
String authErrorMessage(AppLocalizations l10n, String code) {
  switch (code) {
    case AccountErrors.invalidCredentials:
      return l10n.authInvalidCredentials;
    case AccountErrors.usernameTaken:
      return l10n.authUsernameTaken;
    case AccountErrors.tooManyAttempts:
      return l10n.authTooManyAttempts;
    case AccountErrors.invalidUsername:
      return l10n.authInvalidUsername(
          AccountRules.usernameMinLength, AccountRules.usernameMaxLength);
    case AccountErrors.weakPassword:
      return l10n.authWeakPassword(AccountRules.passwordMinLength);
    case AccountErrors.invalidDisplayName:
      return l10n.authDisplayNameTooLong(AccountRules.displayNameMaxLength);
    case AccountException.network:
      return l10n.authNetworkError;
    default:
      return l10n.authUnknownError;
  }
}

/// Shared page body for the sign-in and sign-up screens: an icon, a
/// headline + subtitle, then the form, centred and scrollable so the
/// keyboard never causes an overflow.
class AuthPageBody extends StatelessWidget {
  const AuthPageBody({
    super.key,
    required this.icon,
    required this.headline,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String headline;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
                  child: Icon(icon, size: 56, color: AppColors.pitchGreen.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Text(headline, textAlign: TextAlign.center, style: AppTheme.title()),
                ),
                const SizedBox(height: AppSpacing.sm),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: Text(subtitle, textAlign: TextAlign.center, style: AppTheme.caption()),
                ),
                const SizedBox(height: AppSpacing.xxl),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A form field in the Night Pitch style (matches the XOX lobby's name
/// fields). With [obscure], shows a show/hide-password toggle.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.focusNode,
    this.obscure = false,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.validator,
    this.maxLength,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FocusNode? focusNode;
  final bool obscure;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final bool enabled;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PremiumCard(
      color: AppColors.surface,
      borderColor: AppColors.border,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        obscureText: _hidden,
        autocorrect: false,
        enableSuggestions: !widget.obscure,
        autofillHints: widget.autofillHints,
        maxLength: widget.maxLength,
        style: AppTheme.label(16, color: AppColors.white),
        cursorColor: AppColors.pitchGreen,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: '',
          labelText: widget.label,
          labelStyle: AppTheme.caption(),
          floatingLabelStyle: AppTheme.caption(color: AppColors.pitchGreen),
          errorStyle: AppTheme.caption(color: AppColors.danger),
          icon: Icon(widget.icon, color: AppColors.pitchGreen, size: 24),
          suffixIcon: widget.obscure
              ? IconButton(
                  tooltip: _hidden ? l10n.authShowPassword : l10n.authHidePassword,
                  onPressed: () => setState(() => _hidden = !_hidden),
                  icon: Icon(
                    _hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: AppColors.whiteMuted,
                    size: 20,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// A danger-tinted banner for a request-level error (wrong password, server
/// unreachable, …), as opposed to per-field validation errors.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.surface,
      borderColor: AppColors.danger,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(message, style: AppTheme.body(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

/// The primary submit button; swaps its label for a spinner while [busy].
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PremiumButton(
      onPressed: busy ? null : onPressed,
      foregroundColor: AppColors.surfaceLow,
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.pitchGreen),
            )
          : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

/// "No account yet? **Sign up**" style link between the two auth screens.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: AppTheme.caption()),
        TextButton(
          onPressed: onTap,
          child: Text(action, style: AppTheme.label(14, color: AppColors.pitchGreen)),
        ),
      ],
    );
  }
}

/// Shown instead of a form when the app has no backend to hold accounts.
class AuthUnavailableView extends StatelessWidget {
  const AuthUnavailableView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      iconColor: AppColors.danger,
      title: l10n.authUnavailableTitle,
      message: l10n.authUnavailableMessage,
    );
  }
}
