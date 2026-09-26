import 'package:flyball_core/flyball_core.dart';

import 'ai_gateway.dart';

/// Used when neither a backend URL nor a Gemini key is configured. Every call
/// returns `null` immediately so the UI shows its "AI not configured" state
/// right away instead of waiting out a timeout.
class NoAiGateway implements AiGateway {
  const NoAiGateway();

  @override
  Future<AnswerResult?> searchTwoTeam(String teamA, String teamB) async => null;

  @override
  Future<AnswerResult?> searchTeamCountry(String team, String country) async =>
      null;

  @override
  Future<AnswerResult?> searchFactors(String condition1, String condition2) async =>
      null;

  @override
  Future<Round?> nextTwoTeamRound() async => null;

  @override
  Future<Round?> nextTeamCountryRound() async => null;

  @override
  Future<Board?> nextBoard() async => null;
}
