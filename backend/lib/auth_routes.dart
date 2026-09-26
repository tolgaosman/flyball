import 'package:flyball_core/flyball_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth_service.dart';
import 'http_json.dart';

/// HTTP adapter over [AuthService]:
///
/// - `POST /api/auth/register` — `{"username", "password", "displayName"?}` → `{"token", "user"}` (201)
/// - `POST /api/auth/login`    — `{"username", "password"}` → `{"token", "user"}`
/// - `POST /api/auth/logout`   — bearer token → 204
/// - `GET  /api/auth/me`       — bearer token → `{"user"}`
///
/// Errors are `{"error": <AccountErrors code>}` with a matching status.
class AuthRoutes {
  AuthRoutes(this._auth);

  final AuthService _auth;

  void mount(Router router) {
    router
      ..post('/api/auth/register', _register)
      ..post('/api/auth/login', _login)
      ..post('/api/auth/logout', _logout)
      ..get('/api/auth/me', _me);
  }

  /// The signed-in account for [request], or `null` if it has no valid
  /// bearer token. For any future endpoint that needs to know who's asking.
  Future<AccountUser?> userFor(Request request) async {
    final token = bearerToken(request);
    return token == null ? null : _auth.userForToken(token);
  }

  static String? bearerToken(Request request) {
    final header = request.headers['authorization'];
    if (header == null || !header.startsWith('Bearer ')) return null;
    final token = header.substring(7).trim();
    return token.isEmpty ? null : token;
  }

  Future<Response> _register(Request request) async {
    final body = await readJsonBody(request);
    if (body == null) return errorResponse('invalid_json_body');
    return _run(() async {
      final session = await _auth.register(
        username: body['username']?.toString() ?? '',
        password: body['password']?.toString() ?? '',
        displayName: body['displayName']?.toString(),
      );
      return jsonResponse(session.toJson(), status: 201);
    });
  }

  Future<Response> _login(Request request) async {
    final body = await readJsonBody(request);
    if (body == null) return errorResponse('invalid_json_body');
    return _run(() async {
      final session = await _auth.login(
        username: body['username']?.toString() ?? '',
        password: body['password']?.toString() ?? '',
      );
      return jsonResponse(session.toJson());
    });
  }

  Future<Response> _logout(Request request) async {
    final token = bearerToken(request);
    if (token != null) await _auth.logout(token);
    return Response(204);
  }

  Future<Response> _me(Request request) async {
    final user = await userFor(request);
    if (user == null) {
      return errorResponse(AccountErrors.unauthorized, status: 401);
    }
    return jsonResponse({'user': user.toJson()});
  }

  static Future<Response> _run(Future<Response> Function() action) async {
    try {
      return await action();
    } on AuthException catch (e) {
      return errorResponse(e.code, status: e.status);
    }
  }
}
