import 'package:flyball_core/flyball_core.dart';

import '../../data/ai/ai_exceptions.dart';
import '../../data/ai/ai_gateway.dart';
import 'xox_cell.dart';

/// Immutable-ish controller for a single 2-player Football XOX match.
///
/// Runs in **Game Master Mode**: players alternate, and tapping an empty cell
/// instantly claims it with the current mark (the two players agree verbally
/// on a real footballer satisfying that cell's row + column factor — there is
/// no in-app validation of *which* footballer). The first to complete a line
/// of their mark — any row, any column, or a main diagonal — wins; a full
/// board with no line is a draw.
class XoxGame {
  XoxGame._({
    required this.rows,
    required this.columns,
    required this.cellExamples,
    required List<XoxCell> cells,
    required this.current,
    required this.winner,
    required this.isDraw,
    required this.playerXName,
    required this.playerOName,
  }) : _cells = cells; // ignore: prefer_initializing_formals

  /// Starts a fresh match by fetching an AI-verified board.
  ///
  /// Throws [AiUnavailableException] if the AI is unreachable/unconfigured —
  /// callers must catch this and show an error/retry state, never silently
  /// show an empty or broken board.
  static Future<XoxGame> createMatch({
    required AiGateway aiGateway,
    String playerXName = 'Player X',
    String playerOName = 'Player O',
  }) async {
    final board = await aiGateway.nextBoard();
    if (board == null) throw const AiUnavailableException();

    return XoxGame._(
      rows: board.rows,
      columns: board.columns,
      cellExamples: board.cellExamples,
      cells: List<XoxCell>.filled(9, const XoxCell()),
      current: Mark.x,
      winner: Mark.none,
      isDraw: false,
      playerXName: playerXName,
      playerOName: playerOName,
    );
  }

  /// Creates a match for testing without network calls.
  factory XoxGame.testMatch({
    List<Factor> rows = const [],
    List<Factor> columns = const [],
    List<List<String>>? cellExamples,
    String playerXName = 'Player X',
    String playerOName = 'Player O',
  }) {
    return XoxGame._(
      rows: rows,
      columns: columns,
      cellExamples: cellExamples ?? List.generate(9, (_) => const []),
      cells: List<XoxCell>.filled(9, const XoxCell()),
      current: Mark.x,
      winner: Mark.none,
      isDraw: false,
      playerXName: playerXName,
      playerOName: playerOName,
    );
  }

  final List<Factor> rows;
  final List<Factor> columns;

  /// Example players confirmed (by the AI board builder) to satisfy each
  /// cell — indexed `row * 3 + col`. An instant preview for the long-press
  /// reveal; the authoritative list is always re-fetched fresh via
  /// [AiGateway.searchFactors].
  final List<List<String>> cellExamples;

  final List<XoxCell> _cells;

  /// Display name of the X player.
  final String playerXName;

  /// Display name of the O player.
  final String playerOName;

  /// Whose turn it is (X or O). [Mark.none] only when the game is over.
  final Mark current;

  /// The winning mark, or [Mark.none] if no winner yet.
  final Mark winner;

  /// True when the board filled with no winner.
  final bool isDraw;

  /// Returns the display name for the given [mark].
  String nameOf(Mark mark) => mark == Mark.x ? playerXName : playerOName;

  /// Returns the display name of the player whose turn it is.
  String get currentPlayerName => nameOf(current);

  List<XoxCell> get cells => List.unmodifiable(_cells);

  bool get isOver => winner != Mark.none || isDraw;

  int get filledCount => _cells.where((c) => c.isFilled).length;

  XoxCell cellAt(int row, int col) => _cells[row * 3 + col];

  List<String> examplesAt(int row, int col) => cellExamples[row * 3 + col];

  /// Returns a new game state with the current mark claiming the cell at
  /// (row, col), advancing the turn and recomputing win/draw. If the cell is
  /// occupied or the game is over, returns `this` unchanged.
  XoxGame claimCell(int row, int col) {
    final index = row * 3 + col;
    if (isOver || _cells[index].isFilled) return this;

    final newCells = List<XoxCell>.of(_cells);
    newCells[index] = newCells[index].claim(current);

    final newWinner = _findWinner(newCells);
    final boardFull = newCells.every((c) => c.isFilled);
    final draw = newWinner == Mark.none && boardFull;

    // Turn passes only while the game continues.
    final nextMark = (newWinner != Mark.none || draw)
        ? Mark.none
        : (current == Mark.x ? Mark.o : Mark.x);

    return XoxGame._(
      rows: rows,
      columns: columns,
      cellExamples: cellExamples,
      cells: newCells,
      current: nextMark,
      winner: newWinner,
      isDraw: draw,
      playerXName: playerXName,
      playerOName: playerOName,
    );
  }

  /// Passes the turn to the other player without claiming a cell (used when
  /// no valid move can be found verbally). No-op once the game is over.
  XoxGame passTurn() {
    if (isOver) return this;
    return XoxGame._(
      rows: rows,
      columns: columns,
      cellExamples: cellExamples,
      cells: _cells,
      current: current == Mark.x ? Mark.o : Mark.x,
      winner: winner,
      isDraw: isDraw,
      playerXName: playerXName,
      playerOName: playerOName,
    );
  }

  /// The 8 winning lines as cell-index triples.
  static const List<List<int>> _lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
    [0, 4, 8], [2, 4, 6], // main diagonals
  ];

  static Mark _findWinner(List<XoxCell> cells) {
    for (final line in _lines) {
      final a = cells[line[0]].mark;
      if (a != Mark.none &&
          a == cells[line[1]].mark &&
          a == cells[line[2]].mark) {
        return a;
      }
    }
    return Mark.none;
  }
}
