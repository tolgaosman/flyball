import 'package:flutter/material.dart';
import 'package:flyball/l10n/app_localizations.dart';
import 'package:flyball/main.dart';
import 'package:flyball/screens/coming_soon_screen.dart';
import 'package:flyball/screens/xox_lobby_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  setUpAll(() {
    // Never hit the network for fonts in tests; fall back to bundled defaults.
    GoogleFonts.config.allowRuntimeFetching = false;
    // localeController.setLocale persists via shared_preferences; this gives
    // it an in-memory fake instead of a real platform channel.
    SharedPreferences.setMockInitialValues({});
  });

  // `localeController` is a module-level singleton (see main.dart), so a
  // locale change in one test would otherwise leak into the next.
  tearDown(() => localeController.value = null);

  testWidgets('HomeScreen renders the game buttons', (tester) async {
    await tester.pumpWidget(const FlyballApp());
    await tester.pumpAndSettle();

    expect(find.text('FOOTBALL XOX'), findsOneWidget);
    expect(find.text('2 TEAM 1 PLAYER'), findsOneWidget);
    expect(find.text('1 TEAM 1 COUNTRY'), findsOneWidget);
    expect(find.text('FOOTBALLDLE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping Football XOX opens the lobby', (tester) async {
    await tester.pumpWidget(const FlyballApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('FOOTBALL XOX'));
    await tester.pumpAndSettle();

    expect(find.byType(XoxLobbyScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home language toggle switches the whole app language', (tester) async {
    await tester.pumpWidget(const FlyballApp());
    await tester.pumpAndSettle();
    expect(find.text('EN'), findsOneWidget);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('TR'), findsOneWidget);
    // The lobby's start button label should now read Turkish too.
    await tester.tap(find.text('FOOTBALL XOX'));
    await tester.pumpAndSettle();
    expect(find.text('MAÇI BAŞLAT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('XoxLobbyScreen validates both names before starting', (tester) async {
    await tester.pumpWidget(_wrap(const XoxLobbyScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('START MATCH'));
    await tester.pump();

    expect(find.text('Please enter a name'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ComingSoonScreen renders without overflowing', (tester) async {
    await tester.pumpWidget(_wrap(const ComingSoonScreen(title: 'Footballdle', icon: Icons.abc_rounded)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
