import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:trustguard/src/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/repositories/template_repository.dart';
import 'package:trustguard/src/core/models/expense_template.dart';
import 'package:trustguard/src/core/models/group.dart';
import 'package:trustguard/src/core/models/member.dart';
import 'package:trustguard/src/core/services/coachmark_service.dart';
import 'package:trustguard/src/features/settings/services/settings_service.dart';
import 'package:trustguard/src/features/transactions/presentation/add_expense_screen.dart';
import 'package:trustguard/src/ui/theme/app_theme.dart';
import 'package:trustguard/src/core/models/expense_template.dart'
    as template_model;
import 'package:trustguard/src/features/groups/presentation/groups_providers.dart';
import 'package:trustguard/src/features/transactions/presentation/transactions_providers.dart';

class MockCoachmarkService extends Mock implements CoachmarkService {}

class MockTemplateRepository extends Mock implements TemplateRepository {}

class MockSettingsService extends Mock implements SettingsService {}

void main() {
  late MockCoachmarkService mockCoachmarkService;
  late MockTemplateRepository mockTemplateRepository;
  late MockSettingsService mockSettingsService;
  late SharedPreferences sharedPreferences;

  setUpAll(() async {
    registerFallbackValue(CoachmarkKey.receiptScanHint);
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  setUp(() {
    mockCoachmarkService = MockCoachmarkService();
    mockTemplateRepository = MockTemplateRepository();
    mockSettingsService = MockSettingsService();
    when(() => mockCoachmarkService.shouldShow(any())).thenReturn(false);
    when(
      () => mockTemplateRepository.updateUsageCount(any()),
    ).thenAnswer((_) async {});
    when(() => mockSettingsService.isCustomKeypadEnabled()).thenReturn(false);
    when(() => mockSettingsService.getRoundingDecimalPlaces()).thenReturn(2);
  });

  final group = Group(
    id: 'group1',
    name: 'Test Group',
    currencyCode: 'USD',
    createdAt: DateTime.now(),
  );

  final member1 = Member(
    id: 'user1',
    groupId: 'group1',
    displayName: 'User 1',
    createdAt: DateTime.now(),
  );

  final member2 = Member(
    id: 'user2',
    groupId: 'group1',
    displayName: 'User 2',
    createdAt: DateTime.now(),
  );

  final t1 = template_model.ExpenseTemplate(
    id: 't1',
    groupId: 'group1',
    name: 'Fixed Template',
    currencyCode: 'USD',
    payerId: 'user1',
    splitType: template_model.SplitType.equal,
    tagIds: [],
    orderIndex: 0,
    createdAt: DateTime(2023),
    usageCount: 5,
    amountMinor: 1000, // 10.00
    description: 'Fixed Description',
  );

  final t2 = template_model.ExpenseTemplate(
    id: 't2',
    groupId: 'group1',
    name: 'Variable Template',
    currencyCode: 'USD',
    payerId: 'user1',
    splitType: template_model.SplitType.equal,
    tagIds: [],
    orderIndex: 0,
    createdAt: DateTime(2023),
    usageCount: 5,
    amountMinor: null, // Variable
    description: 'Variable Description',
  );

  Future<void> pumpScreen(
    WidgetTester tester, {
    ExpenseTemplate? initialTemplate,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsServiceProvider.overrideWithValue(mockSettingsService),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          coachmarkServiceProvider.overrideWithValue(mockCoachmarkService),
          templateRepositoryProvider.overrideWithValue(mockTemplateRepository),
          groupStreamProvider(
            'group1',
          ).overrideWith((ref) => Stream.value(group)),
          membersByGroupProvider(
            'group1',
          ).overrideWith((ref) => Stream.value([member1, member2])),
          amountSuggestionsProvider(
            'group1',
          ).overrideWith((ref) => Future.value([])),
          tagsProvider('group1').overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: AddExpenseScreen(
            groupId: 'group1',
            initialTemplate: initialTemplate,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('pre-fills fixed amount from template', (tester) async {
    await pumpScreen(tester, initialTemplate: t1);

    expect(find.text('10.00'), findsOneWidget); // Amount field
    expect(find.text('Fixed Description'), findsOneWidget); // Note field
  });

  testWidgets('leaves amount empty for variable template', (tester) async {
    await pumpScreen(tester, initialTemplate: t2);

    expect(find.text('10.00'), findsNothing);
    expect(find.text('Variable Description'), findsOneWidget);
  });
}
