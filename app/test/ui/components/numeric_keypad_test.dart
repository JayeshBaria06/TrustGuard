import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/ui/components/numeric_keypad.dart';

void main() {
  testWidgets('NumericKeypad digit buttons fire onDigitPressed', (
    WidgetTester tester,
  ) async {
    String? pressedDigit;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumericKeypad(
            onDigitPressed: (digit) => pressedDigit = digit,
            onDecimalPressed: () {},
            onBackspacePressed: () {},
            onClearPressed: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('1'));
    expect(pressedDigit, '1');

    await tester.tap(find.text('5'));
    expect(pressedDigit, '5');

    await tester.tap(find.text('9'));
    expect(pressedDigit, '9');

    await tester.tap(find.text('0'));
    expect(pressedDigit, '0');
  });

  testWidgets('NumericKeypad decimal button fires onDecimalPressed', (
    WidgetTester tester,
  ) async {
    bool decimalPressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumericKeypad(
            onDigitPressed: (_) {},
            onDecimalPressed: () => decimalPressed = true,
            onBackspacePressed: () {},
            onClearPressed: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('.'));
    expect(decimalPressed, true);
  });

  testWidgets('NumericKeypad backspace fires onBackspacePressed', (
    WidgetTester tester,
  ) async {
    bool backspacePressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumericKeypad(
            onDigitPressed: (_) {},
            onDecimalPressed: () {},
            onBackspacePressed: () => backspacePressed = true,
            onClearPressed: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    expect(backspacePressed, true);
  });

  testWidgets('NumericKeypad long press on backspace fires onClearPressed', (
    WidgetTester tester,
  ) async {
    bool clearPressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumericKeypad(
            onDigitPressed: (_) {},
            onDecimalPressed: () {},
            onBackspacePressed: () {},
            onClearPressed: () => clearPressed = true,
          ),
        ),
      ),
    );

    await tester.longPress(find.byIcon(Icons.backspace_outlined));
    expect(clearPressed, true);
  });

  testWidgets('NumericKeypad handles keyboard input', (
    WidgetTester tester,
  ) async {
    String? pressedDigit;
    bool decimalPressed = false;
    bool backspacePressed = false;
    bool clearPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumericKeypad(
            onDigitPressed: (digit) => pressedDigit = digit,
            onDecimalPressed: () => decimalPressed = true,
            onBackspacePressed: () => backspacePressed = true,
            onClearPressed: () => clearPressed = true,
          ),
        ),
      ),
    );

    // Focus is required for onKeyEvent to work
    // Focus is already added in NumericKeypad with autofocus: true

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    expect(pressedDigit, '1');

    await tester.sendKeyEvent(LogicalKeyboardKey.period);
    expect(decimalPressed, true);

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    expect(backspacePressed, true);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(clearPressed, true);
  });

  testWidgets('NumericKeypad showDecimal: false hides decimal button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumericKeypad(
            onDigitPressed: (_) {},
            onDecimalPressed: () {},
            onBackspacePressed: () {},
            onClearPressed: () {},
            showDecimal: false,
          ),
        ),
      ),
    );

    expect(find.text('.'), findsNothing);
  });
}
