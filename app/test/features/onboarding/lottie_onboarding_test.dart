import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustguard/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

class MockGoRouter extends Mock implements GoRouter {}

class MockGoRouterProvider extends StatelessWidget {
  const MockGoRouterProvider({
    required this.goRouter,
    required this.child,
    super.key,
  });

  final GoRouter goRouter;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      InheritedGoRouter(goRouter: goRouter, child: child);
}

void main() {
  late SharedPreferences prefs;
  late MockGoRouter mockRouter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockRouter = MockGoRouter();
    when(() => mockRouter.go(any())).thenReturn(null);
  });

  testWidgets('OnboardingScreen renders Lottie widgets on each slide', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MockGoRouterProvider(
          goRouter: mockRouter,
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      ),
    );

    // First slide
    expect(find.text('No Account Needed'), findsOneWidget);
    // Use LottieBuilder instead of Lottie if Lottie type check is flaky
    expect(find.byType(LottieBuilder), findsOneWidget);

    // Navigate to second slide
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Your Data Stays Private'), findsOneWidget);
    expect(find.byType(LottieBuilder), findsOneWidget);

    // Navigate to third slide
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Easy Expense Splitting'), findsOneWidget);
    expect(find.byType(LottieBuilder), findsOneWidget);
  });

  testWidgets('OnboardingScreen Skip button completes onboarding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MockGoRouterProvider(
          goRouter: mockRouter,
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      ),
    );

    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Verify preference is set
    expect(prefs.getBool('onboarding_complete'), isTrue);
    verify(() => mockRouter.go('/')).called(1);
  });

  testWidgets(
    'OnboardingScreen Get Started button appears on last slide and completes onboarding',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MockGoRouterProvider(
            goRouter: mockRouter,
            child: const MaterialApp(home: OnboardingScreen()),
          ),
        ),
      );

      // Navigate to second slide
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Navigate to third slide
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Verify preference is set
      expect(prefs.getBool('onboarding_complete'), isTrue);
      verify(() => mockRouter.go('/')).called(1);
    },
  );
}
