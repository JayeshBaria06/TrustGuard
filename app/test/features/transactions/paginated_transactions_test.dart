import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/repositories/transaction_repository.dart';
import 'package:trustguard/src/core/models/transaction.dart' as model;
import 'package:trustguard/src/core/models/expense.dart' as model;
import 'package:trustguard/src/core/models/transaction_filter.dart';
import 'package:trustguard/src/features/transactions/providers/paginated_transactions_provider.dart';
import 'package:trustguard/src/features/transactions/presentation/transactions_providers.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftTransactionRepository(db);

    // Setup: Create a group and members
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: 'group-1',
            name: 'Test Group',
            currencyCode: 'USD',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'member-1',
            groupId: 'group-1',
            displayName: 'Member 1',
            createdAt: DateTime(2026, 1, 1),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedTransactions(int count) async {
    final now = DateTime(2026, 1, 26, 10);
    for (var i = 0; i < count; i++) {
      final tx = model.Transaction(
        id: 'tx-$i',
        groupId: 'group-1',
        type: model.TransactionType.expense,
        occurredAt: now.subtract(Duration(minutes: i)),
        note: 'Note $i',
        createdAt: now,
        updatedAt: now,
        expenseDetail: model.ExpenseDetail(
          payerMemberId: 'member-1',
          totalAmountMinor: 100 * (i + 1),
          splitType: model.SplitType.equal,
          participants: [
            model.ExpenseParticipant(
              memberId: 'member-1',
              owedAmountMinor: 100 * (i + 1),
            ),
          ],
        ),
      );
      await repository.createTransaction(tx);
    }
  }

  group('PaginatedTransactionsNotifier', () {
    test('initial load fetches first page', () async {
      await seedTransactions(25);
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final state = await container.read(
        paginatedTransactionsProvider('group-1').future,
      );

      expect(state.transactions, hasLength(20));
      expect(state.hasMore, isTrue);
      expect(state.totalCount, equals(25));
      expect(state.transactions.first.id, equals('tx-0'));
      expect(state.transactions.last.id, equals('tx-19'));
    });

    test('loadMore appends next page', () async {
      await seedTransactions(25);
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
      );

      // Trigger initial load
      await container.read(paginatedTransactionsProvider('group-1').future);

      // Load more
      await container
          .read(paginatedTransactionsProvider('group-1').notifier)
          .loadMore();

      final state = container
          .read(paginatedTransactionsProvider('group-1'))
          .value!;
      expect(state.transactions, hasLength(25));
      expect(state.hasMore, isFalse);
      expect(state.totalCount, equals(25));
      expect(state.transactions[20].id, equals('tx-20'));
    });

    test('refresh resets pagination', () async {
      await seedTransactions(25);
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
      );

      await container.read(paginatedTransactionsProvider('group-1').future);
      await container
          .read(paginatedTransactionsProvider('group-1').notifier)
          .loadMore();

      expect(
        container
            .read(paginatedTransactionsProvider('group-1'))
            .value!
            .transactions,
        hasLength(25),
      );

      await container
          .read(paginatedTransactionsProvider('group-1').notifier)
          .refresh();

      final state = container
          .read(paginatedTransactionsProvider('group-1'))
          .value!;
      expect(state.transactions, hasLength(20));
      expect(state.hasMore, isTrue);
    });

    test('filter change resets pagination', () async {
      await seedTransactions(25);
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
      );

      // Initial load
      await container.read(paginatedTransactionsProvider('group-1').future);
      await container
          .read(paginatedTransactionsProvider('group-1').notifier)
          .loadMore();
      expect(
        container
            .read(paginatedTransactionsProvider('group-1'))
            .value!
            .transactions,
        hasLength(25),
      );

      // Change filter
      container.read(transactionFilterProvider('group-1').notifier).state =
          const TransactionFilter(searchQuery: 'Note 0');

      // Wait for provider to rebuild (AsyncNotifier watches filter)
      final filteredState = await container.read(
        paginatedTransactionsProvider('group-1').future,
      );

      expect(filteredState.transactions, hasLength(1));
      expect(filteredState.transactions.first.note, equals('Note 0'));
      expect(filteredState.totalCount, equals(1));
      expect(filteredState.hasMore, isFalse);
    });

    test('empty group returns empty state', () async {
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final state = await container.read(
        paginatedTransactionsProvider('group-1').future,
      );

      expect(state.transactions, isEmpty);
      expect(state.hasMore, isFalse);
      expect(state.totalCount, equals(0));
    });
  });
}
