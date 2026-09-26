import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flyball_core/flyball_core.dart';

import 'password_hasher.dart';
import 'user_store.dart';

/// A rejected auth request. [code] is one of [AccountErrors]; [status] is
/// the HTTP status the route should answer with.
class AuthException implements Exception {
  const AuthException(this.code, this.status);
  final String code;
  final int status;

  @override
  String toString() => 'AuthException($code, $status)';
}

/// A freshly issued login: the bearer [token] the app sends back as
/// `Authorization: Bearer <token>`, and the account it belongs to.
class AuthSession {
  const AuthSession(this.token, this.user);
  final String token;
  final AccountUser user;

  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};
}

/// Sign-up, login, logout and token lookup. All the rules live here so the
/// HTTP layer ([AuthRoutes]) stays a thin JSON adapter.
class AuthService {
  AuthService({
    required UserStore store,
    PasswordHasher hasher = const PasswordHasher(),
    DateTime Function()? clock,
    this.sessionTtl = const Duration(days: 90),
    this.maxFailedLogins = 5,
    this.failedLoginWindow = const Duration(minutes: 15),
  })  : _store = store,
        _hasher = hasher,
        _clock = clock ?? DateTime.now;

  final UserStore _store;
  final PasswordHasher _hasher;
  final DateTime Function() _clock;
  final Duration sessionTtl;

  /// After this many wrong passwords for one username inside
  /// [failedLoginWindow], further attempts are refused until the window
  /// passes — a simple brake on password guessing.
  final int maxFailedLogins;
  final Duration failedLoginWindow;

  /// Recent failed-login times per lower-cased username. In memory only: a
  /// restart forgets them, which is acceptable for a brake, not a lock.
  final Map<String, List<DateTime>> _failedLogins = {};

  static final _random = Random.secure();

  Future<AuthSession> register({
    required String username,
    required String password,
    String? displayName,
  }) async {
    username = username.trim();
    final name = (displayName ?? '').trim().isEmpty ? username : displayName!.trim();
    final error = AccountRules.validateUsername(username) ??
        AccountRules.validatePassword(password) ??
        AccountRules.validateDisplayName(name);
    if (error != null) throw AuthException(error, 400);

    final user = await _store.createUser(
      username: username,
      displayName: name,
      passwordHash: _hasher.hash(password),
      now: _clock(),
    );
    if (user == null) throw const AuthException(AccountErrors.usernameTaken, 409);
    return _issueSession(user);
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    username = username.trim();
    final key = username.toLowerCase();
    final now = _clock();
    final recent = (_failedLogins[key] ?? const <DateTime>[])
        .where((t) => now.difference(t) < failedLoginWindow)
        .toList();
    if (recent.length >= maxFailedLogins) {
      throw const AuthException(AccountErrors.tooManyAttempts, 429);
    }

    final stored = await _store.findByUsername(username);
    if (stored == null || !_hasher.verify(password, stored.passwordHash)) {
      _failedLogins[key] = [...recent, now];
      // Same error for "no such user" and "wrong password", so a login
      // attempt can't be used to probe which usernames exist.
      throw const AuthException(AccountErrors.invalidCredentials, 401);
    }

    _failedLogins.remove(key);
    await _store.purgeExpiredSessions(now);
    return _issueSession(stored.user);
  }

  /// The account behind a bearer [token], or `null` if it's unknown/expired.
  Future<AccountUser?> userForToken(String token) =>
      _store.userForSession(_hashToken(token), _clock());

  Future<void> logout(String token) => _store.deleteSession(_hashToken(token));

  Future<AuthSession> _issueSession(AccountUser user) async {
    final token = base64Url
        .encode(List.generate(32, (_) => _random.nextInt(256)))
        .replaceAll('=', '');
    final now = _clock();
    await _store.createSession(
      tokenHash: _hashToken(token),
      userId: user.id,
      now: now,
      expiresAt: now.add(sessionTtl),
    );
    return AuthSession(token, user);
  }

  static String _hashToken(String token) => sha256.convert(utf8.encode(token)).toString();
}
