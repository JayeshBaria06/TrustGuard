import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/core/database/repositories/member_repository.dart';
import 'package:trustguard/src/core/database/repositories/transaction_repository.dart';
import 'package:trustguard/src/core/models/member.dart';
import 'package:trustguard/src/core/models/tag.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/core/models/transaction_filter.dart';
import 'package:trustguard/src/core/models/expense.dart';
import 'package:trustguard/src/features/analytics/services/spending_analytics_service.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockMemberRepository extends Mock implements MemberRepository {}

void main() {
  late SpendingAnalyticsService service;
  late MockTransactionRepository mockTransactionRepository;
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockTransactionRepository = MockTransactionRepository();
    mockMemberRepository = MockMemberRepository();
    service = SpendingAnalyticsService(
      transactionRepository: mockTransactionRepository,
      memberRepository: mockMemberRepository,
    );

    registerFallbackValue(const TransactionFilter());
  });

  group('SpendingAnalyticsService', () {
    const groupId = 'group1';

    test('getSpendingByTag aggregates correctly', () async {
      const tag1 = Tag(id: 't1', groupId: groupId, name: 'Food');
      const tag2 = Tag(id: 't2', groupId: groupId, name: 'Transport');

      final transactions = [
        Transaction(
          id: '1',
          groupId: groupId,
          type: TransactionType.expense,
          occurredAt: DateTime.now(),
          note: 'Note 1',
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 1000,
            splitType: SplitType.equal,
            participants: [],
          ),
          tags: [tag1],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '2',
          groupId: groupId,
          type: TransactionType.expense,
          occurredAt: DateTime.now(),
          note: 'Note 2',
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 500,
            splitType: SplitType.equal,
            participants: [],
          ),
          tags: [tag1],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '3',
          groupId: groupId,
          type: TransactionType.expense,
          occurredAt: DateTime.now(),
          note: 'Note 3',
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 2000,
            splitType: SplitType.equal,
            participants: [],
          ),
          tags: [tag2],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '4',
          groupId: groupId,
          type: TransactionType.expense,
          occurredAt: DateTime.now(),
          note: 'Note 4',
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 300,
            splitType: SplitType.equal,
            participants: [],
          ),
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(
        () => mockTransactionRepository.getTransactionsByGroup(
          any(),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer((_) async => transactions);

      final result = await service.getSpendingByTag(groupId);

      expect(result['Food'], 1500);
      expect(result['Transport'], 2000);
      expect(result['Other'], 300);
    });

    test('getSpendingByMember aggregates correctly', () async {
      final members = [
        Member(
          id: 'm1',
          groupId: groupId,
          displayName: 'Alice',
          createdAt: DateTime.now(),
        ),
        Member(
          id: 'm2',
          groupId: groupId,
          displayName: 'Bob',
          createdAt: DateTime.now(),
        ),
      ];

      final transactions = [
        Transaction(
          id: '1',
          groupId: groupId,
          type: TransactionType.expense,
          occurredAt: DateTime.now(),
          note: 'Note 1',
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 1000,
            splitType: SplitType.equal,
            participants: [],
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '2',
          groupId: groupId,
          type: TransactionType.expense,
          occurredAt: DateTime.now(),
          note: 'Note 2',
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm2',
            totalAmountMinor: 500,
            splitType: SplitType.equal,
            participants: [],
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(
        () => mockTransactionRepository.getTransactionsByGroup(
          any(),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer((_) async => transactions);
      when(
        () => mockMemberRepository.getMembersByGroup(
          any(),
          includeRemoved: any(named: 'includeRemoved'),
        ),
      ).thenAnswer((_) async => members);

      final result = await service.getSpendingByMember(groupId);

      expect(result['Alice'], 1000);
      expect(result['Bob'], 500);
    });

    test('getMonthlyTrend returns correct months', () async {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final twoMonthsAgo = DateTime(now.year, now.month - 2, 1);

      final transactions = [
        Transaction(
          id: '1',
          groupId: groupId,
          type: TransactionType.expense,
          occurredAt: now,
          note: 'Note 1',
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 1000,
            splitType: SplitType.equal,
            participants: [],
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '2',
          groupId: groupId,
          type: TransactionType.expense,
          occurredAt: lastMonth,
          note: 'Note 2',
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 500,
            splitType: SplitType.equal,
            participants: [],
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(
        () => mockTransactionRepository.getTransactionsByGroup(
          any(),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer((_) async => transactions);

      final result = await service.getMonthlyTrend(groupId, 3);

      expect(result.length, 3);
      // Sorted ascending
      expect(result[0].month.year, twoMonthsAgo.year);
      expect(result[0].month.month, twoMonthsAgo.month);
      expect(result[0].totalAmountMinor, 0);

      expect(result[1].month.year, lastMonth.year);
      expect(result[1].month.month, lastMonth.month);
      expect(result[1].totalAmountMinor, 500);

      expect(result[2].month.year, now.year);
      expect(result[2].month.month, now.month);
      expect(result[2].totalAmountMinor, 1000);
    });

    test('Empty data returns empty map or zeroed trend', () async {
      when(
        () => mockTransactionRepository.getTransactionsByGroup(
          any(),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockMemberRepository.getMembersByGroup(
          any(),
          includeRemoved: any(named: 'includeRemoved'),
        ),
      ).thenAnswer((_) async => []);

      final tagResult = await service.getSpendingByTag(groupId);
      final memberResult = await service.getSpendingByMember(groupId);
      final trendResult = await service.getMonthlyTrend(groupId, 3);

      expect(tagResult, isEmpty);
      expect(memberResult, isEmpty);
      expect(trendResult.every((m) => m.totalAmountMinor == 0), true);
    });

    test('Date filtering works correctly', () async {
      final startDate = DateTime(2023, 1, 1);
      final endDate = DateTime(2023, 12, 31);

      when(
        () => mockTransactionRepository.getTransactionsByGroup(
          any(),
          filter: any(named: 'filter'),
        ),
      ).thenAnswer((_) async => []);

      await service.getSpendingByTag(
        groupId,
        startDate: startDate,
        endDate: endDate,
      );

      verify(
        () => mockTransactionRepository.getTransactionsByGroup(
          groupId,
          filter: any(
            named: 'filter',
            that: predicate<TransactionFilter>(
              (f) => f.startDate == startDate && f.endDate == endDate,
            ),
          ),
        ),
      ).called(1);
    });
  });
}
