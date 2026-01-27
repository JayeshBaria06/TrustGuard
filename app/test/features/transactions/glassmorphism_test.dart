import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/features/transactions/presentation/widgets/date_group_header.dart';
import '../../helpers/localization_helper.dart';

void main() {
  testWidgets('DateGroupHeader renders with blur when isStuck is true', (
    WidgetTester tester,
  ) async {
    final date = DateTime(2026, 1, 27);
    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(body: DateGroupHeader(date: date, isStuck: true)),
      ),
    );

    // Verify BackdropFilter is present
    expect(find.byType(BackdropFilter), findsOneWidget);

    // Verify ClipRect is present (required for BackdropFilter)
    expect(find.byType(ClipRect), findsOneWidget);

    // Verify it contains the date label
    // Note: The label depends on today's date.
    // We can just check if it finds *any* text since we're testing glassmorphism.
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('DateGroupHeader renders without blur when isStuck is false', (
    WidgetTester tester,
  ) async {
    final date = DateTime(2026, 1, 27);
    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(body: DateGroupHeader(date: date, isStuck: false)),
      ),
    );

    // Verify BackdropFilter is NOT present
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(ClipRect), findsNothing);

    expect(find.byType(Text), findsOneWidget);
  });
}
