import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/core/database/repositories/transaction_repository.dart';
import 'package:trustguard/src/core/models/expense.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/features/transactions/services/amount_suggestion_service.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository repository;
  late AmountSuggestionService service;

  setUp(() {
    repository = MockTransactionRepository();
    service = AmountSuggestionService(repository);
  });

  group('AmountSuggestionService', () {
    const groupId = 'test_group';

    test('getRecentAmounts returns unique amounts >= 100', () async {
      final now = DateTime.now();
      final transactions = [
        Transaction(
          id: '1',
          groupId: groupId,
          type: TransactionType.expense,
          occurredAt: now,
          note: 'a',
          createdAt: now,
          updatedAt: now,
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 1000,
            splitType: SplitType.equal,
            participants: [],
          ),
        ),
        Transaction(
          id: '2',
          groupId: groupId,
          type: TransactionType.expense,
          occurredAt: now.subtract(const Duration(minutes: 1)),
          note: 'b',
          createdAt: now,
          updatedAt: now,
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 1000, // Duplicate
            splitType: SplitType.equal,
            participants: [],
          ),
        ),
        Transaction(
          id: '3',
          groupId: groupId,
          type: TransactionType.expense,
          occurredAt: now.subtract(const Duration(minutes: 2)),
          note: 'c',
          createdAt: now,
          updatedAt: now,
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 50, // Too small
            splitType: SplitType.equal,
            participants: [],
          ),
        ),
        Transaction(
          id: '4',
          groupId: groupId,
          type: TransactionType.expense,
          occurredAt: now.subtract(const Duration(minutes: 3)),
          note: 'd',
          createdAt: now,
          updatedAt: now,
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 2000,
            splitType: SplitType.equal,
            participants: [],
          ),
        ),
      ];

      when(
        () => repository.getTransactionsByGroup(groupId, includeDeleted: false),
      ).thenAnswer((_) async => transactions);

      final result = await service.getRecentAmounts(groupId);

      expect(result, [1000, 2000]);
    });

    test('getFrequentAmounts returns sorted by frequency', () async {
      final now = DateTime.now();
      final transactions = [
        _createTx(groupId, 1000, now),
        _createTx(groupId, 1000, now),
        _createTx(groupId, 2000, now),
        _createTx(groupId, 2000, now),
        _createTx(groupId, 2000, now),
        _createTx(groupId, 500, now),
      ];

      when(
        () => repository.getTransactionsByGroup(groupId),
      ).thenAnswer((_) async => transactions);

      final result = await service.getFrequentAmounts(groupId);

      expect(result, [2000, 1000, 500]);
    });

    test('getSuggestions combines and prioritizes frequent', () async {
      final now = DateTime.now();
      // Frequent: 2000 (3x), 1000 (2x)
      // Recent: 3000, 2000, 1000
      final transactions = [
        _createTx(groupId, 3000, now), // Most recent
        _createTx(groupId, 2000, now.subtract(const Duration(minutes: 1))),
        _createTx(groupId, 2000, now.subtract(const Duration(minutes: 2))),
        _createTx(groupId, 2000, now.subtract(const Duration(minutes: 3))),
        _createTx(groupId, 1000, now.subtract(const Duration(minutes: 4))),
        _createTx(groupId, 1000, now.subtract(const Duration(minutes: 5))),
      ];

      when(
        () => repository.getTransactionsByGroup(
          groupId,
          includeDeleted: any(named: 'includeDeleted'),
        ),
      ).thenAnswer((_) async => transactions);
      when(
        () => repository.getTransactionsByGroup(groupId),
      ).thenAnswer((_) async => transactions);

      final result = await service.getSuggestions(groupId);

      // Frequent are [2000, 1000, 3000] (3000 has freq 1)
      // Recent are [3000, 2000, 1000]
      // Combined: [2000, 1000, 3000]
      expect(result, containsAll([2000, 1000, 3000]));
      expect(result.first, 2000); // 2000 is definitely most frequent
    });
  });
}

Transaction _createTx(String groupId, int amount, DateTime occurredAt) {
  return Transaction(
    id: amount.toString() + occurredAt.toString(),
    groupId: groupId,
    type: TransactionType.expense,
    occurredAt: occurredAt,
    note: 'note',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    expenseDetail: ExpenseDetail(
      payerMemberId: 'm1',
      totalAmountMinor: amount,
      splitType: SplitType.equal,
      participants: [],
    ),
  );
}
