import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flyball/data/account/account_api.dart';
import 'package:flyball/data/account/session_controller.dart';
import 'package:flyball/l10n/app_localizations.dart';
import 'package:flyball/screens/login_screen.dart';
import 'package:flyball/screens/signup_screen.dart';
import 'package:flyball_core/flyball_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _user = AccountUser(
  id: 1,
  username: 'osman',
  displayName: 'Osman',
  createdAt: DateTime.utc(2026, 9, 26),
);

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

/// A fake backend: `osman` / `password1` is the only valid login and
/// `taken` is the only registered-elsewhere username.
MockClient _fakeBackend({List<http.Request>? log}) => MockClient((request) async {
      log?.add(request);
      final body = request.body.isEmpty ? const {} : jsonDecode(request.body) as Map;
      switch (request.url.path) {
        case '/api/auth/login':
          if (body['username'] == 'osman' && body['password'] == 'password1') {
            return _json({'token': 'tok', 'user': _user.toJson()});
          }
          return _json({'error': AccountErrors.invalidCredentials}, 401);
        case '/api/auth/register':
          if (body['username'] == 'taken') return _json({'error': AccountErrors.usernameTaken}, 409);
          return _json({
            'token': 'tok',
            'user': AccountUser(
              id: 2,
              username: body['username'] as String,
              displayName: (body['displayName'] ?? body['username']) as String,
              createdAt: DateTime.utc(2026, 9, 26),
            ).toJson(),
          }, 201);
        case '/api/auth/me':
          if (request.headers['Authorization'] == 'Bearer tok') return _json({'user': _user.toJson()});
          return _json({'error': AccountErrors.unauthorized}, 401);
        case '/api/auth/logout':
          return http.Response('', 204);
      }
      return http.Response('not found', 404);
    });

SessionController _session({http.Client? client}) => SessionController(
      api: AccountApi(baseUrl: 'http://test', client: client ?? _fakeBackend()),
    );

/// Opens [screen] on top of a placeholder home so a successful pop can be
/// observed.
Widget _app(Widget screen) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen)),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );

Future<void> _open(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(_app(screen));
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(GestureDetector, label).last;
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SessionController', () {
    test('login signs in and persists; restore brings it back', () async {
      final session = _session();
      await session.login(username: 'osman', password: 'password1');
      expect(session.isSignedIn, isTrue);
      expect(session.token, 'tok');

      final restored = _session();
      await restored.restore();
      expect(restored.value?.username, 'osman');
      expect(restored.token, 'tok');
    });

    test('wrong password throws the backend error code', () async {
      final session = _session();
      await expectLater(
        session.login(username: 'osman', password: 'nope-nope'),
        throwsA(isA<AccountException>().having((e) => e.code, 'code', AccountErrors.invalidCredentials)),
      );
      expect(session.isSignedIn, isFalse);
    });

    test('an unreachable server surfaces as a network error', () async {
      final session = _session(client: MockClient((_) async => throw http.ClientException('down')));
      await expectLater(
        session.login(username: 'osman', password: 'password1'),
        throwsA(isA<AccountException>().having((e) => e.code, 'code', AccountException.network)),
      );
    });

    test('a session the server rejects is cleared on refresh', () async {
      SharedPreferences.setMockInitialValues({
        'flyball.session.token': 'stale',
        'flyball.session.user': jsonEncode(_user.toJson()),
      });
      final session = _session();
      await session.restore();
      expect(session.isSignedIn, isTrue, reason: 'cached account shows instantly');
      await session.refresh();
      expect(session.isSignedIn, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('flyball.session.token'), isNull);
    });

    test('an offline refresh keeps the cached account', () async {
      SharedPreferences.setMockInitialValues({
        'flyball.session.token': 'tok',
        'flyball.session.user': jsonEncode(_user.toJson()),
      });
      final session = _session(client: MockClient((_) async => throw http.ClientException('offline')));
      await session.restore();
      await session.refresh();
      expect(session.value?.username, 'osman');
    });

    test('logout clears locally and tells the backend', () async {
      final log = <http.Request>[];
      final session = _session(client: _fakeBackend(log: log));
      await session.login(username: 'osman', password: 'password1');
      await session.logout();
      await Future<void>.delayed(Duration.zero);
      expect(session.isSignedIn, isFalse);
      expect(session.token, isNull);
      expect(log.last.url.path, '/api/auth/logout');
      expect(log.last.headers['Authorization'], 'Bearer tok');
    });

    test('without a backend the controller is unavailable', () async {
      final session = SessionController();
      expect(session.isAvailable, isFalse);
      await session.restore();
      expect(session.isSignedIn, isFalse);
    });
  });

  group('LoginScreen', () {
    testWidgets('requires both fields', (tester) async {
      await _open(tester, LoginScreen(session: _session()));
      await _tapButton(tester, 'SIGN IN');
      expect(find.text('Enter your username'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the server error for a wrong password', (tester) async {
      await _open(tester, LoginScreen(session: _session()));
      await tester.enterText(find.byType(TextFormField).at(0), 'osman');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong-pass');
      await _tapButton(tester, 'SIGN IN');
      expect(find.text('Wrong username or password'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('signs in and pops back', (tester) async {
      final session = _session();
      await _open(tester, LoginScreen(session: session));
      await tester.enterText(find.byType(TextFormField).at(0), ' osman ');
      await tester.enterText(find.byType(TextFormField).at(1), 'password1');
      await _tapButton(tester, 'SIGN IN');
      expect(session.value?.username, 'osman');
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('Welcome, Osman!'), findsOneWidget);
    });

    testWidgets('explains itself when there is no backend', (tester) async {
      await _open(tester, LoginScreen(session: SessionController()));
      expect(find.text('ACCOUNTS UNAVAILABLE'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });
  });

  group('SignupScreen', () {
    testWidgets('validates with the shared account rules', (tester) async {
      await _open(tester, SignupScreen(session: _session()));
      await tester.enterText(find.byType(TextFormField).at(0), 'a b');
      await tester.enterText(find.byType(TextFormField).at(2), 'short');
      await tester.enterText(find.byType(TextFormField).at(3), 'different');
      await _tapButton(tester, 'CREATE ACCOUNT');
      expect(find.text('3–20 characters: letters, numbers, _ or .'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text("Passwords don't match"), findsOneWidget);
    });

    testWidgets('shows "username taken" from the server', (tester) async {
      await _open(tester, SignupScreen(session: _session()));
      await tester.enterText(find.byType(TextFormField).at(0), 'taken');
      await tester.enterText(find.byType(TextFormField).at(2), 'password1');
      await tester.enterText(find.byType(TextFormField).at(3), 'password1');
      await _tapButton(tester, 'CREATE ACCOUNT');
      expect(find.text('That username is already taken'), findsOneWidget);
    });

    testWidgets('creates the account, signs in and pops back', (tester) async {
      final session = _session();
      await _open(tester, SignupScreen(session: session));
      await tester.enterText(find.byType(TextFormField).at(0), 'yeni_oyuncu');
      await tester.enterText(find.byType(TextFormField).at(1), 'İlkay');
      await tester.enterText(find.byType(TextFormField).at(2), 'password1');
      await tester.enterText(find.byType(TextFormField).at(3), 'password1');
      await _tapButton(tester, 'CREATE ACCOUNT');
      expect(session.value?.username, 'yeni_oyuncu');
      expect(session.value?.displayName, 'İlkay');
      expect(find.byType(SignupScreen), findsNothing);
    });
  });
}
