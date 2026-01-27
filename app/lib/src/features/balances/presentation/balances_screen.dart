import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/components/skeletons/skeleton_list.dart';
import '../../../core/utils/haptics.dart';
import '../../groups/presentation/groups_providers.dart';
import '../services/balance_service.dart';

class BalancesScreen extends ConsumerWidget {
  final String groupId;

  const BalancesScreen({super.key, required this.groupId});

  Future<void> _onRefresh(WidgetRef ref) async {
    HapticsService.lightTap();
    ref.invalidate(groupBalancesProvider(groupId));
    await ref.read(groupBalancesProvider(groupId).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(groupBalancesProvider(groupId));
    final groupAsync = ref.watch(groupStreamProvider(groupId));
    final formatMoney = ref.watch(moneyFormatterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Balances')),
      body: groupAsync.when(
        data: (group) {
          final currency = group?.currencyCode ?? 'USD';
          return balancesAsync.when(
            data: (balances) {
              if (balances.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => _onRefresh(ref),
                  child: const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: AppTheme.space32),
                        child: Text('No members in this group'),
                      ),
                    ),
                  ),
                );
              }

              // Sort balances: creditors first, then settled, then debtors
              final sortedBalances = List.of(balances)
                ..sort((a, b) => b.netAmountMinor.compareTo(a.netAmountMinor));

              return RefreshIndicator(
                onRefresh: () => _onRefresh(ref),
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: sortedBalances.length,
                  itemBuilder: (context, index) {
                    final balance = sortedBalances[index];
                    final isSettled = balance.netAmountMinor == 0;
                    final isCreditor = balance.netAmountMinor > 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppTheme.space8),
                      child: ListTile(
                        title: Text(
                          balance.memberName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          isSettled
                              ? 'Settled'
                              : isCreditor
                              ? 'is owed'
                              : 'owes',
                        ),
                        trailing: Text(
                          formatMoney(
                            balance.netAmountMinor.abs(),
                            currencyCode: currency,
                          ),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSettled
                                ? null
                                : isCreditor
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SkeletonList(),
            error: (e, _) => Center(child: Text('Error loading balances: $e')),
          );
        },
        loading: () => const SkeletonList(),
        error: (e, _) => Center(child: Text('Error loading group: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/group/$groupId/settlements'),
        label: const Text('Settle Up'),
        icon: const Icon(Icons.payments_outlined),
      ),
    );
  }
}
