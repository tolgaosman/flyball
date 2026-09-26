import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_card.dart';

/// Shared "Coming Soon" screen used by not-yet-built games.
///
/// More than a placeholder: a glowing hero icon, a "SOON" chip, a preview
/// word (Wordle-style tiles) and a short feature list, so the page still
/// feels like part of the app instead of a dead end.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.tagline,
    required this.previewWord,
    required this.features,
  });

  final String title;
  final IconData icon;
  final String tagline;
  final String previewWord;
  final List<(IconData, String)> features;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title.toUpperCase())),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeSlideIn(child: _GlowingIcon(icon: icon)),
                AppSpacing.gapLg,
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: _SoonChip(label: l10n.comingSoonBadge),
                ),
                AppSpacing.gapMd,
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppTheme.display(),
                  ),
                ),
                AppSpacing.gapMd,
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: Text(
                    tagline,
                    textAlign: TextAlign.center,
                    style: AppTheme.body(color: AppColors.textMuted),
                  ),
                ),
                AppSpacing.gapXxl,
                _PreviewRow(word: previewWord),
                AppSpacing.gapXxl,
                FadeSlideIn(
                  delay: const Duration(milliseconds: 260),
                  child: PremiumCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < features.length; i++) ...[
                          if (i > 0)
                            const Divider(height: AppSpacing.xl, color: AppColors.border),
                          _FeatureRow(icon: features[i].$1, label: features[i].$2),
                        ],
                      ],
                    ),
                  ),
                ),
                AppSpacing.gapXxl,
                FadeSlideIn(
                  delay: const Duration(milliseconds: 320),
                  child: PremiumButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    color: AppColors.surfaceHigh,
                    foregroundColor: AppColors.textPrimary,
                    borderColor: AppColors.border,
                    expand: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    child: Text(l10n.comingSoonBack),
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

/// A gently "breathing" icon inside a two-colour glow, echoing the home
/// screen's [FlyballLogo] treatment. Uses a single [AnimationController] with
/// `repeat(reverse: true)` — never chained `.then()` scale effects, which
/// compose multiplicatively and leave the icon permanently oversized.
class _GlowingIcon extends StatefulWidget {
  const _GlowingIcon({required this.icon});

  final IconData icon;

  @override
  State<_GlowingIcon> createState() => _GlowingIconState();
}

class _GlowingIconState extends State<_GlowingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        width: 128,
        height: 128,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.pitchGreen.withValues(alpha: 0.26),
                    AppColors.gold.withValues(alpha: 0.10),
                    AppColors.pitchGreen.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Icon(widget.icon, size: 56, color: AppColors.pitchGreen),
          ],
        ),
      ),
    );
  }
}

class _SoonChip extends StatelessWidget {
  const _SoonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: AppTheme.overline(color: AppColors.gold)),
    );
  }
}

/// A Wordle-style row of letter tiles previewing what a Footballdle guess
/// will look like, cycling green/gold/muted so it reads as a teaser rather
/// than a real (solved) answer.
class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    final letters = word.toUpperCase().split('');
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < letters.length; i++)
          FadeSlideIn(
            delay: Duration(milliseconds: 180 + i * 60),
            offset: const Offset(0, 0.3),
            child: _LetterTile(letter: letters[i], colorIndex: i % 3),
          ),
      ],
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({required this.letter, required this.colorIndex});

  final String letter;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final color = switch (colorIndex) {
      0 => AppColors.pitchGreen,
      1 => AppColors.gold,
      _ => AppColors.surfaceHigh,
    };
    final foreground =
        colorIndex == 2 ? AppColors.textPrimary : AppColors.surfaceLow;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: colorIndex == 2
            ? Border.all(color: AppColors.border)
            : null,
      ),
      child: Text(letter, style: AppTheme.heading(20, color: foreground)),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.pitchGreen),
          AppSpacing.gapMd,
          Expanded(
            child: Text(label, style: AppTheme.body()),
          ),
        ],
      ),
    );
  }
}
