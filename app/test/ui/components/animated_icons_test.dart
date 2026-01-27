import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/ui/components/animated_filter_badge.dart';
import 'package:trustguard/src/ui/components/animated_archive_icon.dart';

void main() {
  group('AnimatedFilterBadge', () {
    testWidgets('renders child and shows badge when isActive is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedFilterBadge(
              isActive: true,
              child: Icon(Icons.filter_list),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      // Badge is a Container with a circle shape
      final badgeFinder = find.byType(Container);
      expect(badgeFinder, findsOneWidget);
    });

    testWidgets('badge animates in when isActive changes from false to true', (
      WidgetTester tester,
    ) async {
      bool isActive = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: AnimatedFilterBadge(
                  isActive: isActive,
                  child: IconButton(
                    onPressed: () => setState(() => isActive = true),
                    icon: const Icon(Icons.filter_list),
                  ),
                ),
              ),
            );
          },
        ),
      );

      // Initially, the badge is not visible (scale 0)
      // We check that the ScaleTransition scale is 0.0 or forward animation hasn't started
      final badgeScaleTransition = find.descendant(
        of: find.byType(AnimatedFilterBadge),
        matching: find.byType(ScaleTransition),
      );
      var scaleTransition = tester.widget<ScaleTransition>(
        badgeScaleTransition,
      );
      expect(scaleTransition.scale.value, 0.0);

      await tester.tap(find.byType(IconButton));
      await tester.pump(); // Start animation

      // Middle of animation
      await tester.pump(const Duration(milliseconds: 150));
      scaleTransition = tester.widget<ScaleTransition>(badgeScaleTransition);
      expect(scaleTransition.scale.value, greaterThan(0.0));

      await tester.pumpAndSettle();
      scaleTransition = tester.widget<ScaleTransition>(badgeScaleTransition);
      expect(scaleTransition.scale.value, 1.0);
    });

    testWidgets('respects reduced motion', (WidgetTester tester) async {
      // Set reduced motion via MediaQueryData
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: AnimatedFilterBadge(
                isActive: true,
                child: Icon(Icons.filter_list),
              ),
            ),
          ),
        ),
      );

      final badgeScaleTransition = find.descendant(
        of: find.byType(AnimatedFilterBadge),
        matching: find.byType(ScaleTransition),
      );
      final scaleTransition = tester.widget<ScaleTransition>(
        badgeScaleTransition,
      );
      expect(scaleTransition.scale.value, 1.0);
    });
  });

  group('AnimatedArchiveIcon', () {
    testWidgets('shows correct icon based on isArchived', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AnimatedArchiveIcon(isArchived: false)),
        ),
      );
      expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
      expect(find.byIcon(Icons.archive), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AnimatedArchiveIcon(isArchived: true)),
        ),
      );
      // Need to pump for AnimatedSwitcher
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.archive), findsOneWidget);
      expect(find.byIcon(Icons.archive_outlined), findsNothing);
    });

    testWidgets('animates transition between states', (
      WidgetTester tester,
    ) async {
      bool isArchived = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: InkWell(
                  onTap: () => setState(() => isArchived = !isArchived),
                  child: AnimatedArchiveIcon(isArchived: isArchived),
                ),
              ),
            );
          },
        ),
      );

      expect(find.byIcon(Icons.archive_outlined), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump(); // Start animation

      // Both icons might be present during transition
      expect(find.byIcon(Icons.archive), findsOneWidget);
      expect(find.byIcon(Icons.archive_outlined), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.archive), findsOneWidget);
      expect(find.byIcon(Icons.archive_outlined), findsNothing);
    });
  });
}
