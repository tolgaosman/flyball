import 'dart:async';

import 'package:flyball_core/flyball_core.dart';

import 'cache_db.dart';

/// Ties the cache together with the AI engine: every request checks the
/// cache first, collapses concurrent identical requests into one Gemini call
/// (`_inFlight`), and keeps a small buffer of ready-to-serve rounds/boards
/// topped up in the background so the common case is instant.
class AppService {
  AppService({
    required this.cache,
    required this.answerFinder,
    required this.boardBuilder,
    required this.roundPicker,
  });

  final CacheDb cache;
  final AnswerFinder answerFinder;
  final BoardBuilder boardBuilder;
  final RoundPicker roundPicker;

  static const _bufferTarget = 0;

  final Map<String, Future<AnswerResult?>> _inFlightAnswers = {};
  bool _toppingUpRounds = false;
  bool _toppingUpBoards = false;

  /// Players satisfying both conditions for a "2 Team 1 Player" pair.
  Future<AnswerResult?> answersForTwoTeam(String teamA, String teamB) {
    return _answersFor(
      kind: RoundKind.twoTeam,
      cacheA: teamA,
      cacheB: teamB,
      promptCondition1: 'Played for $teamA',
      promptCondition2: 'Played for $teamB',
    );
  }

  /// Players satisfying both conditions for a "1 Team 1 Country" pair.
  Future<AnswerResult?> answersForTeamCountry(String team, String country) {
    return _answersFor(
      kind: RoundKind.teamCountry,
      cacheA: team,
      cacheB: country,
      promptCondition1: 'Played for $team',
      promptCondition2: '$country nationality',
    );
  }

  /// Same-shaped search for an arbitrary XOX cell (row/column factor labels).
  /// Not cached under a (team, country) key since XOX conditions are free-form
  /// factor labels — still deduped against identical concurrent requests.
  Future<AnswerResult?> answersForFactors(String condition1, String condition2) {
    final key = 'xox:$condition1::$condition2';
    return _dedupedSearch(key, condition1, condition2, onFound: null);
  }

  Future<AnswerResult?> _answersFor({
    required RoundKind kind,
    required String cacheA,
    required String cacheB,
    required String promptCondition1,
    required String promptCondition2,
  }) async {
    final key = CacheDb.keyFor(kind, cacheA, cacheB);
    final cached = await cache.getAnswer(key);
    if (cached != null) return cached;
    return _dedupedSearch(
      key,
      promptCondition1,
      promptCondition2,
      onFound: (result) => cache.putAnswer(key, cacheA, cacheB, result),
    );
  }

  Future<AnswerResult?> _dedupedSearch(
    String key,
    String condition1,
    String condition2, {
    required FutureOr<void> Function(AnswerResult result)? onFound,
  }) {
    final existing = _inFlightAnswers[key];
    if (existing != null) return existing;

    final future = answerFinder
        .search(condition1: condition1, condition2: condition2)
        .then((result) async {
      if (result != null && onFound != null) await onFound(result);
      return result;
    });
    _inFlightAnswers[key] = future;
    // `.whenComplete()` opens its own, independent listener branch on
    // `future` — since `future` (returned below) can now throw
    // GeminiQuotaExceededException instead of just resolving to null, that
    // branch needs its own error handling too, or Dart reports it as an
    // unhandled async error even though the caller of `_dedupedSearch`
    // already catches the very same error on the `future` it awaits.
    unawaited(
      future.whenComplete(() => _inFlightAnswers.remove(key)).catchError((_) => null),
    );
    return future;
  }

  /// Serves a buffered round instantly if one is ready, else builds one now
  /// (paying the AI latency directly) — never returns an empty round silently.
  Future<Round?> nextRound(RoundKind kind) async {
    final buffered = await cache.takeBufferedRound(kind);
    _topUpRoundBuffer(kind);
    if (buffered != null) return buffered;
    return kind == RoundKind.twoTeam
        ? roundPicker.nextTwoTeamRound()
        : roundPicker.nextTeamCountryRound();
  }

  Future<Board?> nextBoard() async {
    final buffered = await cache.takeBufferedBoard();
    _topUpBoardBuffer();
    if (buffered != null) return buffered;
    return boardBuilder.buildBoard();
  }

  void _topUpRoundBuffer(RoundKind kind) {
    if (_toppingUpRounds) return;
    _toppingUpRounds = true;
    unawaited(() async {
      try {
        var count = await cache.bufferedRoundCount(kind);
        while (count < _bufferTarget) {
          final round = kind == RoundKind.twoTeam
              ? await roundPicker.nextTwoTeamRound()
              : await roundPicker.nextTeamCountryRound();
          if (round == null) break; // AI unreachable — stop, don't spin.
          await cache.pushRound(round);
          count++;
        }
      } on GeminiQuotaExceededException {
        // Quota exhausted — stop, don't spin (same as a null result above).
      } finally {
        _toppingUpRounds = false;
      }
    }());
  }

  void _topUpBoardBuffer() {
    if (_toppingUpBoards) return;
    _toppingUpBoards = true;
    unawaited(() async {
      try {
        var count = await cache.bufferedBoardCount();
        while (count < _bufferTarget) {
          final board = await boardBuilder.buildBoard();
          if (board == null) break;
          await cache.pushBoard(board);
          count++;
        }
      } on GeminiQuotaExceededException {
        // Quota exhausted — stop, don't spin (same as a null result above).
      } finally {
        _toppingUpBoards = false;
      }
    }());
  }
}
