import 'package:flyball/game/xox/xox_cell.dart';
import 'package:flyball/game/xox/xox_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('XoxGame', () {
    test('starts with X, no winner, empty board', () {
      final game = XoxGame.testMatch();
      expect(game.current, Mark.x);
      expect(game.winner, Mark.none);
      expect(game.isDraw, isFalse);
      expect(game.filledCount, 0);
    });

    test('claimCell alternates the turn', () {
      var game = XoxGame.testMatch();
      game = game.claimCell(0, 0);
      expect(game.cellAt(0, 0).mark, Mark.x);
      expect(game.current, Mark.o);
      game = game.claimCell(0, 1);
      expect(game.cellAt(0, 1).mark, Mark.o);
      expect(game.current, Mark.x);
    });

    test('claiming an already-filled cell is a no-op', () {
      var game = XoxGame.testMatch();
      game = game.claimCell(1, 1);
      final afterFirst = game;
      game = game.claimCell(1, 1); // same cell, now O's turn
      expect(game, same(afterFirst));
    });

    test('detects a row win', () {
      var game = XoxGame.testMatch();
      game = game.claimCell(0, 0); // X
      game = game.claimCell(1, 0); // O
      game = game.claimCell(0, 1); // X
      game = game.claimCell(1, 1); // O
      game = game.claimCell(0, 2); // X completes row 0
      expect(game.winner, Mark.x);
      expect(game.isOver, isTrue);
    });

    test('detects a draw with no winner', () {
      // X O X
      // X O O
      // O X X
      var game = XoxGame.testMatch();
      final moves = [
        (0, 0), (0, 1), // X, O
        (0, 2), (1, 1), // X, O
        (1, 0), (1, 2), // X, O
        (2, 1), (2, 0), // X, O
        (2, 2), // X
      ];
      for (final m in moves) {
        game = game.claimCell(m.$1, m.$2);
      }
      expect(game.winner, Mark.none);
      expect(game.isDraw, isTrue);
      expect(game.filledCount, 9);
    });

    test('passTurn hands the turn over without filling a cell', () {
      var game = XoxGame.testMatch();
      expect(game.current, Mark.x);
      game = game.passTurn();
      expect(game.current, Mark.o);
      expect(game.filledCount, 0);
    });

    test('nameOf resolves the display name for each mark', () {
      final game = XoxGame.testMatch(playerXName: 'Alice', playerOName: 'Bob');
      expect(game.nameOf(Mark.x), 'Alice');
      expect(game.nameOf(Mark.o), 'Bob');
      expect(game.currentPlayerName, 'Alice');
    });

    test('examplesAt reads the board-builder preview for a cell', () {
      final game = XoxGame.testMatch(
        cellExamples: [
          for (var i = 0; i < 9; i++) i == 4 ? ['Test Player'] : <String>[],
        ],
      );
      expect(game.examplesAt(1, 1), ['Test Player']);
      expect(game.examplesAt(0, 0), isEmpty);
    });
  });
}
