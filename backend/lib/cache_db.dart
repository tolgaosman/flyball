import 'dart:convert';
import 'dart:io';

import 'package:flyball_core/flyball_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// SQLite-backed cache so repeat questions are instant and don't re-spend
/// Gemini quota, and so a couple of rounds/boards are always sitting ready for
/// the frontend to serve instantly while the next one builds in the
/// background.
///
/// This is a CACHE, not a corpus: every row here was written from a live
/// Gemini answer, and it expires. There is no bundled/static player data.
class CacheDb {
  CacheDb(this._path);

  final String _path;
  late Database _db;

  Future<void> open() async {
    await Directory(File(_path).parent.path).create(recursive: true);
    sqfliteFfiInit();
    _db = await databaseFactoryFfi.openDatabase(
      _path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE answer_cache(
              cache_key TEXT PRIMARY KEY,
              cond_a TEXT NOT NULL,
              cond_b TEXT NOT NULL,
              players_json TEXT NOT NULL,
              verified INTEGER NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE boards(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              board_json TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE rounds(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              kind TEXT NOT NULL,
              round_json TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
  }

  Future<void> close() => _db.close();

  // ─── Answer cache ───────────────────────────────────────────────────────

  /// Normalizes a (kind, conditionA, conditionB) triple into one cache key.
  /// For `twoTeam` the two conditions are interchangeable (club A × club B
  /// reads the same either way round), so they're sorted first to double the
  /// cache hit rate; `teamCountry` keeps its order since the roles differ.
  static String keyFor(RoundKind kind, String conditionA, String conditionB) {
    if (kind == RoundKind.twoTeam) {
      final sorted = [conditionA, conditionB]..sort();
      return 'twoTeam:${sorted[0]}::${sorted[1]}';
    }
    return 'teamCountry:$conditionA::$conditionB';
  }

  /// How long a cached answer stays valid. Shorter during the two transfer
  /// windows (new signings change who "played for" a club).
  static Duration ttlFor(DateTime now) {
    final inWindow = (now.month == 1 || now.month == 2) ||
        (now.month >= 6 && now.month <= 9);
    return inWindow ? const Duration(days: 2) : const Duration(days: 7);
  }

  Future<AnswerResult?> getAnswer(String cacheKey) async {
    final rows = await _db.query(
      'answer_cache',
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int);
    if (DateTime.now().difference(createdAt) > ttlFor(DateTime.now())) {
      await _db.delete('answer_cache', where: 'cache_key = ?', whereArgs: [cacheKey]);
      return null;
    }
    final players = (jsonDecode(row['players_json'] as String) as List)
        .map((e) => e.toString())
        .toList();
    return AnswerResult(players, verified: (row['verified'] as int) == 1);
  }

  Future<void> putAnswer(
    String cacheKey,
    String conditionA,
    String conditionB,
    AnswerResult result,
  ) async {
    await _db.insert(
      'answer_cache',
      {
        'cache_key': cacheKey,
        'cond_a': conditionA,
        'cond_b': conditionB,
        'players_json': jsonEncode(result.players),
        'verified': result.verified ? 1 : 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Board / round buffers ──────────────────────────────────────────────

  /// Pops the oldest buffered board (FIFO), or null if none is ready.
  Future<Board?> takeBufferedBoard() async {
    final rows = await _db.query('boards', orderBy: 'id ASC', limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    await _db.delete('boards', where: 'id = ?', whereArgs: [row['id']]);
    return Board.fromJson(jsonDecode(row['board_json'] as String));
  }

  Future<int> bufferedBoardCount() async {
    final rows = await _db.rawQuery('SELECT COUNT(*) AS c FROM boards');
    return rows.first['c'] as int;
  }

  Future<void> pushBoard(Board board) async {
    await _db.insert('boards', {
      'board_json': jsonEncode(board.toJson()),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Round?> takeBufferedRound(RoundKind kind) async {
    final rows = await _db.query(
      'rounds',
      where: 'kind = ?',
      whereArgs: [kind.name],
      orderBy: 'id ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    await _db.delete('rounds', where: 'id = ?', whereArgs: [row['id']]);
    return Round.fromJson(jsonDecode(row['round_json'] as String));
  }

  Future<int> bufferedRoundCount(RoundKind kind) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM rounds WHERE kind = ?',
      [kind.name],
    );
    return rows.first['c'] as int;
  }

  Future<void> pushRound(Round round) async {
    await _db.insert('rounds', {
      'kind': round.kind.name,
      'round_json': jsonEncode(round.toJson()),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
