import 'package:flyball/data/ai/ai_gateway.dart';
import 'package:flyball/game/party/round_queue.dart';
import 'package:flyball_core/flyball_core.dart';
import 'package:flutter_test/flutter_test.dart';

Round _round(String a, String b) => Round(
      kind: RoundKind.twoTeam,
      conditionA: a,
      conditionB: b,
      answers: const AnswerResult(['Someone'], verified: true),
    );

class _FakeAiGateway implements AiGateway {
  int twoTeamCalls = 0;
  List<Round?> twoTeamResponses = [];

  @override
  Future<Round?> nextTwoTeamRound() async {
    final i = twoTeamCalls++;
    if (i >= twoTeamResponses.length) return null;
    return twoTeamResponses[i];
  }

  @override
  Future<AnswerResult?> searchTwoTeam(String teamA, String teamB) async => null;
  @override
  Future<AnswerResult?> searchTeamCountry(String team, String country) async => null;
  @override
  Future<AnswerResult?> searchFactors(String condition1, String condition2) async => null;
  @override
  Future<Round?> nextTeamCountryRound() async => null;
  @override
  Future<Board?> nextBoard() async => null;
}

void main() {
  group('RoundQueue', () {
    test('next() returns a fetched round when nothing is buffered yet', () async {
      final gateway = _FakeAiGateway()..twoTeamResponses = [_round('A', 'B')];
      final queue = RoundQueue(aiGateway: gateway, kind: RoundKind.twoTeam);
      final round = await queue.next();
      expect(round?.conditionA, 'A');
    });

    test('a background-prefetched round is served instantly on the next call', () async {
      final gateway = _FakeAiGateway()
        ..twoTeamResponses = [_round('A', 'B'), _round('C', 'D')];
      final queue = RoundQueue(aiGateway: gateway, kind: RoundKind.twoTeam);

      // Call 1: nothing buffered yet, fetches "A/B" directly, then kicks off
      // a background prefetch of "C/D" (call 2).
      final first = await queue.next();
      expect(first?.conditionA, 'A');

      // Let the background prefetch resolve before asking for the next round.
      await Future<void>.delayed(Duration.zero);

      // Call 2: the prefetched "C/D" is served instantly from the buffer,
      // which then kicks off ANOTHER prefetch (call 3, beyond the scripted
      // responses, so it resolves to null and leaves nothing buffered).
      final second = await queue.next();
      expect(second?.conditionA, 'C');
      expect(gateway.twoTeamCalls, 3);
    });

    test('returns null when the AI is unreachable', () async {
      final gateway = _FakeAiGateway();
      final queue = RoundQueue(aiGateway: gateway, kind: RoundKind.twoTeam);
      expect(await queue.next(), isNull);
    });
  });
}
