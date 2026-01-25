import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/transaction.dart';
import '../../../core/utils/money.dart';
import '../../../ui/components/empty_state.dart';
import '../../../ui/theme/app_theme.dart';
import '../../groups/presentation/groups_providers.dart';
import 'transactions_providers.dart';

class TransactionListScreen extends ConsumerWidget {
  final String groupId;

  const TransactionListScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsByGroupProvider(groupId));
    final membersAsync = ref.watch(membersByGroupProvider(groupId));
    final groupAsync = ref.watch(groupStreamProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              message: 'Add your first expense or transfer to get started.',
              actionLabel: 'Add Expense',
              onActionPressed: () =>
                  context.push('/group/$groupId/transactions/add-expense'),
            );
          }

          return membersAsync.when(
            data: (members) {
              final memberMap = {for (var m in members) m.id: m.displayName};

              return groupAsync.when(
                data: (group) {
                  final currencyCode = group?.currencyCode ?? 'USD';

                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(
                      transactionsByGroupProvider(groupId).future,
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppTheme.space8),
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return _TransactionListItem(
                          transaction: tx,
                          memberMap: memberMap,
                          currencyCode: currencyCode,
                          onTap: () => context.push(
                            '/group/$groupId/transactions/${tx.id}',
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMenu(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.add_shopping_cart,
                color: Colors.orange,
              ),
              title: const Text('Add Expense'),
              onTap: () {
                context.pop();
                context.push('/group/$groupId/transactions/add-expense');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync_alt, color: Colors.blue),
              title: const Text('Add Transfer'),
              onTap: () {
                context.pop();
                context.push('/group/$groupId/transactions/add-transfer');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final Map<String, String> memberMap;
  final String currencyCode;
  final VoidCallback onTap;

  const _TransactionListItem({
    required this.transaction,
    required this.memberMap,
    required this.currencyCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final amount = isExpense
        ? transaction.expenseDetail?.totalAmountMinor ?? 0
        : transaction.transferDetail?.amountMinor ?? 0;

    final dateStr = DateFormat.yMMMd().format(transaction.occurredAt);

    String subTitle = '';
    if (isExpense) {
      final payerName =
          memberMap[transaction.expenseDetail?.payerMemberId] ?? 'Unknown';
      final participantsCount =
          transaction.expenseDetail?.participants.length ?? 0;
      subTitle = 'Paid by $payerName for $participantsCount members';
    } else {
      final fromName =
          memberMap[transaction.transferDetail?.fromMemberId] ?? 'Unknown';
      final toName =
          memberMap[transaction.transferDetail?.toMemberId] ?? 'Unknown';
      subTitle = '$fromName → $toName';
    }

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isExpense
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.1),
        child: Icon(
          isExpense ? Icons.add_shopping_cart : Icons.sync_alt,
          color: isExpense ? Colors.orange : Colors.blue,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              transaction.note.isNotEmpty ? transaction.note : 'No note',
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          Text(
            MoneyUtils.format(amount, currencyCode: currencyCode),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.red[700] : Colors.blue[700],
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subTitle),
              Text(
                dateStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
          if (transaction.tags.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space4),
            Wrap(
              spacing: AppTheme.space4,
              children: transaction.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag.name,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
