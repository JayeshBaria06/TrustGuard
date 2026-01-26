import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/models/transaction.dart';
import '../../../ui/theme/app_theme.dart';
import '../../groups/presentation/groups_providers.dart';
import 'transactions_providers.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String groupId;
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.groupId,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionProvider(transactionId));
    final groupAsync = ref.watch(groupStreamProvider(groupId));
    final membersAsync = ref.watch(membersByGroupProvider(groupId));
    final formatMoney = ref.watch(moneyFormatterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          transactionAsync.when(
            data: (tx) => tx != null
                ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      if (tx.type == TransactionType.expense) {
                        context.push(
                          '/group/$groupId/transactions/add-expense?txId=$transactionId',
                        );
                      } else {
                        context.push(
                          '/group/$groupId/transactions/add-transfer?txId=$transactionId',
                        );
                      }
                    },
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: transactionAsync.when(
        data: (tx) {
          if (tx == null) {
            return const Center(child: Text('Transaction not found'));
          }

          return groupAsync.when(
            data: (group) {
              final currency = group?.currencyCode ?? 'USD';
              return membersAsync.when(
                data: (members) {
                  final memberMap = {
                    for (var m in members) m.id: m.displayName,
                  };
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, tx, currency, formatMoney),
                        const Divider(height: AppTheme.space32),
                        _buildInfoSection(context, tx, memberMap),
                        const SizedBox(height: AppTheme.space24),
                        if (tx.type == TransactionType.expense)
                          _buildSplitSection(
                            context,
                            tx,
                            memberMap,
                            currency,
                            formatMoney,
                          ),
                        if (tx.tags.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.space24),
                          _buildTagsSection(context, tx),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Error loading members: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading group: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Transaction tx,
    String currency,
    MoneyFormatter formatMoney,
  ) {
    final amount = tx.type == TransactionType.expense
        ? tx.expenseDetail?.totalAmountMinor ?? 0
        : tx.transferDetail?.amountMinor ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              tx.type == TransactionType.expense
                  ? Icons.shopping_cart_outlined
                  : Icons.swap_horiz,
              color: tx.type == TransactionType.expense
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppTheme.space8),
            Text(
              tx.type == TransactionType.expense ? 'Expense' : 'Transfer',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: tx.type == TransactionType.expense
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          formatMoney(amount, currencyCode: currency),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (tx.note.isNotEmpty) ...[
          const SizedBox(height: AppTheme.space8),
          Text(tx.note, style: Theme.of(context).textTheme.titleLarge),
        ],
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    Transaction tx,
    Map<String, String> memberMap,
  ) {
    return Column(
      children: [
        _buildInfoRow(
          context,
          Icons.calendar_today_outlined,
          'Date',
          DateFormat.yMMMMd().add_jm().format(tx.occurredAt),
        ),
        const SizedBox(height: AppTheme.space12),
        if (tx.type == TransactionType.expense)
          _buildInfoRow(
            context,
            Icons.person_outline,
            'Paid by',
            memberMap[tx.expenseDetail?.payerMemberId] ?? 'Unknown Member',
          ),
        if (tx.type == TransactionType.transfer) ...[
          _buildInfoRow(
            context,
            Icons.person_outline,
            'From',
            memberMap[tx.transferDetail?.fromMemberId] ?? 'Unknown Member',
          ),
          const SizedBox(height: AppTheme.space12),
          _buildInfoRow(
            context,
            Icons.person_outline,
            'To',
            memberMap[tx.transferDetail?.toMemberId] ?? 'Unknown Member',
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).hintColor),
        const SizedBox(width: AppTheme.space12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ],
    );
  }

  Widget _buildSplitSection(
    BuildContext context,
    Transaction tx,
    Map<String, String> memberMap,
    String currency,
    MoneyFormatter formatMoney,
  ) {
    final participants = tx.expenseDetail?.participants ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Split details', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTheme.space8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: participants.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = participants[index];
              return ListTile(
                title: Text(memberMap[p.memberId] ?? 'Unknown Member'),
                trailing: Text(
                  formatMoney(p.owedAmountMinor, currencyCode: currency),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(BuildContext context, Transaction tx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTheme.space8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tx.tags.map((tag) {
            return Chip(
              label: Text(tag.name),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
          'This will remove the transaction from balances and history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.softDeleteTransaction(transactionId);
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () =>
                  repository.undoSoftDeleteTransaction(transactionId),
            ),
          ),
        );
      }
    }
  }
}
