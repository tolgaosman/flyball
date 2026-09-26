import 'package:flyball_core/flyball_core.dart';

/// The app's single door to "AI answers something". Every screen goes through
/// this — there is no static player database to fall back to, so a `null`
/// result always means "AI unavailable right now", and the caller must show
/// a real error/retry state rather than silently rendering nothing.
abstract class AiGateway {
  /// Players who played for BOTH clubs.
  Future<AnswerResult?> searchTwoTeam(String teamA, String teamB);

  /// Players of [country] who played for [team].
  Future<AnswerResult?> searchTeamCountry(String team, String country);

  /// Players satisfying two arbitrary XOX factor labels.
  Future<AnswerResult?> searchFactors(String condition1, String condition2);

  /// A ready "2 Team 1 Player" round (clubs pre-verified to have an answer).
  Future<Round?> nextTwoTeamRound();

  /// A ready "1 Team 1 Country" round.
  Future<Round?> nextTeamCountryRound();

  /// A ready, AI-checked Football XOX board.
  Future<Board?> nextBoard();
}
