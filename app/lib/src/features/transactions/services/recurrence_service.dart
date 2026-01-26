import 'package:uuid/uuid.dart';
import '../../../core/database/repositories/recurring_transaction_repository.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/models/recurring_transaction.dart';

class RecurrenceService {
  final RecurringTransactionRepository _recurringRepo;
  final TransactionRepository _transactionRepo;

  RecurrenceService({
    required RecurringTransactionRepository recurringRepo,
    required TransactionRepository transactionRepo,
  }) : _recurringRepo = recurringRepo,
       _transactionRepo = transactionRepo;

  Future<void> checkAndCreateDueTransactions() async {
    final now = DateTime.now();
    final dueRecurrings = await _recurringRepo.getDueRecurrings(now);

    for (final recurring in dueRecurrings) {
      final template = await _transactionRepo.getTransactionById(
        recurring.templateTransactionId,
      );
      if (template == null) {
        // Template missing, deactivate to prevent endless attempts
        await _recurringRepo.deactivateRecurring(recurring.id);
        continue;
      }

      // Clone transaction
      final newTx = template.copyWith(
        id: const Uuid().v4(),
        occurredAt: recurring.nextOccurrence,
        createdAt: now,
        updatedAt: now,
      );

      await _transactionRepo.createTransaction(newTx);

      // Calculate next occurrence
      final nextOccurrence = calculateNextOccurrence(
        recurring.nextOccurrence,
        recurring.frequency,
      );

      // Check if we passed the end date
      if (recurring.endDate != null &&
          nextOccurrence.isAfter(recurring.endDate!)) {
        await _recurringRepo.deactivateRecurring(recurring.id);
      } else {
        await _recurringRepo.updateNextOccurrence(recurring.id, nextOccurrence);
      }
    }
  }

  DateTime calculateNextOccurrence(
    DateTime current,
    RecurrenceFrequency frequency,
  ) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return current.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return current.add(const Duration(days: 7));
      case RecurrenceFrequency.biweekly:
        return current.add(const Duration(days: 14));
      case RecurrenceFrequency.monthly:
        // Simple month increment
        return DateTime(
          current.year,
          current.month + 1,
          current.day,
          current.hour,
          current.minute,
        );
      case RecurrenceFrequency.yearly:
        return DateTime(
          current.year + 1,
          current.month,
          current.day,
          current.hour,
          current.minute,
        );
    }
  }
}
