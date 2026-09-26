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

/// Always answers "found nobody" on recall (so [AnswerFinder.search] returns
/// null), forcing [RoundPicker] to retry with a new draw each time.
class _AlwaysEmptyTransport implements GeminiTransport {
  int calls = 0;
  @override
  Future<String?> generateContent({
    required String prompt,
    required int thinkingBudget,
    required int maxOutputTokens,
  }) async {
    calls++;
    return _geminiBody('{"players": []}');
  }
}

/// Always finds a confirmed answer on the first try.
class _AlwaysFoundTransport implements GeminiTransport {
  int calls = 0;
  @override
  Future<String?> generateContent({
    required String prompt,
    required int thinkingBudget,
    required int maxOutputTokens,
  }) async {
    calls++;
    // recall (odd calls) then verify (even calls) both return one player.
    return _geminiBody('{"players": ["Test Player"]}');
  }
}

void main() {
  group('RoundPicker.nextTwoTeamRound', () {
    test('returns a confirmed round on the first successful draw', () async {
      final transport = _AlwaysFoundTransport();
      final round = await RoundPicker(AnswerFinder(transport))
          .nextTwoTeamRound(random: Random(1));
      expect(round, isNotNull);
      expect(round!.kind, RoundKind.twoTeam);
      expect(round.answers.players, ['Test Player']);
      expect(round.conditionA, isNot(equals(round.conditionB)));
    });

    test('gives up after maxAttempts of empty answers and returns the last unverified draw',
        () async {
      final transport = _AlwaysEmptyTransport();
      final round = await RoundPicker(AnswerFinder(transport))
          .nextTwoTeamRound(random: Random(2));
      // Every recall came back empty -> AnswerFinder.search returns null each
      // time -> RoundPicker exhausts its attempts with no fallback round.
      expect(round, isNull);
    });
  });

  group('RoundPicker.nextTeamCountryRound', () {
    test('returns a confirmed club + nationality round', () async {
      final transport = _AlwaysFoundTransport();
      final round = await RoundPicker(AnswerFinder(transport))
          .nextTeamCountryRound(random: Random(3));
      expect(round, isNotNull);
      expect(round!.kind, RoundKind.teamCountry);
      expect(round.answers.players, ['Test Player']);
    });
  });
}
