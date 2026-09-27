import 'dart:convert';

import 'package:flyball_core/flyball_core.dart';
import 'package:http/http.dart' as http;

import 'ai_exceptions.dart';
import 'ai_gateway.dart';

/// Talks to the Flyball backend (`backend/`), which holds the Gemini key
/// server-side and caches/pre-buffers rounds & boards. This is the
/// recommended, production-safe [AiGateway].
class BackendAiGateway implements AiGateway {
  BackendAiGateway({required String baseUrl, http.Client? client})
      : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  /// Answer searches make up to two sequential Gemini calls server-side.
  static const _answerTimeout = Duration(seconds: 35);

  /// Board/round builds can make several Gemini calls server-side when a
  /// buffer is empty and it has to build one live.
  static const _buildTimeout = Duration(seconds: 45);

  @override
  Future<AnswerResult?> searchTwoTeam(String teamA, String teamB) =>
      _postAnswers({'kind': 'two_team', 'a': teamA, 'b': teamB});

  @override
  Future<AnswerResult?> searchTeamCountry(String team, String country) =>
      _postAnswers({'kind': 'team_country', 'a': team, 'b': country});

  @override
  Future<AnswerResult?> searchFactors(String condition1, String condition2) =>
      _postAnswers({'kind': 'xox', 'a': condition1, 'b': condition2});

  @override
  Future<Round?> nextTwoTeamRound() async {
    final json = await _getJson('/api/rounds/two-team', _buildTimeout);
    return json == null ? null : Round.fromJson(json);
  }

  @override
  Future<Round?> nextTeamCountryRound() async {
    final json = await _getJson('/api/rounds/team-country', _buildTimeout);
    return json == null ? null : Round.fromJson(json);
  }

  @override
  Future<Board?> nextBoard() async {
    final json = await _getJson('/api/xox/board', _buildTimeout);
    return json == null ? null : Board.fromJson(json);
  }

  Future<AnswerResult?> _postAnswers(Map<String, dynamic> body) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$_baseUrl/api/answers'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_answerTimeout);
      if (res.statusCode == 429) throw const AiUnavailableException.quotaExceeded();
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return null;
      return AnswerResult.fromJson(decoded);
    } on AiUnavailableException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getJson(String path, Duration timeout) async {
    try {
      final res = await _client.get(Uri.parse('$_baseUrl$path')).timeout(timeout);
      if (res.statusCode == 429) throw const AiUnavailableException.quotaExceeded();
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on AiUnavailableException {
      rethrow;
    } catch (_) {
      return null;
    }
  }
}
