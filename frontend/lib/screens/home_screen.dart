import 'package:flutter/material.dart';

import '../routing/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/premium_button.dart';
import '../widgets/flyball_logo.dart';

/// The landing screen: the Flyball brand mark and the three game buttons.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
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
                      const SizedBox(height: AppSpacing.sm),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 140),
                        child: Text(
                          'FOOTBALL TRIVIA, REIMAGINED',
                          style: AppTheme.overline(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      ..._buildGameButtons(context),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildGameButtons(BuildContext context) {
    final buttons = <_GameButton>[
      _GameButton(
        label: 'FOOTBALL XOX',
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
        label: '2 TEAM 1 PLAYER',
        icon: Icons.people_alt_rounded,
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.twoTeamOnePlayer),
      ),
      _GameButton(
        label: '1 TEAM 1 COUNTRY',
        icon: Icons.public_rounded,
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.oneTeamOneCountry),
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

/// A bouncy home button with an icon and label. The primary (fully built)
/// game gets the pitch-green "lit from within" treatment; the rest stay on
/// the neutral surface so the hierarchy reads instantly.
class _GameButton extends StatelessWidget {
  const _GameButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  })  : color = primary ? AppColors.pitchGreen : AppColors.surfaceHigh,
        foregroundColor =
            primary ? AppColors.surfaceLow : AppColors.textPrimary,
        borderColor = primary ? Colors.transparent : AppColors.border;

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;
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
