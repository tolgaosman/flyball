import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';
import '../widgets/animations.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_card.dart';

/// Pre-game lobby for Football XOX: both players enter their names, and
/// X / O marks are assigned randomly. Returns a [XoxLobbyResult] to the
/// calling route so the game screen knows who is who.
class XoxLobbyScreen extends StatefulWidget {
  const XoxLobbyScreen({super.key});

  @override
  State<XoxLobbyScreen> createState() => _XoxLobbyScreenState();
}

/// The result passed back from the lobby to the game screen.
class XoxLobbyResult {
  const XoxLobbyResult({
    required this.playerXName,
    required this.playerOName,
  });

  /// Name of the player who will play as X.
  final String playerXName;

  /// Name of the player who will play as O.
  final String playerOName;
}

class _XoxLobbyScreenState extends State<XoxLobbyScreen>
    with SingleTickerProviderStateMixin {
  final _player1Controller = TextEditingController();
  final _player2Controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _player1Focus = FocusNode();
  final _player2Focus = FocusNode();

  /// True once the user taps START; triggers the coin-flip animation before
  /// navigating to the game.
  bool _flipping = false;

  /// Resolved after the coin flip.
  XoxLobbyResult? _result;

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    _player1Focus.dispose();
    _player2Focus.dispose();
    super.dispose();
  }

  void _onStart() {
    if (!_formKey.currentState!.validate()) return;
    _player1Focus.unfocus();
    _player2Focus.unfocus();

    final name1 = _player1Controller.text.trim();
    final name2 = _player2Controller.text.trim();

    // Coin flip: randomly decide who gets X (goes first).
    final firstIsX = Random().nextBool();
    final result = XoxLobbyResult(
      playerXName: firstIsX ? name1 : name2,
      playerOName: firstIsX ? name2 : name1,
    );

    setState(() {
      _flipping = true;
      _result = result;
    });

    // Show the assignment for a moment, then navigate.
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.lobbyTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            child: _flipping ? _buildFlipResult(l10n, context) : _buildForm(l10n),
          ),
        ),
      ),
    );
  }

  // ---- Name entry form -----------------------------------------------------

  Widget _buildForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeSlideIn(
            child: Icon(
              Icons.grid_3x3_rounded,
              size: 64,
              color: AppColors.pitchGreen.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Text(
              l10n.lobbyRandomAssignHint,
              style: AppTheme.caption(),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Player 1
          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: _NameField(
              controller: _player1Controller,
              focusNode: _player1Focus,
              label: l10n.lobbyPlayerXLabel,
              hint: l10n.lobbyNameHint,
              icon: Icons.person_rounded,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_player2Focus),
              validator: (value) => _validateName(l10n, value),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Player 2
          FadeSlideIn(
            delay: const Duration(milliseconds: 260),
            child: _NameField(
              controller: _player2Controller,
              focusNode: _player2Focus,
              label: l10n.lobbyPlayerOLabel,
              hint: l10n.lobbyNameHint,
              icon: Icons.person_outline_rounded,
              // Submitting player 2's name should start the match, not chase
              // a "next" field that doesn't exist.
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onStart(),
              validator: (value) {
                final basic = _validateName(l10n, value);
                if (basic != null) return basic;
                if (value!.trim().toLowerCase() ==
                    _player1Controller.text.trim().toLowerCase()) {
                  return l10n.lobbyNamesMustDiffer;
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Start button
          FadeSlideIn(
            delay: const Duration(milliseconds: 340),
            child: PremiumButton(
              onPressed: _onStart,
              foregroundColor: AppColors.surfaceLow,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: Text(l10n.lobbyStart,
                        style: AppTheme.heading(22),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateName(AppLocalizations l10n, String? value) {
    if (value == null || value.trim().isEmpty) return l10n.lobbyNameRequired;
    return null;
  }

  // ---- Coin-flip reveal ----------------------------------------------------

  Widget _buildFlipResult(AppLocalizations l10n, BuildContext context) {
    final r = _result!;
    final locale = Localizations.localeOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FadeSlideIn(
          child: Text('⚡', style: TextStyle(fontSize: 56)),
        ),
        const SizedBox(height: AppSpacing.xl),
        FadeSlideIn(
          delay: const Duration(milliseconds: 500),
          child: _AssignmentChip(
            name: r.playerXName.toUpperCaseFor(locale),
            mark: 'X',
            color: AppColors.pitchGreen,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FadeSlideIn(
          delay: const Duration(milliseconds: 700),
          child: _AssignmentChip(
            name: r.playerOName.toUpperCaseFor(locale),
            mark: 'O',
            color: AppColors.gold,
          ),
        ),
      ],
    );
  }
}

// ---- Private helper widgets ------------------------------------------------

/// A styled text field for entering a player name.
class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.surface,
      borderColor: AppColors.border,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: TextCapitalization.words,
        maxLength: 16,
        style: AppTheme.headline(color: AppColors.white),
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: '',
          hintText: hint,
          hintStyle: AppTheme.headline(color: AppColors.whiteMuted.withValues(alpha: 0.4)),
          icon: Icon(icon, color: AppColors.pitchGreen, size: 28),
        ),
        validator: validator,
      ),
    );
  }
}

/// A card showing a player's mark assignment with a subtle pop effect.
class _AssignmentChip extends StatelessWidget {
  const _AssignmentChip({
    required this.name,
    required this.mark,
    required this.color,
  });

  final String name;
  final String mark;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.surface,
      borderColor: color.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(
        children: [
          // Mark badge
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Text(mark, style: AppTheme.display(color: color)),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.headline(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
