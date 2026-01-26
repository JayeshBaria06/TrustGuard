import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/features/settings/presentation/settings_screen.dart';
import 'package:trustguard/src/features/settings/providers/lock_providers.dart';
import 'package:trustguard/src/core/platform/app_lock_service.dart';

class MockAppLockService extends Mock implements AppLockService {}

void main() {
  late MockAppLockService mockService;

  setUp(() {
    mockService = MockAppLockService();
    when(() => mockService.isPinSet()).thenAnswer((_) async => false);
    when(() => mockService.isBiometricEnabled()).thenAnswer((_) async => false);
    when(() => mockService.setBiometricEnabled(any())).thenAnswer((_) async {});
  });

  Widget createTestWidget(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  testWidgets('renders settings screen correctly', (tester) async {
    final container = ProviderContainer(
      overrides: [appLockServiceProvider.overrideWithValue(mockService)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(createTestWidget(container));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Set PIN'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('shows change pin when pin is set', (tester) async {
    when(() => mockService.isPinSet()).thenAnswer((_) async => true);

    final container = ProviderContainer(
      overrides: [appLockServiceProvider.overrideWithValue(mockService)],
    );
    addTearDown(container.dispose);

    await container.read(appLockStateProvider.notifier).init();
    await tester.pumpWidget(createTestWidget(container));
    await tester.pumpAndSettle();

    expect(find.text('Change PIN'), findsOneWidget);
    expect(find.text('Biometric Unlock'), findsOneWidget);
    expect(find.text('Remove PIN'), findsOneWidget);
  });

  testWidgets('toggling biometric unlock updates state', (tester) async {
    when(() => mockService.isPinSet()).thenAnswer((_) async => true);

    final container = ProviderContainer(
      overrides: [appLockServiceProvider.overrideWithValue(mockService)],
    );
    addTearDown(container.dispose);

    await container.read(appLockStateProvider.notifier).init();
    await tester.pumpWidget(createTestWidget(container));
    await tester.pumpAndSettle();

    final switchFinder = find.byType(SwitchListTile).first;
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    verify(() => mockService.setBiometricEnabled(true)).called(1);
    expect(container.read(appLockStateProvider).isBiometricEnabled, true);
  });
}
