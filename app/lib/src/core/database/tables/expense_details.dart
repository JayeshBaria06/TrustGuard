import 'package:drift/drift.dart';
import '../../models/expense.dart';
import 'transactions.dart';
import 'members.dart';

class ExpenseDetails extends Table {
  TextColumn get txId => text().references(Transactions, #id)();
  TextColumn get payerMemberId => text().references(Members, #id)();
  IntColumn get totalAmountMinor => integer()();
  TextColumn get splitType => textEnum<SplitType>()();
  TextColumn get splitMetaJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {txId};
}
