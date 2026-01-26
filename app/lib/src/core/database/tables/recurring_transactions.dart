import 'package:drift/drift.dart';
import '../../models/recurring_transaction.dart';
import 'groups.dart';
import 'transactions.dart';

class RecurringTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get templateTransactionId =>
      text().references(Transactions, #id)();
  TextColumn get frequency => textEnum<RecurrenceFrequency>()();
  DateTimeColumn get nextOccurrence => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
