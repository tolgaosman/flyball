import 'dart:math';

import '../model/board.dart';
import '../model/factor.dart';
import '../model/factor_pool.dart';
import 'gemini_parser.dart';
import 'gemini_transport.dart';
import 'prompts.dart';

/// Builds a Football XOX board: draws 3 row + 3 column factors that obey
/// [FactorPool.axesAreValid], then confirms with ONE Gemini call that every
/// one of the 9 cells has real example players — swapping out whichever axis
/// factor is causing the most empty cells and retrying when some aren't
/// confirmed.
///
/// This is best-effort, not a hard guarantee: the returned [Board.cellExamples]
/// are only an instant preview for the long-press reveal — the authoritative
/// answer list is always fetched fresh (and with a more thorough two-phase
/// search) by [AnswerFinder] when a cell is actually revealed. So a board is
/// still returned even if a cell couldn't be confirmed within the attempt
/// budget; only a total transport failure (AI unreachable) returns `null`.
class BoardBuilder {
  BoardBuilder(this._transport);

  final GeminiTransport _transport;

  static const _maxAttempts = 3;

  Future<Board?> buildBoard({Random? random}) async {
    final rng = random ?? Random();
    var axes = FactorPool.pickAxisValidSix(rng);
    var rows = axes.rows;
    var columns = axes.columns;

    List<List<String>>? lastGoodCells;

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final cells = await _fetchCells(rows, columns);
      if (cells == null) {
        // Transport/parse failure. On the very first attempt this means AI is
        // unreachable — surface that as a hard failure. On a later attempt,
        // keep the last good board rather than losing progress.
        if (attempt == 0) return null;
        break;
      }
      lastGoodCells = cells;

      final emptyIndices = [
        for (var i = 0; i < cells.length; i++)
          if (cells[i].isEmpty) i,
      ];
      if (emptyIndices.isEmpty) {
        return Board(rows: rows, columns: columns, cellExamples: cells);
      }
      if (attempt == _maxAttempts - 1) break;

      // Swap out whichever axis (row or column) accounts for the most empty
      // cells, so one bad factor doesn't need 3 separate fixes.
      final emptyRowCounts = List.filled(3, 0);
      final emptyColCounts = List.filled(3, 0);
      for (final i in emptyIndices) {
        emptyRowCounts[i ~/ 3]++;
        emptyColCounts[i % 3]++;
      }
      final worstRow = _argMax(emptyRowCounts);
      final worstCol = _argMax(emptyColCounts);
      final replaceRow = emptyRowCounts[worstRow] >= emptyColCounts[worstCol];

      final replacement = _findReplacementFactor(
        rng,
        rows: rows,
        columns: columns,
        replaceRowIndex: replaceRow ? worstRow : null,
        replaceColIndex: replaceRow ? null : worstCol,
      );
      if (replacement == null) break; // no valid swap found; stop trying.

      if (replaceRow) {
        rows = [...rows]..[worstRow] = replacement;
      } else {
        columns = [...columns]..[worstCol] = replacement;
      }
    }

    return Board(
      rows: rows,
      columns: columns,
      cellExamples: lastGoodCells ?? List.generate(9, (_) => const []),
    );
  }

  Future<List<List<String>>?> _fetchCells(
    List<Factor> rows,
    List<Factor> columns,
  ) async {
    final prompt = Prompts.boardCells(
      [for (final r in rows) r.label],
      [for (final c in columns) c.label],
    );
    final body = await _transport.generateContent(
      prompt: prompt,
      thinkingBudget: 1024,
      maxOutputTokens: 4096,
    );
    if (body == null) return null;
    return GeminiParser.parseCells(body, expectedCells: 9);
  }

  int _argMax(List<int> values) {
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    return best;
  }

  /// Draws a fresh axis-valid replacement for the factor at [replaceRowIndex]
  /// (in rows) or [replaceColIndex] (in columns), bounded by a small number of
  /// tries. Returns null if no valid replacement is found.
  Factor? _findReplacementFactor(
    Random rng, {
    required List<Factor> rows,
    required List<Factor> columns,
    int? replaceRowIndex,
    int? replaceColIndex,
  }) {
    final pool = FactorPool.allFactors()..shuffle(rng);
    final current = {...rows, ...columns};
    for (final candidate in pool) {
      if (current.contains(candidate)) continue;
      final newRows = replaceRowIndex != null
          ? ([...rows]..[replaceRowIndex] = candidate)
          : rows;
      final newColumns = replaceColIndex != null
          ? ([...columns]..[replaceColIndex] = candidate)
          : columns;
      if (FactorPool.axesAreValid(newRows, newColumns)) return candidate;
    }
    return null;
  }
}
