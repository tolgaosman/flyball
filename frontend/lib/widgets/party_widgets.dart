import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'dynamic_art.dart';
import 'premium_button.dart';
import 'premium_card.dart';

/// A single slot box for a party game: a club logo or country flag above its
/// name. While [spinning], art fetching is skipped entirely (see
/// [ClubLogo]/[CountryFlag] `enabled`) — a spin flashes a new name many times
/// a second, and none of them are worth a network request for.
class SlotCard extends StatelessWidget {
  const SlotCard({
    super.key,
    required this.name,
    required this.spinning,
    required this.isCountry,
  });

  final String name;
  final bool spinning;
  final bool isCountry;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: spinning ? AppColors.pitchGreen : AppColors.border,
      soft: !spinning,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 84,
            child: Center(
              child: isCountry
                  ? CountryFlag(countryName: name, size: 72, enabled: !spinning)
                  : ClubLogo(clubName: name, size: 72, enabled: !spinning),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.headline(),
          ),
        ],
      ),
    );
  }
}

/// A scoreboard column for one player: editable name, score, and +/- buttons.
class ScorePanel extends StatelessWidget {
  const ScorePanel({
    super.key,
    required this.name,
    required this.score,
    required this.onEditName,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String name;
  final int score;
  final VoidCallback onEditName;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: AppColors.border,
      soft: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 44,
            child: GestureDetector(
              onTap: onEditName,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.caption(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.edit, size: 14, color: AppColors.whiteMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('$score', style: AppTheme.heading(44, color: AppColors.pitchGreen)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  onPressed: onDecrement,
                  color: AppColors.surfaceLow,
                  foregroundColor: AppColors.white,
                  borderColor: AppColors.border,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: const Text('−'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PremiumButton(
                  onPressed: onIncrement,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: const Text('+'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Prompts for a new player name. Returns the trimmed name, or `null` if
/// cancelled/empty. Manages its own [TextEditingController] lifetime (fixes a
/// leak in the previous inline implementation, which never disposed one).
Future<String?> showEditNameDialog(BuildContext context, {required String initial}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _EditNameDialog(initial: initial),
  );
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initial});
  final String initial;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    Navigator.of(context).pop(trimmed.isEmpty ? null : trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: const BorderSide(color: AppColors.pitchGreen, width: AppTheme.borderWidth),
      ),
      title: Text(l10n.partyEditNameTitle, style: AppTheme.title()),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 24,
        style: AppTheme.label(16),
        cursorColor: AppColors.pitchGreen,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.whiteMuted)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.pitchGreen, width: 2)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel, style: AppTheme.label(14, color: AppColors.whiteMuted)),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(l10n.save, style: AppTheme.label(14, color: AppColors.pitchGreen)),
        ),
      ],
    );
  }
}
