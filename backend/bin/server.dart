import 'dart:io';

import 'package:flyball_core/flyball_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import '../lib/app_service.dart';
import '../lib/auth_routes.dart';
import '../lib/auth_service.dart';
import '../lib/cache_db.dart';
import '../lib/env_config.dart';
import '../lib/http_json.dart';
import '../lib/user_store.dart';

late AppService _service;
late EnvConfig _config;

Response _healthHandler(Request request) =>
    jsonResponse({'status': 'ok', 'aiConfigured': _config.hasGeminiKey});

/// `POST /api/answers` — `{"kind": "two_team"|"team_country"|"xox", "a": ..., "b": ...}`.
Future<Response> _answersHandler(Request request) async {
  final body = await readJsonBody(request);
  if (body == null) return errorResponse('invalid_json_body');

  final kind = body['kind']?.toString();
  final a = body['a']?.toString();
  final b = body['b']?.toString();
  if (a == null || a.isEmpty || b == null || b.isEmpty) {
    return errorResponse('missing "a" or "b"');
  }

  final AnswerResult? result;
  switch (kind) {
    case 'two_team':
      result = await _service.answersForTwoTeam(a, b);
    case 'team_country':
      result = await _service.answersForTeamCountry(a, b);
    case 'xox':
      result = await _service.answersForFactors(a, b);
    default:
      return errorResponse('invalid "kind" (expected two_team | team_country | xox)');
  }

  if (result == null) {
    return errorResponse('AI search failed — try again', status: 502);
  }
  return jsonResponse(result.toJson());
}

Future<Response> _twoTeamRoundHandler(Request request) async {
  final round = await _service.nextRound(RoundKind.twoTeam);
  if (round == null) return errorResponse('AI unreachable — try again', status: 502);
  return jsonResponse(round.toJson());
}

Future<Response> _teamCountryRoundHandler(Request request) async {
  final round = await _service.nextRound(RoundKind.teamCountry);
  if (round == null) return errorResponse('AI unreachable — try again', status: 502);
  return jsonResponse(round.toJson());
}

Future<Response> _xoxBoardHandler(Request request) async {
  final board = await _service.nextBoard();
  if (board == null) return errorResponse('AI unreachable — try again', status: 502);
  return jsonResponse(board.toJson());
}

void main(List<String> args) async {
  _config = EnvConfig.fromEnvironment();
  if (!_config.hasGeminiKey) {
    stderr.writeln(
      'WARNING: GEMINI_API_KEY is not set. Every AI request will fail with '
      '502 until it is provided (see backend/.env.example).',
    );
  }

  final cache = CacheDb(_config.cacheDbPath);
  await cache.open();

  final transport = DirectGeminiTransport(
    GeminiConfig(model: _config.geminiModel, apiKey: _config.geminiApiKey),
  );
  final answerFinder = AnswerFinder(transport);
  _service = AppService(
    cache: cache,
    answerFinder: answerFinder,
    boardBuilder: BoardBuilder(transport),
    roundPicker: RoundPicker(answerFinder),
  );

  final users = UserStore(_config.userDbPath);
  await users.open();
  final authRoutes = AuthRoutes(AuthService(store: users));

  final router = Router()
    ..get('/health', _healthHandler)
    ..post('/api/answers', _answersHandler)
    ..get('/api/rounds/two-team', _twoTeamRoundHandler)
    ..get('/api/rounds/team-country', _teamCountryRoundHandler)
    ..get('/api/xox/board', _xoxBoardHandler);
  authRoutes.mount(router);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  final port = _config.port;
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  print('Flyball backend listening on port ${server.port} '
      '(AI configured: ${_config.hasGeminiKey})');
}
