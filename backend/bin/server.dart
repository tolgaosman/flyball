import 'dart:io';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../lib/game/xox/factor_pool.dart';
import '../lib/game/xox/factor.dart';
import '../lib/data/sqlite_player_repository.dart';
import '../lib/data/player_database.dart';

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/api/xox/generate-board', _generateBoardHandler);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Map<String, dynamic> _factorToJson(Factor f) => {
  'type': f.type.toString(),
  'label': f.label,
  'value': f.value,
};

Future<Response> _generateBoardHandler(Request request) async {
  // Initialize FFI for SQLite on desktop/server.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  // Create repository and load corpus.
  final db = PlayerDatabase();
  await db.init();
  final repo = SqlitePlayerRepository(db);
  final players = await repo.getAllPlayers();
  
  final board = FactorPool.generateBoard(null, players);
  
  final jsonResp = {
    'rows': board.rows.map(_factorToJson).toList(),
    'columns': board.columns.map(_factorToJson).toList(),
  };
  
  return Response.ok(jsonEncode(jsonResp), headers: {'content-type': 'application/json'});
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
