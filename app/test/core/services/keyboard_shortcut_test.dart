import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/services/keyboard_shortcut_service.dart';

void main() {
  group('KeyboardShortcutService', () {
    test('defaultShortcuts contains expected mappings', () {
      final shortcuts = KeyboardShortcutService.defaultShortcuts;

      expect(shortcuts.values, contains(isA<NewExpenseIntent>()));
      expect(shortcuts.values, contains(isA<NewTransferIntent>()));
      expect(shortcuts.values, contains(isA<SaveIntent>()));
      expect(shortcuts.values, contains(isA<SearchIntent>()));
      expect(shortcuts.values, contains(isA<CancelIntent>()));
    });
  });

  group('AppShortcuts Widget', () {
    testWidgets('triggers actions when keys are pressed', (
      WidgetTester tester,
    ) async {
      bool newExpenseCalled = false;
      bool saveCalled = false;
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AppShortcuts(
            actions: {
              NewExpenseIntent: CallbackAction<NewExpenseIntent>(
                onInvoke: (intent) => newExpenseCalled = true,
              ),
              SaveIntent: CallbackAction<SaveIntent>(
                onInvoke: (intent) => saveCalled = true,
              ),
              CancelIntent: CallbackAction<CancelIntent>(
                onInvoke: (intent) => cancelCalled = true,
              ),
            },
            child: const Scaffold(
              body: Center(
                child: Focus(autofocus: true, child: Text('Shortcut Test')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test NewExpenseIntent (Ctrl+N or Cmd+N)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      if (!newExpenseCalled) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await tester.pump();
      }

      expect(
        newExpenseCalled,
        isTrue,
        reason: 'NewExpenseIntent should be triggered',
      );

      // Test SaveIntent (Ctrl+S or Cmd+S)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      if (!saveCalled) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await tester.pump();
      }
      expect(saveCalled, isTrue, reason: 'SaveIntent should be triggered');

      // Test CancelIntent (Escape)
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(cancelCalled, isTrue, reason: 'CancelIntent should be triggered');
    });
  });
}
