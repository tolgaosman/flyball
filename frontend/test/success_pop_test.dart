import 'package:flutter/material.dart';
import 'package:flyball/widgets/animations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'SuccessPop settles back to scale 1.0 (regression: chained '
    'flutter_animate .scale().then().scale() used to compose '
    'multiplicatively and leave it stuck at ~1.1x)',
    (tester) async {
      Object? trigger = 1;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setter) {
              setState = setter;
              return SuccessPop(trigger: trigger, child: const SizedBox(width: 40, height: 40));
            },
          ),
        ),
      );

      // Change the trigger to start the pop animation.
      setState(() => trigger = 2);
      await tester.pump(); // build with new trigger
      await tester.pump(const Duration(milliseconds: 100)); // mid pop-up

      final midScale = tester.widget<ScaleTransition>(find.byType(ScaleTransition)).scale.value;
      expect(midScale, greaterThan(1.0)); // actually popped up partway through

      // Run past the full animation.
      await tester.pump(const Duration(milliseconds: 400));
      final endScale = tester.widget<ScaleTransition>(find.byType(ScaleTransition)).scale.value;
      expect(endScale, closeTo(1.0, 0.001));
    },
  );

  testWidgets('SuccessPop renders the child unwrapped when trigger is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SuccessPop(trigger: null, child: Text('hello')),
      ),
    );
    expect(find.byType(ScaleTransition), findsNothing);
    expect(find.text('hello'), findsOneWidget);
  });
}
