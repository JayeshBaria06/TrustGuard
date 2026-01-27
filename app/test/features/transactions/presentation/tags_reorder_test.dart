import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/features/transactions/presentation/tags_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../../../helpers/localization_helper.dart';
import '../../../helpers/shared_prefs_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  Future<void> setupGroup(String id) async {
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: id,
            name: 'Test Group',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> createTag(
    String id,
    String groupId,
    String name,
    int orderIndex,
  ) async {
    await db
        .into(db.tags)
        .insert(
          TagsCompanion.insert(
            id: id,
            groupId: groupId,
            name: name,
            orderIndex: Value(orderIndex),
          ),
        );
  }

  testWidgets('TagsScreen supports reordering tags', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    await setupGroup(groupId);

    final foodId = const Uuid().v4();
    final travelId = const Uuid().v4();

    await createTag(foodId, groupId, 'Food', 0);
    await createTag(travelId, groupId, 'Travel', 1);

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(TagsScreen(groupId: groupId)),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);

    // Find drag handles
    final handles = find.byIcon(Icons.drag_handle);
    expect(handles, findsNWidgets(2));

    // Verify initial order in UI
    final foodPos = tester.getCenter(find.byKey(ValueKey(foodId)));
    final travelPos = tester.getCenter(find.byKey(ValueKey(travelId)));
    expect(foodPos.dy < travelPos.dy, isTrue);

    // Drag Food below Travel
    final firstHandle = tester.getCenter(handles.first);
    final gesture = await tester.startGesture(firstHandle);
    await tester.pump(kPressTimeout);
    await gesture.moveBy(
      const Offset(0, 150),
    ); // Large enough offset to move past Travel
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify order in UI changed
    final foodPosNew = tester.getCenter(find.byKey(ValueKey(foodId)));
    final travelPosNew = tester.getCenter(find.byKey(ValueKey(travelId)));
    expect(foodPosNew.dy > travelPosNew.dy, isTrue);

    // Verify order in DB
    final tags = await db.select(db.tags).get();
    final food = tags.firstWhere((t) => t.id == foodId);
    final travel = tags.firstWhere((t) => t.id == travelId);

    // Food should now have orderIndex 1, Travel 0
    expect(food.orderIndex, 1);
    expect(travel.orderIndex, 0);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
