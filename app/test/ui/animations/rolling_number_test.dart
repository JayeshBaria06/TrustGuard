import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/ui/components/rolling_number_text.dart';

void main() {
  testWidgets('RollingNumberText displays initial value correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RollingNumberText(value: 100))),
    );

    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('RollingNumberText animates when value changes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RollingNumberText(
            value: 100,
            duration: Duration(milliseconds: 500),
          ),
        ),
      ),
    );

    expect(find.text('100'), findsOneWidget);

    // Change value
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RollingNumberText(
            value: 200,
            duration: Duration(milliseconds: 500),
          ),
        ),
      ),
    );

    // Immediately after pump, it should still be 100 or close to it
    await tester.pump(const Duration(milliseconds: 100));
    final textWidget = tester.widget<Text>(find.byType(Text));
    final value = int.parse(textWidget.data!);
    expect(value, greaterThan(100));
    expect(value, lessThan(200));

    // Complete animation
    await tester.pumpAndSettle();
    expect(find.text('200'), findsOneWidget);
  });

  testWidgets('RollingNumberText handles negative values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RollingNumberText(value: -50))),
    );

    expect(find.text('-50'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RollingNumberText(value: 50))),
    );

    await tester.pumpAndSettle();
    expect(find.text('50'), findsOneWidget);
  });

  testWidgets('RollingNumberText applies custom formatFn', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RollingNumberText(value: 1234, formatFn: (val) => '$val units'),
        ),
      ),
    );

    expect(find.text('1234 units'), findsOneWidget);
  });

  testWidgets('RollingNumberText respects reduced motion', (
    WidgetTester tester,
  ) async {
    // Force reduced motion via MediaQuery
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: RollingNumberText(
              value: 100,
              duration: Duration(milliseconds: 500),
            ),
          ),
        ),
      ),
    );

    expect(find.text('100'), findsOneWidget);

    // Change value
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: RollingNumberText(
              value: 200,
              duration: Duration(milliseconds: 500),
            ),
          ),
        ),
      ),
    );

    // With reduced motion, it should jump immediately
    await tester.pump();
    expect(find.text('200'), findsOneWidget);
  });
}
