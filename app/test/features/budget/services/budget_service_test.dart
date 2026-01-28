import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/core/database/repositories/budget_repository.dart';
import 'package:trustguard/src/core/database/repositories/transaction_repository.dart';
import 'package:trustguard/src/core/models/budget.dart';
import 'package:trustguard/src/core/models/expense.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/core/models/transaction_filter.dart';
import 'package:trustguard/src/features/budget/services/budget_service.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockBudgetRepository mockBudgetRepo;
  late MockTransactionRepository mockTransactionRepo;
  late BudgetService service;

  setUp(() {
    mockBudgetRepo = MockBudgetRepository();
    mockTransactionRepo = MockTransactionRepository();
    service = BudgetService(mockBudgetRepo, mockTransactionRepo);

    registerFallbackValue(const TransactionFilter());
  });

  group('BudgetService', () {
    test('calculatePeriodBounds returns correct dates for monthly', () {
      final now = DateTime.now();
      final budget = Budget(
        id: '1',
        groupId: 'g1',
        name: 'Test',
        limitMinor: 1000,
        currencyCode: 'USD',
        period: BudgetPeriod.monthly,
        startDate: now,
        alertThreshold: 80,
        isActive: true,
        createdAt: now,
      );

      final (start, end) = service.calculatePeriodBounds(budget);

      expect(start.day, 1);
      expect(start.month, now.month);
      expect(end.month, now.month);
      expect(end.hour, 23);
      expect(end.minute, 59);
    });

    test('getSpendingForBudget aggregates expenses correctly', () async {
      final now = DateTime.now();
      final budget = Budget(
        id: '1',
        groupId: 'g1',
        name: 'Test',
        limitMinor: 1000,
        currencyCode: 'USD',
        period: BudgetPeriod.monthly,
        startDate: now,
        alertThreshold: 80,
        isActive: true,
        createdAt: now,
      );

      final tx1 = Transaction(
        id: 't1',
        groupId: 'g1',
        type: TransactionType.expense,
        note: 'T1',
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
        expenseDetail: const ExpenseDetail(
          payerMemberId: 'u1',
          totalAmountMinor: 200,
          splitType: SplitType.equal,
          participants: [],
        ),
      );

      final tx2 = Transaction(
        id: 't2',
        groupId: 'g1',
        type: TransactionType.expense,
        note: 'T2',
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
        expenseDetail: const ExpenseDetail(
          payerMemberId: 'u1',
          totalAmountMinor: 300,
          splitType: SplitType.equal,
          participants: [],
        ),
      );

      when(
        () => mockTransactionRepo.getTransactionsByGroup(
          any(),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer((_) async => [tx1, tx2]);

      final spent = await service.getSpendingForBudget(budget);

      expect(spent, 500);
      verify(
        () => mockTransactionRepo.getTransactionsByGroup(
          'g1',
          filter: any(named: 'filter'),
        ),
      ).called(1);
    });

    test('checkBudgetAlerts triggers when threshold exceeded', () async {
      final now = DateTime.now();
      final budget = Budget(
        id: '1',
        groupId: 'g1',
        name: 'Test',
        limitMinor: 1000,
        currencyCode: 'USD',
        period: BudgetPeriod.monthly,
        startDate: now,
        alertThreshold: 50, // 50%
        isActive: true,
        createdAt: now,
      );

      when(
        () => mockBudgetRepo.getBudgetsByGroup('g1'),
      ).thenAnswer((_) async => [budget]);

      final tx1 = Transaction(
        id: 't1',
        groupId: 'g1',
        type: TransactionType.expense,
        note: 'T1',
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
        expenseDetail: const ExpenseDetail(
          payerMemberId: 'u1',
          totalAmountMinor: 600, // 6.00 (60%)
          splitType: SplitType.equal,
          participants: [],
        ),
      );

      when(
        () => mockTransactionRepo.getTransactionsByGroup(
          any(),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer((_) async => [tx1]);

      final alerts = await service.checkBudgetAlerts('g1');

      expect(alerts.length, 1);
      expect(alerts.first.percentUsed, 0.6);
      expect(alerts.first.budget.id, '1');
    });

    test('checkBudgetAlerts does not trigger when below threshold', () async {
      final now = DateTime.now();
      final budget = Budget(
        id: '1',
        groupId: 'g1',
        name: 'Test',
        limitMinor: 1000,
        currencyCode: 'USD',
        period: BudgetPeriod.monthly,
        startDate: now,
        alertThreshold: 80, // 80%
        isActive: true,
        createdAt: now,
      );

      when(
        () => mockBudgetRepo.getBudgetsByGroup('g1'),
      ).thenAnswer((_) async => [budget]);

      final tx1 = Transaction(
        id: 't1',
        groupId: 'g1',
        type: TransactionType.expense,
        note: 'T1',
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
        expenseDetail: const ExpenseDetail(
          payerMemberId: 'u1',
          totalAmountMinor: 600, // 60% < 80%
          splitType: SplitType.equal,
          participants: [],
        ),
      );

      when(
        () => mockTransactionRepo.getTransactionsByGroup(
          any(),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer((_) async => [tx1]);

      final alerts = await service.checkBudgetAlerts('g1');

      expect(alerts, isEmpty);
    });
  });
}
