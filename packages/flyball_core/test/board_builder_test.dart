import 'dart:convert';
import 'dart:math';

import 'package:flyball_core/flyball_core.dart';
import 'package:test/test.dart';

String _geminiBody(String text) => jsonEncode({
      'candidates': [
        {
          'finishReason': 'STOP',
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    });

String _cellsBody(List<List<String>> cells) =>
    _geminiBody(jsonEncode({'cells': [for (final c in cells) {'players': c}]}));

class _ScriptedTransport implements GeminiTransport {
  _ScriptedTransport(this.responses);
  final List<String?> responses;
  int calls = 0;

  @override
  Future<String?> generateContent({
    required String prompt,
    required int thinkingBudget,
    required int maxOutputTokens,
  }) async {
    final i = calls++;
    if (i >= responses.length) return responses.isEmpty ? null : responses.last;
    return responses[i];
  }
}

void main() {
  group('BoardBuilder.buildBoard', () {
    test('returns a solved board immediately when all 9 cells resolve', () async {
      final allFilled = List.generate(9, (_) => ['Some Player']);
      final transport = _ScriptedTransport([_cellsBody(allFilled)]);
      final board = await BoardBuilder(transport).buildBoard(random: Random(1));
      expect(board, isNotNull);
      expect(board!.rows.length, 3);
      expect(board.columns.length, 3);
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          expect(board.examplesAt(r, c), isNotEmpty);
        }
      }
    });

    test('swaps a factor out when a cell keeps coming back empty', () async {
      // First attempt: cell 0 empty, everything else filled.
      final firstAttempt = List.generate(9, (i) => i == 0 ? <String>[] : ['P']);
      // Second attempt (after a swap): everything filled.
      final secondAttempt = List.generate(9, (_) => ['P']);
      final transport = _ScriptedTransport([
        _cellsBody(firstAttempt),
        _cellsBody(secondAttempt),
      ]);
      final board = await BoardBuilder(transport).buildBoard(random: Random(2));
      expect(board, isNotNull);
      expect(transport.calls, 2);
      for (var i = 0; i < 9; i++) {
        expect(board!.cellExamples[i], isNotEmpty);
      }
    });

    test('returns null when the AI is unreachable on the first attempt', () async {
      final transport = _ScriptedTransport([null]);
      final board = await BoardBuilder(transport).buildBoard(random: Random(3));
      expect(board, isNull);
    });

    test('still returns a board (not null) if some cells never resolve', () async {
      final alwaysOneEmpty = List.generate(9, (i) => i == 0 ? <String>[] : ['P']);
      final transport = _ScriptedTransport([_cellsBody(alwaysOneEmpty)]);
      final board = await BoardBuilder(transport).buildBoard(random: Random(4));
      expect(board, isNotNull);
      expect(board!.rows.length, 3);
    });
  });
}
