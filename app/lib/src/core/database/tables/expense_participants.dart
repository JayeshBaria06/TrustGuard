import 'package:drift/drift.dart';
import 'transactions.dart';
import 'members.dart';

class ExpenseParticipants extends Table {
  TextColumn get txId => text().references(Transactions, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get owedAmountMinor => integer()();

  @override
  Set<Column> get primaryKey => {txId, memberId};
}
