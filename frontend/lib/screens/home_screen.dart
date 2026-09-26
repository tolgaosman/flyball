import 'package:flutter/material.dart';
import 'package:flyball_core/flyball_core.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../main.dart' show localeController, sessionController;
import '../routing/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/dynamic_art.dart';
import '../widgets/premium_button.dart';
import '../widgets/flyball_logo.dart';

/// The landing screen: the Flyball brand mark and the game buttons.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          FadeSlideIn(
                            offset: const Offset(0, 0.18),
                            child: _GlowingLogo(),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Wordmark.
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 80),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'FLY',
                                    style: AppTheme.displayXL(color: AppColors.white),
                                  ),
                                  TextSpan(
                                    text: 'BALL',
                                    style: AppTheme.displayXL(
                                        color: AppColors.pitchGreen),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xxl),
                          ..._buildGameButtons(context, l10n),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (sessionController.isAvailable)
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.lg,
                child: FadeSlideIn(
                  child: _AccountButton(l10n: l10n),
                ),
              ),
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.lg,
              child: FadeSlideIn(
                child: _LanguageToggle(l10n: l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGameButtons(BuildContext context, AppLocalizations l10n) {
    final buttons = <_GameButton>[
      _GameButton(
        label: l10n.playFootballXox,
        icon: Icons.grid_3x3_rounded,
        primary: true,
        onPressed: () async {
          final result = await Navigator.of(context)
              .pushNamed(AppRoutes.footballXoxLobby);
          if (!context.mounted || result == null) return;
          Navigator.of(context).pushNamed(
            AppRoutes.footballXox,
            arguments: result,
          );
        },
      ),
      _GameButton(
        label: l10n.playTwoTeamOnePlayer,
        icon: Icons.people_alt_rounded,
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.twoTeamOnePlayer),
      ),
      _GameButton(
        label: l10n.playOneTeamOneCountry,
        icon: Icons.public_rounded,
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.oneTeamOneCountry),
      ),
      _GameButton(
        label: l10n.playFootballdle,
        icon: Icons.password_rounded,
        badge: l10n.comingSoonBadge,
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.footballdle),
      ),
    ];

    final widgets = <Widget>[];
    for (var i = 0; i < buttons.length; i++) {
      if (i > 0) widgets.add(const SizedBox(height: AppSpacing.md));
      widgets.add(
        FadeSlideIn(
          delay: Duration(milliseconds: 200 + i * 70),
          child: buttons[i],
        ),
      );
    }
    return widgets;
  }
}

/// A small pill button in the top-right corner cycling between English and
/// Turkish, persisted via [LocaleController].
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final current = Localizations.localeOf(context).languageCode;
    final next = current == 'tr' ? const Locale('en') : const Locale('tr');
    return Tooltip(
      message: l10n.languageToggleTooltip,
      child: SpringScale(
        onTap: () => localeController.setLocale(next),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            current.toUpperCase(),
            style: AppTheme.overline(color: AppColors.pitchGreen),
          ),
        ),
      ),
    );
  }
}

/// Top-left pill mirroring [_LanguageToggle]: "SIGN IN" when signed out
/// (opens the login screen), the account's name when signed in (opens a
/// small sheet with sign-out). Only shown when accounts are available
/// (backend mode).
class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccountUser?>(
      valueListenable: sessionController,
      builder: (context, user, _) {
        return SpringScale(
          onTap: user == null
              ? () => Navigator.of(context).pushNamed(AppRoutes.login)
              : () => _showAccountSheet(context, user),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 170),
            padding: EdgeInsets.fromLTRB(user == null ? 12 : 6, 6, 12, 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user == null)
                  const Icon(Icons.person_rounded, size: 16, color: AppColors.pitchGreen)
                else
                  Monogram(text: user.displayName, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    user?.displayName ?? l10n.authAccountButton,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: user == null
                        ? AppTheme.overline(color: AppColors.pitchGreen)
                        : AppTheme.label(13, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccountSheet(BuildContext context, AccountUser user) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Monogram(text: user.displayName, size: 56),
              const SizedBox(height: AppSpacing.md),
              Text(user.displayName, style: AppTheme.title(), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.authSignedInAs(user.username), style: AppTheme.caption()),
              const SizedBox(height: AppSpacing.xl),
              PremiumButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  sessionController.logout();
                },
                color: AppColors.surface,
                foregroundColor: AppColors.danger,
                borderColor: AppColors.danger,
                child: Text(l10n.authSignOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bouncy home button with an icon and label. The primary (fully built)
/// game gets the pitch-green "lit from within" treatment; the rest stay on
/// the neutral surface so the hierarchy reads instantly. An optional [badge]
/// (e.g. "SOON") renders as a small chip after the label.
class _GameButton extends StatelessWidget {
  const _GameButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.badge,
  })  : color = primary ? AppColors.pitchGreen : AppColors.surfaceHigh,
        foregroundColor =
            primary ? AppColors.surfaceLow : AppColors.textPrimary,
        borderColor = primary ? Colors.transparent : AppColors.border;

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;
  final String? badge;
  final Color color;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return PremiumButton(
      onPressed: onPressed,
      color: color,
      foregroundColor: foregroundColor,
      borderColor: borderColor,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: foregroundColor),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.heading(24, color: foregroundColor),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: foregroundColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                badge!,
                style: AppTheme.overline(color: foregroundColor).copyWith(fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The Flyball wordmark image, floating over a soft dual-colour ambient
/// glow (pitch green + gold) — the home screen's signature entrance.
class _GlowingLogo extends StatelessWidget {
  const _GlowingLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.pitchGreen.withValues(alpha: 0.28),
                  AppColors.gold.withValues(alpha: 0.10),
                  AppColors.pitchGreen.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          const FlyballLogo(size: 112),
        ],
      ),
    );
  }
}
