import 'dart:async';
import 'dart:convert';

import 'package:flyball_core/flyball_core.dart';
import 'package:http/http.dart' as http;

/// A failed account request. [code] is one of [AccountErrors], or
/// [AccountException.network] when the backend couldn't be reached at all.
class AccountException implements Exception {
  const AccountException(this.code);

  static const network = 'network';

  final String code;

  @override
  String toString() => 'AccountException($code)';
}

/// A successful sign-in / sign-up: the bearer token plus its account.
class AuthResult {
  const AuthResult(this.token, this.user);
  final String token;
  final AccountUser user;
}

/// Talks to the backend's `/api/auth/*` routes (see `backend/lib/auth_routes.dart`).
class AccountApi {
  AccountApi({required String baseUrl, http.Client? client})
      : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  static const _timeout = Duration(seconds: 15);

  Future<AuthResult> register({
    required String username,
    required String password,
    String? displayName,
  }) async {
    final json = await _send('POST', '/api/auth/register', body: {
      'username': username,
      'password': password,
      if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
    });
    return _authResult(json);
  }

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final json = await _send('POST', '/api/auth/login', body: {
      'username': username,
      'password': password,
    });
    return _authResult(json);
  }

  /// The account behind [token]. Throws [AccountErrors.unauthorized] if the
  /// session is gone (expired / logged out elsewhere).
  Future<AccountUser> me(String token) async {
    final json = await _send('GET', '/api/auth/me', token: token);
    return AccountUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  /// Ends the session server-side. Best effort — the app forgets the token
  /// locally either way.
  Future<void> logout(String token) async {
    try {
      await _send('POST', '/api/auth/logout', token: token);
    } on AccountException {
      // Already signed out locally; an unreachable server just means the
      // token expires on its own.
    }
  }

  AuthResult _authResult(Map<String, dynamic> json) => AuthResult(
        json['token'] as String,
        AccountUser.fromJson(json['user'] as Map<String, dynamic>),
      );

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'));
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    final http.Response res;
    try {
      res = await http.Response.fromStream(await _client.send(request).timeout(_timeout));
    } on Exception {
      // SocketException, TimeoutException, ClientException, …
      throw const AccountException(AccountException.network);
    }

    if (res.statusCode == 204) return const {};
    Object? decoded;
    try {
      decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    } on FormatException {
      decoded = null;
    }
    final map = decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
    if (res.statusCode >= 200 && res.statusCode < 300) return map;
    throw AccountException(map['error']?.toString() ?? 'http_${res.statusCode}');
  }
}
