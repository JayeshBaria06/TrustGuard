import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/repositories/template_repository.dart';
import 'package:trustguard/src/core/models/expense_template.dart';
import 'package:trustguard/src/features/templates/presentation/template_picker_sheet.dart';
import 'package:trustguard/src/ui/theme/app_theme.dart';
import 'package:trustguard/src/core/models/expense_template.dart'
    as template_model;

class MockTemplateRepository extends Mock implements TemplateRepository {}

void main() {
  late MockTemplateRepository mockRepository;

  setUp(() {
    mockRepository = MockTemplateRepository();
  });

  // Helper to pump the sheet
  Future<void> pumpSheet(
    WidgetTester tester, {
    required List<ExpenseTemplate> templates,
    required void Function(ExpenseTemplate) onSelected,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          templateRepositoryProvider.overrideWithValue(mockRepository),
          templatesProvider(
            'group1',
          ).overrideWith((ref) => Stream.value(templates)),
          moneyFormatterProvider.overrideWithValue(
            (int minor, {String currencyCode = 'USD', String? locale}) =>
                '$currencyCode ${minor / 100}',
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TemplatePickerSheet(
              groupId: 'group1',
              onSelected: onSelected,
            ),
          ),
        ),
      ),
    );
  }

  final t1 = template_model.ExpenseTemplate(
    id: 't1',
    groupId: 'group1',
    name: 'Template 1',
    currencyCode: 'USD',
    payerId: 'user1',
    splitType: template_model.SplitType.equal,
    tagIds: [],
    orderIndex: 0,
    createdAt: DateTime(2023),
    usageCount: 5,
    amountMinor: 1000, // 10.00
  );

  final t2 = template_model.ExpenseTemplate(
    id: 't2',
    groupId: 'group1',
    name: 'Template 2',
    currencyCode: 'USD',
    payerId: 'user1',
    splitType: template_model.SplitType.equal,
    tagIds: [],
    orderIndex: 1,
    createdAt: DateTime(2023),
    usageCount: 2,
    amountMinor: null, // Variable
  );

  testWidgets('renders list of templates', (tester) async {
    await pumpSheet(tester, templates: [t1, t2], onSelected: (_) {});
    await tester.pump(Duration.zero); // Allow stream to emit

    expect(find.widgetWithText(ListTile, 'Template 1'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Template 2'), findsOneWidget);
    expect(find.text('USD 10.0'), findsOneWidget); // Formatted amount
    expect(find.text('Variable'), findsOneWidget);
    expect(find.text('Used 5x'), findsOneWidget);
  });

  testWidgets('shows empty state when no templates', (tester) async {
    await pumpSheet(tester, templates: [], onSelected: (_) {});
    await tester.pump(Duration.zero);

    expect(find.text('No Templates Yet'), findsOneWidget);
  });

  testWidgets('filters templates by search query', (tester) async {
    await pumpSheet(tester, templates: [t1, t2], onSelected: (_) {});
    await tester.pump(Duration.zero);

    // Enter search text
    await tester.enterText(find.byType(TextField), 'Template 1');
    await tester.pump();

    // The text 'Template 1' appears in the search field and the list tile.
    // We expect 2 found in total, but we want to verify the list item is present.
    expect(find.widgetWithText(ListTile, 'Template 1'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Template 2'), findsNothing);
  });

  testWidgets('calls onSelected when tapped', (tester) async {
    ExpenseTemplate? selected;
    await pumpSheet(tester, templates: [t1], onSelected: (t) => selected = t);
    await tester.pump(Duration.zero);

    await tester.tap(find.widgetWithText(ListTile, 'Template 1'));
    await tester.pump(); // Handle navigation pop if any

    expect(selected, t1);
  });
}
