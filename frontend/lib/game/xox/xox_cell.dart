/// Which player owns a cell (or none yet).
enum Mark { none, x, o }

/// The state of one cell in the 3x3 XOX grid.
///
/// Football XOX runs in **Game Master Mode**: tapping a cell instantly claims
/// it for whoever's turn it is (players verbally agree on a real footballer
/// away from the screen) — so a cell only needs to remember who claimed it,
/// not which specific footballer was named.
class XoxCell {
  const XoxCell({this.mark = Mark.none});

  /// The owner of this cell.
  final Mark mark;

  bool get isFilled => mark != Mark.none;

  XoxCell claim(Mark mark) => XoxCell(mark: mark);
}
