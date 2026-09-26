import 'dart:math';

import '../catalog/clubs.dart';
import '../catalog/countries.dart';
import '../model/round.dart';
import 'answer_finder.dart';

/// Picks a ready-to-play party-game round: a random pair of clubs (or a club
/// + nationality), pre-verified by [AnswerFinder] so revealing the answer is
/// instant. Retries a bounded number of times if a draw comes back with no
/// confirmed players, weighting toward same-league pairs (which share far
/// more players and so are more likely to have a real answer).
///
/// Returns `null` only when every attempt failed at the transport level (AI
/// unreachable) — the caller should show an error/retry state, never a
/// silent empty round.
class RoundPicker {
  RoundPicker(this._answerFinder);

  final AnswerFinder _answerFinder;

  static const _maxAttempts = 4;

  /// A "2 Team 1 Player" round: two distinct clubs plus a footballer who
  /// played for both.
  Future<Round?> nextTwoTeamRound({Random? random}) async {
    final rng = random ?? Random();
    Round? unverifiedFallback;

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final pair = _pickClubPair(rng);
      final result = await _answerFinder.search(
        condition1: 'Played for ${pair.$1}',
        condition2: 'Played for ${pair.$2}',
      );
      if (result == null) continue; // transport failure — try another draw.
      if (result.players.isNotEmpty) {
        return Round(
          kind: RoundKind.twoTeam,
          conditionA: pair.$1,
          conditionB: pair.$2,
          answers: result,
        );
      }
      unverifiedFallback ??= Round(
        kind: RoundKind.twoTeam,
        conditionA: pair.$1,
        conditionB: pair.$2,
        answers: result,
      );
    }
    return unverifiedFallback;
  }

  /// A "1 Team 1 Country" round: a club plus a nationality plus a footballer
  /// of that nationality who played for that club.
  Future<Round?> nextTeamCountryRound({Random? random}) async {
    final rng = random ?? Random();
    Round? unverifiedFallback;

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final club = ClubCatalog.names[rng.nextInt(ClubCatalog.names.length)];
      final country =
          CountryCatalog.names[rng.nextInt(CountryCatalog.names.length)];
      final result = await _answerFinder.search(
        condition1: 'Played for $club',
        condition2: '$country nationality',
      );
      if (result == null) continue;
      if (result.players.isNotEmpty) {
        return Round(
          kind: RoundKind.teamCountry,
          conditionA: club,
          conditionB: country,
          answers: result,
        );
      }
      unverifiedFallback ??= Round(
        kind: RoundKind.teamCountry,
        conditionA: club,
        conditionB: country,
        answers: result,
      );
    }
    return unverifiedFallback;
  }

  /// Draws two distinct clubs, weighted 65% toward a same-league pair (which
  /// tends to share far more players, raising the odds of a rich answer).
  (String, String) _pickClubPair(Random rng) {
    final sameLeague = rng.nextDouble() < 0.65;
    if (sameLeague) {
      final league = ClubCatalog.leagues[rng.nextInt(ClubCatalog.leagues.length)];
      final clubs = ClubCatalog.clubsInLeague(league);
      if (clubs.length >= 2) {
        final shuffled = [...clubs]..shuffle(rng);
        return (shuffled[0].name, shuffled[1].name);
      }
    }
    final all = ClubCatalog.names;
    final a = all[rng.nextInt(all.length)];
    String b;
    do {
      b = all[rng.nextInt(all.length)];
    } while (b == a);
    return (a, b);
  }
}
