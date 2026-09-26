import 'dart:convert';
import 'dart:io';

import 'package:backend/app_service.dart';
import 'package:backend/cache_db.dart';
import 'package:flyball_core/flyball_core.dart';
import 'package:path/path.dart' as p;
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

/// A transport that counts calls and always finds one player, so recall and
/// verify each succeed on the first try.
class _CountingTransport implements GeminiTransport {
  int calls = 0;

  @override
  Future<String?> generateContent({
    required String prompt,
    required int thinkingBudget,
    required int maxOutputTokens,
  }) async {
    calls++;
    return _geminiBody('{"players": ["Radamel Falcao"]}');
  }
}

void main() {
  late Directory tempDir;
  late CacheDb cache;
  late _CountingTransport transport;
  late AppService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('flyball_app_service_test_');
    cache = CacheDb(p.join(tempDir.path, 'test.db'));
    await cache.open();
    transport = _CountingTransport();
    final answerFinder = AnswerFinder(transport);
    service = AppService(
      cache: cache,
      answerFinder: answerFinder,
      boardBuilder: BoardBuilder(transport),
      roundPicker: RoundPicker(answerFinder),
    );
  });

  tearDown(() async {
    await cache.close();
    await tempDir.delete(recursive: true);
  });

  test('a second identical request is served from the cache without calling the AI again', () async {
    final first = await service.answersForTwoTeam('Monaco', 'Galatasaray');
    expect(first!.players, ['Radamel Falcao']);
    final callsAfterFirst = transport.calls;
    expect(callsAfterFirst, 2); // recall + verify

    final second = await service.answersForTwoTeam('Monaco', 'Galatasaray');
    expect(second!.players, ['Radamel Falcao']);
    expect(transport.calls, callsAfterFirst, reason: 'served from cache, no new Gemini calls');
  });

  test('twoTeam cache is order-independent', () async {
    await service.answersForTwoTeam('Monaco', 'Galatasaray');
    final callsAfterFirst = transport.calls;

    final swapped = await service.answersForTwoTeam('Galatasaray', 'Monaco');
    expect(swapped!.players, ['Radamel Falcao']);
    expect(transport.calls, callsAfterFirst, reason: 'same pair, different order, still cached');
  });

  test('concurrent identical requests are deduped into a single AI call', () async {
    final futures = [
      service.answersForTeamCountry('Monaco', 'France'),
      service.answersForTeamCountry('Monaco', 'France'),
      service.answersForTeamCountry('Monaco', 'France'),
    ];
    final results = await Future.wait(futures);
    for (final r in results) {
      expect(r!.players, ['Radamel Falcao']);
    }
    expect(transport.calls, 2, reason: 'one recall + one verify, shared across all 3 callers');
  });

  test('nextRound serves a buffered round instantly when one is pushed ahead of time', () async {
    await cache.pushRound(Round(
      kind: RoundKind.twoTeam,
      conditionA: 'Arsenal',
      conditionB: 'Chelsea',
      answers: const AnswerResult(['Preset Player'], verified: true),
    ));

    final round = await service.nextRound(RoundKind.twoTeam);
    expect(round!.conditionA, 'Arsenal');
    expect(round.answers.players, ['Preset Player']);

    // nextRound() also kicks off a background buffer top-up (unawaited by
    // design, so the caller never waits on it) — give it a beat to finish
    // before tearDown closes the database out from under it.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
}
