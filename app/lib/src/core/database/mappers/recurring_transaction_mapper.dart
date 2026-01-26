import 'package:drift/drift.dart';
import '../database.dart';
import '../../models/recurring_transaction.dart' as model;

class RecurringTransactionMapper {
  static model.RecurringTransaction toModel(RecurringTransaction data) {
    return model.RecurringTransaction(
      id: data.id,
      groupId: data.groupId,
      templateTransactionId: data.templateTransactionId,
      frequency: data.frequency,
      nextOccurrence: data.nextOccurrence,
      endDate: data.endDate,
      isActive: data.isActive,
      createdAt: data.createdAt,
    );
  }

  static RecurringTransactionsCompanion toCompanion(
    model.RecurringTransaction domain,
  ) {
    return RecurringTransactionsCompanion(
      id: Value(domain.id),
      groupId: Value(domain.groupId),
      templateTransactionId: Value(domain.templateTransactionId),
      frequency: Value(domain.frequency),
      nextOccurrence: Value(domain.nextOccurrence),
      endDate: Value(domain.endDate),
      isActive: Value(domain.isActive),
      createdAt: Value(domain.createdAt),
    );
  }
}
