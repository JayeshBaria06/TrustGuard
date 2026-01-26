import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/features/transactions/presentation/add_expense_screen.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> setupData(String groupId) async {
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: groupId,
            name: 'Test Group',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        );

    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'm1',
            groupId: groupId,
            displayName: 'Alice',
            createdAt: DateTime.now(),
          ),
        );

    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'm2',
            groupId: groupId,
            displayName: 'Bob',
            createdAt: DateTime.now(),
          ),
        );
  }

  testWidgets('AddExpenseScreen adds a new expense successfully', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    await setupData(groupId);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: AddExpenseScreen(groupId: groupId)),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    // Fill in form
    await tester.enterText(find.byType(TextFormField).first, '100.50');
    await tester.enterText(find.byType(TextFormField).at(1), 'Lunch');

    // Tap Save
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify transaction created
    final transactions = await db.select(db.transactions).get();
    expect(transactions.length, 1);
    expect(transactions.first.note, 'Lunch');

    final details = await db.select(db.expenseDetails).get();
    expect(details.length, 1);
    expect(details.first.totalAmountMinor, 10050);

    final participants = await db.select(db.expenseParticipants).get();
    expect(participants.length, 2);
    expect(participants.every((p) => p.owedAmountMinor == 5025), true);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
