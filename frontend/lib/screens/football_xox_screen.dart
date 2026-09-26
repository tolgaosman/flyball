import 'package:flutter/material.dart';
import 'package:flyball_core/flyball_core.dart';

import '../config/app_config.dart';
import '../data/ai/ai_exceptions.dart';
import '../data/ai/ai_gateway.dart';
import '../data/ai/ai_gateway_factory.dart';
import '../game/xox/xox_cell.dart';
import '../game/xox/xox_game.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';
import '../widgets/ai_state_views.dart';
import '../widgets/animations.dart';
import '../widgets/answers_sheet.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_card.dart';
import '../widgets/factor_image.dart';
import '../widgets/states.dart';

/// Football XOX: a two-player (X vs O) tic-tac-toe over a 3x3 trivia grid.
///
/// Runs in **Game Master Mode**: each row/column has a random, AI-verified
/// [Factor]. Tapping an empty cell instantly claims it for whoever's turn it
/// is (the two players agree verbally on a real footballer satisfying that
/// cell) — long-pressing reveals the AI's answer list for that cell instead.
/// First to complete a row, column, or diagonal of their mark wins; a full
/// board with no line is a draw.
class FootballXoxScreen extends StatefulWidget {
  const FootballXoxScreen({
    super.key,
    this.playerXName = 'Player X',
    this.playerOName = 'Player O',
  });

  final String playerXName;
  final String playerOName;

  @override
  State<FootballXoxScreen> createState() => _FootballXoxScreenState();
}

class _FootballXoxScreenState extends State<FootballXoxScreen> {
  late final AiGateway _aiGateway = createAiGateway();

  XoxGame? _game;
  int _matchId = 0;
  bool _loading = true;
  bool _errored = false;

  /// Guards against a slower stale `_load`/`_newGame` call overwriting a
  /// newer one's result (e.g. mashing the refresh button).
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    if (AppConfig.hasAi) _load();
  }

  void _onCellTapped(int row, int col) {
    final game = _game;
    if (game == null || game.isOver || game.cellAt(row, col).isFilled) return;
    setState(() => _game = game.claimCell(row, col));
  }

  void _onCellLongPressed(int row, int col) {
    final game = _game;
    if (game == null) return;
    final rowFactor = game.rows[row];
    final colFactor = game.columns[col];

    showAiAnswersSheet(
      context,
      header: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FactorImage(factor: rowFactor, imageSize: 42),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('×', style: TextStyle(color: AppColors.whiteMuted, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          FactorImage(factor: colFactor, imageSize: 42),
        ],
      ),
      preview: game.examplesAt(row, col),
      fetch: () => _aiGateway.searchFactors(rowFactor.label, colFactor.label),
    );
  }

  Future<void> _load() => _startMatch(showFullLoading: true);

  Future<void> _newGame() => _startMatch(showFullLoading: false);

  Future<void> _startMatch({required bool showFullLoading}) async {
    final requestId = ++_requestId;
    setState(() => _loading = true);
    XoxGame? game;
    var errored = false;
    try {
      game = await XoxGame.createMatch(
        aiGateway: _aiGateway,
        playerXName: widget.playerXName,
        playerOName: widget.playerOName,
      );
    } on AiUnavailableException {
      errored = true;
    }
    if (!mounted || requestId != _requestId) return; // a newer request won.
    setState(() {
      _loading = false;
      _errored = errored;
      if (game != null) {
        _game = game;
        _matchId++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.xoxTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: l10n.xoxNewGameTooltip,
              onPressed: _loading ? null : _newGame,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _buildBody(l10n),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (!AppConfig.hasAi) return const AiNotConfiguredView();
    if (_loading) return LoadingState(message: l10n.xoxBuildingBoard);
    if (_errored || _game == null) {
      return ErrorState(
        title: l10n.xoxBoardUnavailableTitle,
        message: l10n.aiUnavailableMessage,
        action: PremiumButton(
          onPressed: _load,
          expand: false,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Text(l10n.retry),
        ),
      );
    }

    final game = _game!;
    return Column(
      children: [
        _StatusBar(game: game, onPass: () => setState(() => _game = game.passTurn())),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: FadeSlideIn(
                  key: ValueKey(_matchId),
                  child: _buildBoard(constraints, game),
                ),
              );
            },
          ),
        ),
        if (game.isOver) ...[
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            key: ValueKey('result-$_matchId'),
            child: _ResultBanner(game: game, onPlayAgain: _newGame),
          ),
        ],
      ],
    );
  }

  /// Builds the 4x4 visual layout: an empty corner + 3 column headers on top,
  /// 3 row headers down the left, and the 3x3 grid. Scales to fit, and sizes
  /// header art / cell text off the actual cell size rather than a fixed
  /// constant, so small cells (e.g. landscape) never overflow.
  Widget _buildBoard(BoxConstraints constraints, XoxGame game) {
    final side = constraints.biggest.shortestSide.clamp(0.0, 560.0);
    const spacing = 8.0;
    final cellSize = side / 4;
    final imageSize = (cellSize * 0.5).clamp(24.0, 48.0);
    final markFontSize = (cellSize * 0.32).clamp(16.0, 32.0);

    return SizedBox(
      width: side,
      height: side,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                const Expanded(child: SizedBox.shrink()),
                for (final col in game.columns)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(spacing / 2),
                      child: _HeaderCell(factor: col, imageSize: imageSize),
                    ),
                  ),
              ],
            ),
          ),
          for (int r = 0; r < 3; r++)
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(spacing / 2),
                      child: _HeaderCell(factor: game.rows[r], imageSize: imageSize),
                    ),
                  ),
                  for (int c = 0; c < 3; c++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(spacing / 2),
                        child: _GridCell(
                          game: game,
                          cell: game.cellAt(r, c),
                          enabled: !game.isOver,
                          markFontSize: markFontSize,
                          onTap: () => _onCellTapped(r, c),
                          onLongPress: () => _onCellLongPressed(r, c),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Color _markColor(Mark mark) => mark == Mark.x ? AppColors.playerX : AppColors.playerO;
String _markLabel(Mark mark) => mark == Mark.x ? 'X' : 'O';

/// Turn indicator / score header.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.game, required this.onPass});
  final XoxGame game;
  final VoidCallback onPass;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final String text;
    final Color color;
    if (game.winner != Mark.none) {
      text = l10n.xoxWins(game.nameOf(game.winner).toUpperCaseFor(locale));
      color = _markColor(game.winner);
    } else if (game.isDraw) {
      text = l10n.xoxDraw;
      color = AppColors.whiteMuted;
    } else {
      text = l10n.xoxTurn(game.currentPlayerName);
      color = _markColor(game.current);
    }

    return PremiumCard(
      color: AppColors.surface,
      borderColor: color,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          SuccessPop(
            trigger: '${game.current}-${game.isOver}',
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: color, width: 2.5),
              ),
              child: Text(
                game.isOver ? '🏁' : _markLabel(game.current),
                style: AppTheme.headline(color: color),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.headline(color: color),
            ),
          ),
          if (!game.isOver)
            PremiumButton(
              onPressed: onPass,
              expand: false,
              color: AppColors.surfaceLow,
              foregroundColor: AppColors.white,
              borderColor: AppColors.border,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Text(l10n.xoxPass),
            )
          else
            Text('${game.filledCount}/9', style: AppTheme.caption()),
        ],
      ),
    );
  }
}

/// Win/draw banner with a "play again" button.
class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.game, required this.onPlayAgain});
  final XoxGame game;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final won = game.winner != Mark.none;
    final color = won ? _markColor(game.winner) : AppColors.whiteMuted;
    return PremiumCard(
      color: AppColors.surface,
      borderColor: color,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              won ? l10n.xoxCompletedLine(game.nameOf(game.winner)) : l10n.xoxNoMoreMoves,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          PremiumButton(
            onPressed: onPlayAgain,
            expand: false,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Text(l10n.xoxPlayAgain),
          ),
        ],
      ),
    );
  }
}

/// A row/column header showing its factor image (icon-only, text fallback).
class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.factor, required this.imageSize});
  final Factor factor;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.surfaceHigh,
      borderColor: AppColors.border,
      radius: 12,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: FactorImage(factor: factor, imageSize: imageSize),
    );
  }
}

/// A single playable grid cell — empty (tappable) or claimed by X/O.
class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.game,
    required this.cell,
    required this.enabled,
    required this.markFontSize,
    required this.onTap,
    required this.onLongPress,
  });
  final XoxGame game;
  final XoxCell cell;
  final bool enabled;
  final double markFontSize;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final filled = cell.isFilled;
    final markColor = filled ? _markColor(cell.mark) : AppColors.border;
    return SpringScale(
      enabled: !filled && enabled,
      onTap: (filled || !enabled) ? null : onTap,
      onLongPress: onLongPress,
      child: SuccessPop(
        trigger: filled ? '${cell.mark}' : null,
        child: PremiumCard(
          color: filled ? AppColors.surface : AppColors.surfaceLow,
          borderColor: filled ? markColor : AppColors.border,
          radius: 12,
          padding: const EdgeInsets.all(AppSpacing.xs),
          alignment: Alignment.center,
          child: filled ? _claimedContent(context, cell) : _emptyContent(),
        ),
      ),
    );
  }

  Widget _emptyContent() {
    return const Icon(Icons.add_rounded, color: AppColors.whiteMuted, size: 28);
  }

  Widget _claimedContent(BuildContext context, XoxCell cell) {
    final markColor = _markColor(cell.mark);
    final markLabel = _markLabel(cell.mark);
    // Scale the whole claimed mark down together on very small cells (e.g.
    // landscape) instead of overflowing.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(markLabel, style: AppTheme.heading(markFontSize, color: markColor)),
    );
  }
}
