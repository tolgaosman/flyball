import 'dart:convert';

import 'package:flyball_core/flyball_core.dart';
import 'package:test/test.dart';

String _geminiBody(String text, {String finishReason = 'STOP'}) => jsonEncode({
      'candidates': [
        {
          'finishReason': finishReason,
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    });

void main() {
  group('GeminiParser.parsePlayers', () {
    test('parses a clean JSON players object', () {
      final body = _geminiBody('{"players": ["Lionel Messi", "Cristiano Ronaldo"]}');
      expect(GeminiParser.parsePlayers(body),
          ['Lionel Messi', 'Cristiano Ronaldo']);
    });

    test('recovers JSON wrapped in markdown fences and prose', () {
      final body = _geminiBody(
          'Sure, here you go:\n```json\n{"players": ["Kylian Mbappe"]}\n```\nHope that helps!');
      expect(GeminiParser.parsePlayers(body), ['Kylian Mbappe']);
    });

    test('accepts object-shaped player entries with a name field', () {
      final body = _geminiBody(
          '{"players": [{"name": "Erling Haaland", "note": "2023-24"}]}');
      expect(GeminiParser.parsePlayers(body), ['Erling Haaland']);
    });

    test('an empty players array parses as an empty list, not null', () {
      final body = _geminiBody('{"players": []}');
      expect(GeminiParser.parsePlayers(body), isEmpty);
    });

    test('returns null on MAX_TOKENS (truncated, unreliable answer)', () {
      final body = _geminiBody('{"players": ["Partial', finishReason: 'MAX_TOKENS');
      expect(GeminiParser.parsePlayers(body), isNull);
    });

    test('returns null on malformed JSON', () {
      expect(GeminiParser.parsePlayers('not json at all'), isNull);
    });

    test('returns null when candidates are missing', () {
      expect(GeminiParser.parsePlayers(jsonEncode({'candidates': []})), isNull);
    });
  });

  group('GeminiParser.parseCells', () {
    test('parses 9 cells in order and pads missing ones with empty lists', () {
      final cells = List.generate(5, (i) => {'players': ['P$i']});
      final body = _geminiBody(jsonEncode({'cells': cells}));
      final parsed = GeminiParser.parseCells(body, expectedCells: 9);
      expect(parsed, isNotNull);
      expect(parsed!.length, 9);
      expect(parsed[0], ['P0']);
      expect(parsed[8], isEmpty);
    });
  });
}
