import 'dart:convert';

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

/// A scripted [GeminiTransport]: returns [responses] in call order, recording
/// every prompt it was asked. `null` in [responses] simulates a transport
/// failure for that call.
class _ScriptedTransport implements GeminiTransport {
  _ScriptedTransport(this.responses);
  final List<String?> responses;
  final List<String> prompts = [];
  int _i = 0;

  @override
  Future<String?> generateContent({
    required String prompt,
    required int thinkingBudget,
    required int maxOutputTokens,
  }) async {
    prompts.add(prompt);
    if (_i >= responses.length) return null;
    return responses[_i++];
  }
}

void main() {
  group('AnswerFinder.search', () {
    test('recall + verify success merges into a verified result', () async {
      final transport = _ScriptedTransport([
        _geminiBody('{"players": ["A", "B", "C"]}'), // recall
        _geminiBody('{"players": ["A", "B"]}'), // verify drops C
      ]);
      final result =
          await AnswerFinder(transport).search(condition1: 'X', condition2: 'Y');
      expect(result, isNotNull);
      expect(result!.players, ['A', 'B']);
      expect(result.verified, isTrue);
      expect(transport.prompts.length, 2);
    });

    test('empty recall returns null (nothing to verify)', () async {
      final transport = _ScriptedTransport([_geminiBody('{"players": []}')]);
      final result =
          await AnswerFinder(transport).search(condition1: 'X', condition2: 'Y');
      expect(result, isNull);
      expect(transport.prompts.length, 1); // never calls verify
    });

    test('recall transport failure returns null', () async {
      final transport = _ScriptedTransport([null]);
      final result =
          await AnswerFinder(transport).search(condition1: 'X', condition2: 'Y');
      expect(result, isNull);
    });

    test('verify rejecting everything returns an empty, verified result', () async {
      final transport = _ScriptedTransport([
        _geminiBody('{"players": ["A"]}'),
        _geminiBody('{"players": []}'),
      ]);
      final result =
          await AnswerFinder(transport).search(condition1: 'X', condition2: 'Y');
      expect(result, isNotNull);
      expect(result!.players, isEmpty);
      expect(result.verified, isTrue);
    });

    test('verify transport failure falls back to unverified recall list', () async {
      final transport = _ScriptedTransport([
        _geminiBody('{"players": ["A", "B"]}'),
        null,
      ]);
      final result =
          await AnswerFinder(transport).search(condition1: 'X', condition2: 'Y');
      expect(result, isNotNull);
      expect(result!.players, ['A', 'B']);
      expect(result.verified, isFalse);
    });
  });
}
