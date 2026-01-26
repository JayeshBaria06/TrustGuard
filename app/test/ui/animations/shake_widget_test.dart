import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/ui/animations/shake_widget.dart';

void main() {
  testWidgets('ShakeWidget renders child', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ShakeWidget(child: Text('Shake me'))),
      ),
    );

    expect(find.text('Shake me'), findsOneWidget);
  });

  testWidgets('ShakeWidget animates when shake() is called', (
    WidgetTester tester,
  ) async {
    final key = GlobalKey<ShakeWidgetState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShakeWidget(
            key: key,
            shakeRange: 10.0,
            duration: const Duration(milliseconds: 400),
            child: const Text('Target'),
          ),
        ),
      ),
    );

    // Initial translation should be 0
    // We find the Transform that is a descendant of ShakeWidget
    Finder findTransform() => find.descendant(
      of: find.byType(ShakeWidget),
      matching: find.byType(Transform),
    );

    Transform transform = tester.widget(findTransform());
    expect(transform.transform.getTranslation().x, 0.0);

    // Trigger shake
    key.currentState?.shake();
    await tester.pump(); // Start animation

    // Mid-animation check
    await tester.pump(const Duration(milliseconds: 50));
    transform = tester.widget(findTransform());
    expect(transform.transform.getTranslation().x, isNot(0.0));

    // Wait for end
    await tester.pumpAndSettle();
    transform = tester.widget(findTransform());
    expect(transform.transform.getTranslation().x, 0.0);
  });
}
