import 'package:flyball_core/flyball_core.dart';

import 'ai_exceptions.dart';
import 'ai_gateway.dart';

/// Calls Gemini directly from the device using a compiled-in API key — no
/// backend server needed, but the key is extractable from the app binary.
/// Fine for personal/local use (see [AppConfig.aiMode]).
class DirectAiGateway implements AiGateway {
  DirectAiGateway({required String apiKey, required String model})
      : _answerFinder = AnswerFinder(
          DirectGeminiTransport(GeminiConfig(model: model, apiKey: apiKey)),
        ),
        _boardBuilder = BoardBuilder(
          DirectGeminiTransport(GeminiConfig(model: model, apiKey: apiKey)),
        ) {
    _roundPicker = RoundPicker(_answerFinder);
  }

  final AnswerFinder _answerFinder;
  final BoardBuilder _boardBuilder;
  late final RoundPicker _roundPicker;

  @override
  Future<AnswerResult?> searchTwoTeam(String teamA, String teamB) => _guard(
        () => _answerFinder.search(
          condition1: 'Played for $teamA',
          condition2: 'Played for $teamB',
        ),
      );

  @override
  Future<AnswerResult?> searchTeamCountry(String team, String country) => _guard(
        () => _answerFinder.search(
          condition1: 'Played for $team',
          condition2: '$country nationality',
        ),
      );

  @override
  Future<AnswerResult?> searchFactors(String condition1, String condition2) => _guard(
        () => _answerFinder.search(condition1: condition1, condition2: condition2),
      );

  @override
  Future<Round?> nextTwoTeamRound() => _guard(_roundPicker.nextTwoTeamRound);

  @override
  Future<Round?> nextTeamCountryRound() => _guard(_roundPicker.nextTeamCountryRound);

  @override
  Future<Board?> nextBoard() => _guard(_boardBuilder.buildBoard);

  /// Converts flyball_core's [GeminiQuotaExceededException] into the
  /// frontend's own [AiUnavailableException] so every AI-backed screen can
  /// keep catching the one exception type. Every other failure mode is
  /// unaffected — it still just returns `null`, as before.
  Future<T?> _guard<T>(Future<T?> Function() call) async {
    try {
      return await call();
    } on GeminiQuotaExceededException {
      throw const AiUnavailableException.quotaExceeded();
    }
  }
}
