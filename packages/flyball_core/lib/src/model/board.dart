import 'factor.dart';

/// A fully-formed, AI-verified XOX board: 3 row factors, 3 column factors, and
/// (for each of the 9 cells) a short list of example players confirmed to
/// satisfy both — used for the instant long-press reveal and as proof the
/// cell is actually answerable.
///
/// [cellExamples] is indexed `row * 3 + col`, matching [XoxGame.cellAt].
class Board {
  const Board({
    required this.rows,
    required this.columns,
    required this.cellExamples,
  });

  final List<Factor> rows;
  final List<Factor> columns;
  final List<List<String>> cellExamples;

  /// Example players for the cell at (row, col), or an empty list if none
  /// were confirmed.
  List<String> examplesAt(int row, int col) => cellExamples[row * 3 + col];

  Map<String, dynamic> toJson() => {
        'rows': rows.map((f) => f.toJson()).toList(),
        'columns': columns.map((f) => f.toJson()).toList(),
        'cellExamples': cellExamples,
      };

  /// Parses a board from JSON, validating the 3×3 shape so a malformed
  /// response (wrong row/column count) surfaces as a clear exception instead
  /// of a later `RangeError` deep in the UI.
  factory Board.fromJson(Map<String, dynamic> json) {
    final rows = (json['rows'] as List)
        .map((f) => Factor.fromJson(f as Map<String, dynamic>))
        .toList();
    final columns = (json['columns'] as List)
        .map((f) => Factor.fromJson(f as Map<String, dynamic>))
        .toList();
    if (rows.length != 3 || columns.length != 3) {
      throw FormatException(
          'Board must have exactly 3 rows and 3 columns, got '
          '${rows.length}x${columns.length}');
    }
    final rawExamples = json['cellExamples'] as List?;
    final cellExamples = List<List<String>>.generate(9, (i) {
      if (rawExamples == null || i >= rawExamples.length) return const [];
      return (rawExamples[i] as List).map((e) => e.toString()).toList();
    });
    return Board(rows: rows, columns: columns, cellExamples: cellExamples);
  }
}
