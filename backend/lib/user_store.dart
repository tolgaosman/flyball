import 'dart:io';

import 'package:flyball_core/flyball_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A stored account plus its password hash — only ever used inside the
/// backend to check a login; [user] is what gets sent to the app.
class StoredAccount {
  const StoredAccount(this.user, this.passwordHash);
  final AccountUser user;
  final String passwordHash;
}

/// SQLite store for accounts and their login sessions.
///
/// Deliberately a separate database file from [CacheDb]: the cache is
/// disposable (every row expires and can be rebuilt from Gemini), accounts
/// are not — wiping one must never touch the other.
class UserStore {
  UserStore(this._path);

  final String _path;
  late Database _db;

  Future<void> open() async {
    await Directory(File(_path).parent.path).create(recursive: true);
    sqfliteFfiInit();
    _db = await databaseFactoryFfi.openDatabase(
      _path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE users(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL UNIQUE COLLATE NOCASE,
              display_name TEXT NOT NULL,
              password_hash TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          // Only a SHA-256 of each token is stored, so a leaked database
          // can't be replayed as live sessions.
          await db.execute('''
            CREATE TABLE sessions(
              token_hash TEXT PRIMARY KEY,
              user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
              created_at INTEGER NOT NULL,
              expires_at INTEGER NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX sessions_user ON sessions(user_id)');
        },
      ),
    );
  }

  Future<void> close() => _db.close();

  // ─── Users ──────────────────────────────────────────────────────────────

  /// Inserts a new account, or returns `null` if [username] is already taken
  /// (case-insensitively).
  Future<AccountUser?> createUser({
    required String username,
    required String displayName,
    required String passwordHash,
    required DateTime now,
  }) async {
    try {
      final id = await _db.insert('users', {
        'username': username,
        'display_name': displayName,
        'password_hash': passwordHash,
        'created_at': now.millisecondsSinceEpoch,
      });
      return AccountUser(
        id: id,
        username: username,
        displayName: displayName,
        createdAt: now.toUtc(),
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return null;
      rethrow;
    }
  }

  Future<StoredAccount?> findByUsername(String username) async {
    final rows = await _db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return StoredAccount(_userFromRow(rows.first), rows.first['password_hash'] as String);
  }

  static AccountUser _userFromRow(Map<String, Object?> row) => AccountUser(
        id: row['id'] as int,
        username: row['username'] as String,
        displayName: row['display_name'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
          isUtc: true,
        ),
      );

  // ─── Sessions ───────────────────────────────────────────────────────────

  Future<void> createSession({
    required String tokenHash,
    required int userId,
    required DateTime now,
    required DateTime expiresAt,
  }) async {
    await _db.insert('sessions', {
      'token_hash': tokenHash,
      'user_id': userId,
      'created_at': now.millisecondsSinceEpoch,
      'expires_at': expiresAt.millisecondsSinceEpoch,
    });
  }

  /// The account a live session belongs to, or `null` if the session is
  /// unknown or expired (an expired one is deleted on the way out).
  Future<AccountUser?> userForSession(String tokenHash, DateTime now) async {
    final rows = await _db.rawQuery('''
      SELECT u.*, s.expires_at AS session_expires_at
      FROM sessions s JOIN users u ON u.id = s.user_id
      WHERE s.token_hash = ?
      LIMIT 1
    ''', [tokenHash]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    if ((row['session_expires_at'] as int) <= now.millisecondsSinceEpoch) {
      await deleteSession(tokenHash);
      return null;
    }
    return _userFromRow(row);
  }

  Future<void> deleteSession(String tokenHash) async {
    await _db.delete('sessions', where: 'token_hash = ?', whereArgs: [tokenHash]);
  }

  /// Drops every expired session. Cheap; called on each new login.
  Future<void> purgeExpiredSessions(DateTime now) async {
    await _db.delete(
      'sessions',
      where: 'expires_at <= ?',
      whereArgs: [now.millisecondsSinceEpoch],
    );
  }
}
