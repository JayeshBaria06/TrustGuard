import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/models/transaction.dart';

/// Service that provides smart amount suggestions based on recent and frequent transactions.
class AmountSuggestionService {
  final TransactionRepository _repository;

  AmountSuggestionService(this._repository);

  /// Returns recent unique amounts used in the group.
  Future<List<int>> getRecentAmounts(String groupId, {int limit = 5}) async {
    final transactions = await _repository.getTransactionsByGroup(
      groupId,
      includeDeleted: false,
    );

    final amounts = <int>{};
    for (final tx in transactions) {
      final amount = _getAmount(tx);
      // Only suggest reasonable amounts (at least 1.00)
      if (amount != null && amount >= 100) {
        amounts.add(amount);
        if (amounts.length >= limit) break;
      }
    }
    return amounts.toList();
  }

  /// Returns most frequently used amounts in the group.
  Future<List<int>> getFrequentAmounts(String groupId, {int limit = 5}) async {
    final transactions = await _repository.getTransactionsByGroup(groupId);

    final frequencyMap = <int, int>{};
    for (final tx in transactions) {
      final amount = _getAmount(tx);
      if (amount != null && amount >= 100) {
        frequencyMap[amount] = (frequencyMap[amount] ?? 0) + 1;
      }
    }

    final sortedEntries = frequencyMap.entries.toList()
      ..sort((a, b) {
        final frequencyCompare = b.value.compareTo(a.value);
        if (frequencyCompare != 0) return frequencyCompare;
        // Secondary sort by amount descending if frequency is same
        return b.key.compareTo(a.key);
      });

    return sortedEntries.take(limit).map((e) => e.key).toList();
  }

  /// Returns a combined list of suggestions for the group.
  Future<List<int>> getSuggestions(String groupId) async {
    // Combine frequent and recent amounts
    final frequent = await getFrequentAmounts(groupId, limit: 10);
    final recent = await getRecentAmounts(groupId, limit: 10);

    // Using a LinkedHashSet implicitly via the spread operator in a Set literal
    // Frequent amounts are prioritized
    final combined = <int>{...frequent, ...recent};

    // Return top 8 unique suggestions
    return combined.take(8).toList();
  }

  int? _getAmount(Transaction tx) {
    if (tx.type == TransactionType.expense) {
      return tx.expenseDetail?.totalAmountMinor;
    } else if (tx.type == TransactionType.transfer) {
      return tx.transferDetail?.amountMinor;
    }
    return null;
  }
}
