import 'dart:io';

import 'package:backend/cache_db.dart';
import 'package:flyball_core/flyball_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late CacheDb cache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('flyball_cache_test_');
    cache = CacheDb(p.join(tempDir.path, 'test.db'));
    await cache.open();
  });

  tearDown(() async {
    await cache.close();
    await tempDir.delete(recursive: true);
  });

  group('CacheDb.keyFor', () {
    test('twoTeam is order-independent (a club pair reads the same either way)', () {
      final k1 = CacheDb.keyFor(RoundKind.twoTeam, 'Monaco', 'Galatasaray');
      final k2 = CacheDb.keyFor(RoundKind.twoTeam, 'Galatasaray', 'Monaco');
      expect(k1, k2);
    });

    test('teamCountry keeps order (club and country are not interchangeable)', () {
      final k1 = CacheDb.keyFor(RoundKind.teamCountry, 'Monaco', 'France');
      final k2 = CacheDb.keyFor(RoundKind.teamCountry, 'France', 'Monaco');
      expect(k1, isNot(equals(k2)));
    });
  });

  group('answer cache', () {
    test('miss returns null', () async {
      expect(await cache.getAnswer('nope'), isNull);
    });

    test('put then get round-trips the result', () async {
      const result = AnswerResult(['Radamel Falcao', 'Wilfried Singo'], verified: true);
      await cache.putAnswer('k1', 'Monaco', 'Galatasaray', result);
      final got = await cache.getAnswer('k1');
      expect(got, isNotNull);
      expect(got!.players, result.players);
      expect(got.verified, isTrue);
    });

    test('an unverified result round-trips its flag too', () async {
      const result = AnswerResult(['Some Player'], verified: false);
      await cache.putAnswer('k2', 'A', 'B', result);
      final got = await cache.getAnswer('k2');
      expect(got!.verified, isFalse);
    });

    test('putAnswer overwrites an existing key rather than duplicating it', () async {
      await cache.putAnswer('k3', 'A', 'B', const AnswerResult(['Old'], verified: true));
      await cache.putAnswer('k3', 'A', 'B', const AnswerResult(['New'], verified: true));
      final got = await cache.getAnswer('k3');
      expect(got!.players, ['New']);
    });
  });

  group('board buffer', () {
    Board board(String rowValue) => Board(
          rows: [
            Factor(type: FactorType.team, label: 'Played for $rowValue', value: rowValue),
            const Factor(type: FactorType.team, label: 'Played for Chelsea', value: 'Chelsea'),
            const Factor(type: FactorType.team, label: 'Played for Roma', value: 'Roma'),
          ],
          columns: [
            const Factor(type: FactorType.nationality, label: 'France', value: 'France'),
            const Factor(type: FactorType.nationality, label: 'Brazil', value: 'Brazil'),
            const Factor(type: FactorType.nationality, label: 'Spain', value: 'Spain'),
          ],
          cellExamples: List.generate(9, (_) => const []),
        );

    test('takeBufferedBoard returns null when empty', () async {
      expect(await cache.takeBufferedBoard(), isNull);
    });

    test('pushBoard then takeBufferedBoard round-trips and is FIFO', () async {
      await cache.pushBoard(board('Arsenal'));
      await cache.pushBoard(board('Liverpool'));
      expect(await cache.bufferedBoardCount(), 2);

      final first = await cache.takeBufferedBoard();
      expect(first!.rows.first.value, 'Arsenal');
      expect(await cache.bufferedBoardCount(), 1);

      final second = await cache.takeBufferedBoard();
      expect(second!.rows.first.value, 'Liverpool');
      expect(await cache.bufferedBoardCount(), 0);
    });
  });

  group('round buffer', () {
    Round round(RoundKind kind, String a) => Round(
          kind: kind,
          conditionA: a,
          conditionB: 'Galatasaray',
          answers: const AnswerResult(['Someone'], verified: true),
        );

    test('rounds are scoped by kind', () async {
      await cache.pushRound(round(RoundKind.twoTeam, 'Monaco'));
      await cache.pushRound(round(RoundKind.teamCountry, 'Arsenal'));

      expect(await cache.bufferedRoundCount(RoundKind.twoTeam), 1);
      expect(await cache.bufferedRoundCount(RoundKind.teamCountry), 1);

      final twoTeam = await cache.takeBufferedRound(RoundKind.twoTeam);
      expect(twoTeam!.conditionA, 'Monaco');
      expect(await cache.bufferedRoundCount(RoundKind.teamCountry), 1);
    });
  });
}
