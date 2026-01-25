import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/models/transaction.dart';

/// Provider for the list of transactions in a group.
final transactionsByGroupProvider = StreamProvider.autoDispose
    .family<List<Transaction>, String>((ref, groupId) {
      final repository = ref.watch(transactionRepositoryProvider);
      return repository.watchTransactionsByGroup(groupId);
    });
