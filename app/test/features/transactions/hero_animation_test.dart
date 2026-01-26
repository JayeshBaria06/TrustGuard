import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/features/transactions/presentation/transaction_list_screen.dart';
import 'package:trustguard/src/features/transactions/presentation/transaction_detail_screen.dart';
import '../../helpers/localization_helper.dart';
import '../../helpers/shared_prefs_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    // db is closed inside tests
  });

  testWidgets('OpenContainer wraps transaction items', (tester) async {
    final groupId = 'g1';
    final txId = 't1';

    // Seed data
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
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: txId,
            groupId: groupId,
            type: TransactionType.expense,
            occurredAt: DateTime.now(),
            note: 'Test Tx',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(TransactionListScreen(groupId: groupId)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1)); // Wait for data

    // Verify the transaction item is actually rendered
    expect(find.text('Test Tx'), findsOneWidget);

    // Verify OpenContainer exists
    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString().startsWith('OpenContainer'),
      ),
      findsOneWidget,
    );

    // Verify Hero is NOT used for the icon anymore
    final hero = find.byElementPredicate((element) {
      if (element.widget is Hero) {
        return (element.widget as Hero).tag == 'transaction_icon_$txId';
      }
      return false;
    });
    expect(hero, findsNothing);

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets('OpenContainer opens TransactionDetailScreen', (tester) async {
    final groupId = 'g1';
    final txId = 't1';

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
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: txId,
            groupId: groupId,
            type: TransactionType.expense,
            occurredAt: DateTime.now(),
            note: 'Test Tx',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales,
          home: TransactionListScreen(groupId: groupId),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Test Tx'), findsOneWidget);

    // Tap the transaction item to trigger OpenContainer
    await tester.tap(find.text('Test Tx'));

    // Verify transition starts
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Wait for animation to finish
    await tester.pumpAndSettle();

    expect(find.byType(TransactionDetailScreen), findsOneWidget);
    expect(find.text('Transaction Details'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
