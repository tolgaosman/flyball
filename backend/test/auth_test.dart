import 'dart:convert';
import 'dart:io';

import 'package:backend/auth_routes.dart';
import 'package:backend/auth_service.dart';
import 'package:backend/password_hasher.dart';
import 'package:backend/user_store.dart';
import 'package:flyball_core/flyball_core.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late UserStore store;
  late DateTime now;
  late AuthService auth;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('flyball_auth_test_');
    store = UserStore(p.join(tempDir.path, 'users.db'));
    await store.open();
    now = DateTime.utc(2026, 9, 26, 12);
    auth = AuthService(
      store: store,
      // Real PBKDF2, just fewer rounds so the suite stays fast.
      hasher: const PasswordHasher(iterations: 1000),
      clock: () => now,
    );
  });

  tearDown(() async {
    await store.close();
    await tempDir.delete(recursive: true);
  });

  group('PasswordHasher', () {
    const hasher = PasswordHasher(iterations: 1000);

    test('verifies the right password and rejects a wrong one', () {
      final encoded = hasher.hash('correct horse');
      expect(hasher.verify('correct horse', encoded), isTrue);
      expect(hasher.verify('wrong horse', encoded), isFalse);
    });

    test('salts every hash', () {
      expect(hasher.hash('same'), isNot(equals(hasher.hash('same'))));
    });

    test('rejects malformed hashes instead of throwing', () {
      expect(hasher.verify('x', 'garbage'), isFalse);
      expect(hasher.verify('x', r'pbkdf2_sha256$abc$AA==$AA=='), isFalse);
      expect(hasher.verify('x', r'pbkdf2_sha256$10$!!$!!'), isFalse);
    });
  });

  group('AuthService', () {
    test('register issues a working session, display name defaults to username', () async {
      final session = await auth.register(username: 'osman', password: 'password1');
      expect(session.user.displayName, 'osman');
      final me = await auth.userForToken(session.token);
      expect(me?.id, session.user.id);
    });

    test('usernames are unique case-insensitively', () async {
      await auth.register(username: 'Osman', password: 'password1');
      expect(
        () => auth.register(username: 'osman', password: 'password2'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AccountErrors.usernameTaken)),
      );
    });

    test('register enforces the shared rules', () async {
      expect(
        () => auth.register(username: 'a b', password: 'password1'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AccountErrors.invalidUsername)),
      );
      expect(
        () => auth.register(username: 'osman', password: 'short'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AccountErrors.weakPassword)),
      );
    });

    test('login works with any username casing, and the password is checked', () async {
      await auth.register(username: 'Osman', password: 'password1');
      final session = await auth.login(username: 'OSMAN', password: 'password1');
      expect(session.user.username, 'Osman');
      expect(
        () => auth.login(username: 'osman', password: 'nope-nope'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AccountErrors.invalidCredentials)),
      );
    });

    test('an unknown user gets the same error as a wrong password', () async {
      expect(
        () => auth.login(username: 'ghost', password: 'password1'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AccountErrors.invalidCredentials)),
      );
    });

    test('too many wrong passwords locks the username until the window passes', () async {
      await auth.register(username: 'osman', password: 'password1');
      for (var i = 0; i < 5; i++) {
        await expectLater(auth.login(username: 'osman', password: 'wrong-pass'), throwsA(isA<AuthException>()));
      }
      await expectLater(
        auth.login(username: 'osman', password: 'password1'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AccountErrors.tooManyAttempts)),
      );
      now = now.add(const Duration(minutes: 16));
      final session = await auth.login(username: 'osman', password: 'password1');
      expect(session.user.username, 'osman');
    });

    test('logout kills the session', () async {
      final session = await auth.register(username: 'osman', password: 'password1');
      await auth.logout(session.token);
      expect(await auth.userForToken(session.token), isNull);
    });

    test('sessions expire', () async {
      final session = await auth.register(username: 'osman', password: 'password1');
      now = now.add(const Duration(days: 91));
      expect(await auth.userForToken(session.token), isNull);
    });
  });

  group('AuthRoutes', () {
    late Handler handler;

    setUp(() {
      final router = Router();
      AuthRoutes(auth).mount(router);
      handler = router.call;
    });

    Future<Response> post(String path, Object body, {String? token}) async => handler(Request(
          'POST',
          Uri.parse('http://localhost$path'),
          body: jsonEncode(body),
          headers: {if (token != null) 'authorization': 'Bearer $token'},
        ));

    Future<Map<String, dynamic>> json(Response r) async =>
        jsonDecode(await r.readAsString()) as Map<String, dynamic>;

    test('register → me → logout → me', () async {
      final reg = await post('/api/auth/register', {'username': 'osman', 'password': 'password1', 'displayName': 'Osman'});
      expect(reg.statusCode, 201);
      final body = await json(reg);
      final token = body['token'] as String;
      expect(AccountUser.fromJson(body['user']).displayName, 'Osman');

      final me = await handler(Request('GET', Uri.parse('http://localhost/api/auth/me'),
          headers: {'authorization': 'Bearer $token'}));
      expect(me.statusCode, 200);
      expect((await json(me))['user']['username'], 'osman');

      final out = await post('/api/auth/logout', const {}, token: token);
      expect(out.statusCode, 204);

      final after = await handler(Request('GET', Uri.parse('http://localhost/api/auth/me'),
          headers: {'authorization': 'Bearer $token'}));
      expect(after.statusCode, 401);
    });

    test('errors come back as {"error": code} with the right status', () async {
      await post('/api/auth/register', {'username': 'osman', 'password': 'password1'});
      final dup = await post('/api/auth/register', {'username': 'osman', 'password': 'password1'});
      expect(dup.statusCode, 409);
      expect((await json(dup))['error'], AccountErrors.usernameTaken);

      final bad = await post('/api/auth/login', {'username': 'osman', 'password': 'wrong-pass'});
      expect(bad.statusCode, 401);
      expect((await json(bad))['error'], AccountErrors.invalidCredentials);
    });

    test('me without a token is 401', () async {
      final r = await handler(Request('GET', Uri.parse('http://localhost/api/auth/me')));
      expect(r.statusCode, 401);
    });
  });
}
