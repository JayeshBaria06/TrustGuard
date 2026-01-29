import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/balance.dart';
import '../../../core/models/transaction.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../transactions/presentation/transactions_providers.dart';

import '../../../core/models/member.dart';

class BalanceService {
  /// Computes the net balance for each member in a group.
  /// Positive netAmountMinor means the member is a creditor (owed money).
  /// Negative netAmountMinor means the member is a debtor (owes money).
  static List<MemberBalance> computeBalances({
    required List<Member> members,
    required List<Transaction> transactions,
  }) {
    final memberIds = members.map((m) => m.id).toList();
    final netAmounts = {for (var id in memberIds) id: 0};

    for (final tx in transactions) {
      if (tx.deletedAt != null) continue;

      if (tx.type == TransactionType.expense && tx.expenseDetail != null) {
        final detail = tx.expenseDetail!;
        // Payer gets the total amount as "credit"
        netAmounts[detail.payerMemberId] =
            (netAmounts[detail.payerMemberId] ?? 0) + detail.totalAmountMinor;

        // Each participant gets their owed amount as "debt"
        for (final participant in detail.participants) {
          netAmounts[participant.memberId] =
              (netAmounts[participant.memberId] ?? 0) -
              participant.owedAmountMinor;
        }
      } else if (tx.type == TransactionType.transfer &&
          tx.transferDetail != null) {
        final detail = tx.transferDetail!;
        // From member gets amount as "credit" (they paid someone)
        netAmounts[detail.fromMemberId] =
            (netAmounts[detail.fromMemberId] ?? 0) + detail.amountMinor;

        // To member gets amount as "debt" (they received money)
        netAmounts[detail.toMemberId] =
            (netAmounts[detail.toMemberId] ?? 0) - detail.amountMinor;
      }
    }

    return members.map((member) {
      final amount = netAmounts[member.id] ?? 0;
      return MemberBalance(
        memberId: member.id,
        memberName: member.displayName,
        netAmountMinor: amount,
        isCreditor: amount > 0,
        member: member,
      );
    }).toList();
  }
}

/// Provider that computes and watches balances for a group.
final groupBalancesProvider = StreamProvider.autoDispose
    .family<List<MemberBalance>, String>((ref, groupId) {
      final transactionsAsync = ref.watch(transactionsByGroupProvider(groupId));
      final membersAsync = ref.watch(membersByGroupProvider(groupId));

      return transactionsAsync.when(
        data: (transactions) => membersAsync.when(
          data: (members) {
            return Stream.value(
              BalanceService.computeBalances(
                members: members,
                transactions: transactions,
              ),
            );
          },
          loading: () => const Stream.empty(),
          error: (e, s) => Stream.error(e, s),
        ),
        loading: () => const Stream.empty(),
        error: (e, s) => Stream.error(e, s),
      );
    });
