import 'package:flutter_test/flutter_test.dart';
import 'package:flyball/main.dart';
import 'package:flyball/screens/xox_lobby_screen.dart';

void main() {
  testWidgets('Home shows the three game buttons', (tester) async {
    await tester.pumpWidget(const FlyballApp());
    await tester.pumpAndSettle();

    expect(find.text('FOOTBALL XOX'), findsOneWidget);
    expect(find.text('2 TEAM 1 PLAYER'), findsOneWidget);
    expect(find.text('1 TEAM 1 COUNTRY'), findsOneWidget);
  });

  testWidgets('Tapping Football XOX opens the grid game', (tester) async {
    await tester.pumpWidget(const FlyballApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('FOOTBALL XOX'));
    await tester.pumpAndSettle();

    expect(find.byType(XoxLobbyScreen), findsOneWidget);
    // Should see player 1 and 2 input fields
    expect(find.text('PLAYER 1'), findsOneWidget);
    expect(find.text('PLAYER 2'), findsOneWidget);
  });
}
