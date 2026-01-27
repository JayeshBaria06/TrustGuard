import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/ui/components/amount_input_field.dart';
import 'package:trustguard/src/ui/components/numeric_keypad.dart';
import '../../helpers/localization_helper.dart';

void main() {
  testWidgets('AmountInputField displays initial value correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: AmountInputField(
            initialValue: 1250, // $12.50
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('12.5'), findsOneWidget);
    expect(find.text('\$'), findsOneWidget);
  });

  testWidgets('AmountInputField typing updates display and fires onChanged', (
    WidgetTester tester,
  ) async {
    int? changedValue;
    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: AmountInputField(onChanged: (val) => changedValue = val),
        ),
      ),
    );

    // Default state: 0.00
    expect(find.text('0.00'), findsOneWidget);

    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('1')),
    );
    await tester.pump();
    expect(find.text('1'), findsNWidgets(2)); // Display and Keypad
    expect(changedValue, 100);

    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('2')),
    );
    await tester.pump();
    expect(
      find.text('12'),
      findsOneWidget,
    ); // Keypad '2' exists, but '12' is only in display
    expect(changedValue, 1200);

    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('.')),
    );
    await tester.pump();
    expect(find.text('12.'), findsOneWidget);
    expect(changedValue, 1200);

    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('5')),
    );
    await tester.pump();
    expect(find.text('12.5'), findsOneWidget);
    expect(changedValue, 1250);

    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('0')),
    );
    await tester.pump();
    expect(find.text('12.50'), findsOneWidget);
    expect(changedValue, 1250);
  });

  testWidgets('AmountInputField limits decimal places to 2', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithLocalization(Scaffold(body: AmountInputField(onChanged: (_) {}))),
    );

    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('1')),
    );
    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('.')),
    );
    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('2')),
    );
    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('5')),
    );
    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('9')),
    ); // Should be ignored
    await tester.pump();

    expect(find.text('1.25'), findsOneWidget);
  });

  testWidgets('AmountInputField quick buttons add correctly', (
    WidgetTester tester,
  ) async {
    int lastValue = 0;
    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: AmountInputField(
            initialValue: 1000, // $10.00
            onChanged: (val) => lastValue = val,
          ),
        ),
      ),
    );

    await tester.tap(find.text('+20'));
    await tester.pump();

    expect(find.text('30'), findsOneWidget);
    expect(lastValue, 3000);
  });

  testWidgets('AmountInputField backspace works', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: AmountInputField(
            initialValue: 1250, // $12.50
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(find.text('12.5'), findsNothing);
    expect(find.text('12.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('AmountInputField long press clear works', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(body: AmountInputField(initialValue: 1250, onChanged: (_) {})),
      ),
    );

    await tester.longPress(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(find.text('0.00'), findsOneWidget);
  });

  testWidgets('AmountInputField shows thousand separators', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithLocalization(Scaffold(body: AmountInputField(onChanged: (_) {}))),
    );

    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('1')),
    );
    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('2')),
    );
    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('3')),
    );
    await tester.tap(
      find.descendant(of: find.byType(NumericKeypad), matching: find.text('4')),
    );
    await tester.pump();

    // Use a more robust check for thousand separators as it might depend on locale
    // In US locale (default for tests often), it should be 1,234
    // Since we wrap with localization and use context locale, we expect a separator.
    final displayWidget =
        find.textContaining('1').evaluate().first.widget as Text;
    expect(displayWidget.data, contains(RegExp(r'1.234')));
  });
}
