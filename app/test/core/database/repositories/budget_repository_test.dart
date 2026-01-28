import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/repositories/budget_repository.dart';
import 'package:trustguard/src/core/models/budget.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late DriftBudgetRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftBudgetRepository(db);

    // Create required dependencies for foreign keys
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: 'group1',
            name: 'Test Group',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftBudgetRepository', () {
    final now = DateTime.now();
    final testBudget = Budget(
      id: const Uuid().v4(),
      groupId: 'group1',
      name: 'Monthly Groceries',
      limitMinor: 50000,
      currencyCode: 'USD',
      period: BudgetPeriod.monthly,
      startDate: now,
      alertThreshold: 80,
      isActive: true,
      createdAt: now,
    );

    test('createBudget adds a new budget', () async {
      await repository.createBudget(testBudget);

      final retrieved = await repository.getBudgetById(testBudget.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Monthly Groceries');
      expect(retrieved.limitMinor, 50000);
    });

    test('updateBudget updates existing budget', () async {
      await repository.createBudget(testBudget);

      final updated = testBudget.copyWith(name: 'Weekly Groceries');
      await repository.updateBudget(updated);

      final retrieved = await repository.getBudgetById(testBudget.id);
      expect(retrieved!.name, 'Weekly Groceries');
    });

    test('deleteBudget removes the budget', () async {
      await repository.createBudget(testBudget);
      await repository.deleteBudget(testBudget.id);

      final retrieved = await repository.getBudgetById(testBudget.id);
      expect(retrieved, isNull);
    });

    test('watchActiveBudgets returns only active budgets for group', () async {
      await repository.createBudget(testBudget);
      await repository.createBudget(
        testBudget.copyWith(
          id: const Uuid().v4(),
          name: 'Inactive Budget',
          isActive: false,
        ),
      );

      final stream = repository.watchActiveBudgets('group1');
      final budgets = await stream.first;

      expect(budgets.length, 1);
      expect(budgets.first.name, 'Monthly Groceries');
    });

    test('getBudgetsByGroup returns all budgets for group', () async {
      await repository.createBudget(testBudget);
      await repository.createBudget(
        testBudget.copyWith(
          id: const Uuid().v4(),
          name: 'Inactive Budget',
          isActive: false,
        ),
      );

      final budgets = await repository.getBudgetsByGroup('group1');

      expect(budgets.length, 2);
    });
  });
}
