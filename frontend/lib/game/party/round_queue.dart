import 'package:flyball_core/flyball_core.dart';

import '../../data/ai/ai_exceptions.dart';
import '../../data/ai/ai_gateway.dart';

/// Keeps one party-game [Round] pre-fetched ahead of the one on screen, so
/// tapping "New Teams"/"New Round" almost always lands instantly instead of
/// waiting on a fresh AI round-trip. Backed by [AiGateway.nextTwoTeamRound] /
/// [AiGateway.nextTeamCountryRound], which are themselves served from the
/// backend's own buffer when one is configured.
class RoundQueue {
  RoundQueue({required this.aiGateway, required this.kind});

  final AiGateway aiGateway;
  final RoundKind kind;

  Round? _buffered;
  Future<Round?>? _prefetching;

  /// Returns the next round — the buffered one if ready, else fetches now
  /// (paying the latency directly). Returns `null` if the AI is unreachable.
  Future<Round?> next() async {
    final buffered = _buffered;
    _buffered = null;
    final round = buffered ?? await _fetch();
    _topUp();
    return round;
  }

  Future<Round?> _fetch() => kind == RoundKind.twoTeam
      ? aiGateway.nextTwoTeamRound()
      : aiGateway.nextTeamCountryRound();

  void _topUp() {
    if (_buffered != null || _prefetching != null) return;
    _prefetching = _fetch().then((round) {
      _buffered = round;
      return round;
    }).catchError((Object _) {
      // Background prefetch — nothing to show a retry UI to. Treat the same
      // as a `null` result: leave `_buffered` unset and let the next
      // foreground `next()` call surface the real error.
      return null;
    }, test: (e) => e is AiUnavailableException).whenComplete(() => _prefetching = null);
  }
}
