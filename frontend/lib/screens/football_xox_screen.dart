import 'dart:ui';
import 'package:flutter/material.dart';

import '../data/answer_search_service.dart';
import '../data/player.dart';
import '../data/player_database.dart';
import '../game/xox/factor.dart';
import '../game/xox/xox_cell.dart';
import '../game/xox/xox_game.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_card.dart';
import '../widgets/factor_image.dart';
import '../widgets/states.dart';

/// Football XOX: a two-player (X vs O) tic-tac-toe over a 3x3 trivia grid.
///
/// Each row and column has a random, unique [Factor], and the board is always
/// fully solvable. Players alternate; naming a footballer who satisfies a
/// cell's row AND column factor claims it with the current mark. A footballer
/// may be used once per match. First to complete a row, column, or diagonal of
/// their mark wins; a full board with no line is a draw.
class FootballXoxScreen extends StatefulWidget {
  const FootballXoxScreen({
    super.key,
    this.playerXName = 'Player X',
    this.playerOName = 'Player O',
  });

  /// Display name for the player assigned X.
  final String playerXName;

  /// Display name for the player assigned O.
  final String playerOName;

  @override
  State<FootballXoxScreen> createState() => _FootballXoxScreenState();
}

class _FootballXoxScreenState extends State<FootballXoxScreen> {
  late XoxGame _game;
  int _matchId = 0;

  /// The full player corpus, loaded once from the DB and reused for every new
  /// match so board solvability is validated against real data.
  List<Player> _corpus = const [];

  /// True while the database is being opened and the corpus loaded. The board
  /// is only built once this is false, so [_game] is always set by then.
  bool _loading = true;

  /// Fetches live, current-season reference answers for a reveal; falls back
  /// to the static on-device corpus when unavailable.
  final AnswerSearchService _answerSearch = AnswerSearchService();

  void _onCellTapped(int row, int col) {
    if (_game.isOver || _game.cellAt(row, col).isFilled) return;

    // Game Master mode: instantly claim the cell for the current player
    // without opening the search dialog.
    final dummyPlayer = Player(
      id: 'claim_${row}_$col',
      name: _game.currentPlayerName,
      nationality: '',
    );

    setState(() => _game = _game.claimCell(row, col, dummyPlayer));
  }

  void _onCellLongPressed(int row, int col) {
    final rowFactor = _game.rows[row];
    final colFactor = _game.columns[col];

    // Static on-device corpus serves as the offline fallback for the live,
    // current-season-aware search below.
    final fallback = _corpus
        .where((p) => rowFactor.matches(p) && colFactor.matches(p))
        .map((p) => p.name)
        .toList()
      ..sort();

    showDialog(
      context: context,
      builder: (context) => _AnswersDialog(
        rowFactor: rowFactor,
        colFactor: colFactor,
        search: _answerSearch.search(
          condition1: rowFactor.label,
          condition2: colFactor.label,
          localCorpus: fallback,
        ),
        fallback: fallback,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Opens the player database, loads the corpus and starts the first match.
  /// The corpus is fed to board generation so every cell has a real answer.
  ///
  /// If the database can't be opened (e.g. asset unavailable in a test), it
  /// falls back to an empty corpus — the board generator handles this via its
  /// own internal fallback logic.
  Future<void> _load() async {
    List<Player> corpus;
    try {
      corpus = await PlayerDatabase.instance.loadAllPlayers();
      debugPrint('[XOX] Loaded ${corpus.length} players');
    } catch (e) {
      debugPrint('[XOX] DB load failed: $e');
      corpus = const [];
    }
    
    final game = await XoxGame.createMatch(
      playerXName: widget.playerXName,
      playerOName: widget.playerOName,
    );
    
    if (!mounted) return;
    setState(() {
      _corpus = corpus;
      _game = game;
      _matchId++;
      _loading = false;
    });
  }

  Future<void> _newGame() async {
    setState(() => _loading = true);
    final game = await XoxGame.createMatch(
      playerXName: widget.playerXName,
      playerOName: widget.playerOName,
    );
    if (!mounted) return;
    setState(() {
      _game = game;
      _matchId++;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FOOTBALL XOX'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'New game',
              onPressed: _newGame,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingState(message: 'BUILDING YOUR BOARD');
    }
    return Column(
      children: [
        _StatusBar(
          game: _game,
          onPass: () => setState(() => _game = _game.passTurn()),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: FadeSlideIn(
                  // Re-key per match so the entrance replays on "New game".
                  key: ValueKey(_matchId),
                  child: _buildBoard(constraints),
                ),
              );
            },
          ),
        ),
        if (_game.isOver) ...[
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            key: ValueKey('result-$_matchId'),
            child: _ResultBanner(game: _game, onPlayAgain: _newGame),
          ),
        ],
      ],
    );
  }

  /// Builds the 4x4 visual layout: an empty corner + 3 column headers on top,
  /// 3 row headers down the left, and the 3x3 grid. Scales to fit.
  Widget _buildBoard(BoxConstraints constraints) {
    final side = constraints.biggest.shortestSide.clamp(0.0, 560.0);
    const spacing = 8.0;

    return SizedBox(
      width: side,
      height: side,
      child: Column(
        children: [
          // --- Header row: empty corner + 3 column factors. ---
          Expanded(
            child: Row(
              children: [
                const Expanded(child: SizedBox.shrink()),
                for (final col in _game.columns)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(spacing / 2),
                      child: _HeaderCell(factor: col),
                    ),
                  ),
              ],
            ),
          ),
          // --- Three body rows: row factor + 3 cells each. ---
          for (int r = 0; r < 3; r++)
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(spacing / 2),
                      child: _HeaderCell(factor: _game.rows[r]),
                    ),
                  ),
                  for (int c = 0; c < 3; c++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(spacing / 2),
                        child: _GridCell(
                          game: _game,
                          cell: _game.cellAt(r, c),
                          enabled: !_game.isOver,
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

/// Colour for a mark (X = pitch green, O = gold).
Color _markColor(Mark mark) =>
    mark == Mark.x ? AppColors.playerX : AppColors.playerO;

String _markLabel(Mark mark) => mark == Mark.x ? 'X' : 'O';

/// Turn indicator / score header.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.game, required this.onPass});
  final XoxGame game;
  final VoidCallback onPass;

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;
    if (game.winner != Mark.none) {
      text = '${game.nameOf(game.winner).toUpperCase()} WINS!';
      color = _markColor(game.winner);
    } else if (game.isDraw) {
      text = "IT'S A DRAW";
      color = AppColors.whiteMuted;
    } else {
      text = "${game.currentPlayerName.toUpperCase()}'S TURN";
      color = _markColor(game.current);
    }

    return PremiumCard(
      color: AppColors.surface,
      borderColor: color,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          // Turn token chip.
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
            child: Text(text, style: AppTheme.headline(color: color)),
          ),
          if (!game.isOver)
            PremiumButton(
              onPressed: onPass,
              expand: false,
              color: AppColors.surfaceLow,
              foregroundColor: AppColors.white,
              borderColor: AppColors.border,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: const Text('PAS'),
            )
          else
            Text(
              '${game.filledCount}/9',
              style: AppTheme.caption(),
            ),
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
              won
                  ? '${game.nameOf(game.winner)} completed a line!'
                  : 'No more moves — nobody got a line.',
              style: AppTheme.body(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          PremiumButton(
            onPressed: onPlayAgain,
            expand: false,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: const Text('PLAY AGAIN'),
          ),
        ],
      ),
    );
  }
}

/// A row/column header showing its factor image (icon-only, text fallback).
class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.factor});
  final Factor factor;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.surfaceHigh,
      borderColor: AppColors.border,
      radius: 12,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: FactorImage(factor: factor, imageSize: 42),
    );
  }
}

/// A single playable grid cell — empty (tappable) or claimed by X/O.
class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.game,
    required this.cell,
    required this.enabled,
    required this.onTap,
    required this.onLongPress,
  });
  final XoxGame game;
  final XoxCell cell;
  final bool enabled;
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
        trigger: filled ? cell.player?.id : null,
        child: PremiumCard(
          color: filled ? AppColors.surface : AppColors.surfaceLow,
          borderColor: filled ? markColor : AppColors.border,
          radius: 12,
          padding: const EdgeInsets.all(AppSpacing.xs),
          alignment: Alignment.center,
          child: filled ? _claimedContent(cell) : _emptyContent(),
        ),
      ),
    );
  }

  Widget _emptyContent() {
    return const Icon(Icons.add_rounded, color: AppColors.whiteMuted, size: 28);
  }

  Widget _claimedContent(XoxCell cell) {
    final markColor = _markColor(cell.mark);
    final playerName = game.nameOf(cell.mark);
    final markLabel = _markLabel(cell.mark);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 110,
              child: Text(
                playerName,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppTheme.label(
                  14,
                  color: AppColors.white,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          markLabel,
          style: AppTheme.heading(
            32,
            color: markColor,
          ),
        ),
      ],
    );
  }
}

/// A dialog listing valid players for the given [rowFactor] and [colFactor].
///
/// While [search] is in flight it shows a loading state, then renders the live,
/// current-season-aware LLM names; if the search yields `null` (no proxy
/// configured, no network, timeout, or an unparseable response) it falls back
/// to the on-device [fallback] names computed from the static corpus.
class _AnswersDialog extends StatefulWidget {
  const _AnswersDialog({
    required this.rowFactor,
    required this.colFactor,
    required this.search,
    required this.fallback,
  });

  final Factor rowFactor;
  final Factor colFactor;
  final Future<AnswerResult?> search;
  final List<String> fallback;

  @override
  State<_AnswersDialog> createState() => _AnswersDialogState();
}

class _AnswersDialogState extends State<_AnswersDialog> {
  bool _loading = true;
  late List<String> _names;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  /// Whether the shown list was fact-checked. The local [fallback] corpus is
  /// trusted, so it counts as verified; only an unverified live result is false.
  bool _verified = true;

  @override
  void initState() {
    super.initState();
    _names = widget.fallback;
    _resolve();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final live = await widget.search;
    if (!mounted) return;
    setState(() {
      _names = live?.players ?? widget.fallback;
      _verified = live?.verified ?? true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final filteredNames = _names
        .where((n) => n.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: PremiumCard(
          color: AppColors.surfaceHigh.withValues(alpha: 0.8),
          borderColor: AppColors.pitchGreen.withValues(alpha: 0.5),
          padding: const EdgeInsets.all(AppSpacing.lg),
          height: size.height * 0.7,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FactorImage(factor: widget.rowFactor, imageSize: 42),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text('×', style: TextStyle(color: AppColors.whiteMuted, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                FactorImage(factor: widget.colFactor, imageSize: 42),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _loading ? 'ARANIYOR…' : '${_names.length} OYUNCU',
              textAlign: TextAlign.center,
              style: AppTheme.overline(color: AppColors.pitchGreen),
            ),
            if (!_loading && _names.isNotEmpty && !_verified) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '⚠ DOĞRULANMADI — KONTROL EDİLMEDİ',
                textAlign: TextAlign.center,
                style: AppTheme.overline(color: AppColors.danger),
              ),
            ],
            if (!_loading && _names.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: AppTheme.label(14),
                cursorColor: AppColors.pitchGreen,
                decoration: InputDecoration(
                  hintText: 'OYUNCU ARA...',
                  hintStyle: AppTheme.label(14, color: AppColors.whiteMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.whiteMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceLow,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    borderSide: const BorderSide(color: AppColors.pitchGreen, width: 2),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _loading
                  ? const LoadingState(message: 'ARANIYOR…')
                  : filteredNames.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'EŞLEŞEN OYUNCU YOK',
                    )
                  : ListView.separated(
                      itemCount: filteredNames.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 20 * (i % 20)),
                          duration: AppTheme.durMed,
                          child: PremiumCard(
                            color: AppColors.surfaceLow,
                            borderColor: AppColors.border,

                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            child: Text(filteredNames[i], style: AppTheme.body()),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PremiumButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('KAPAT'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
