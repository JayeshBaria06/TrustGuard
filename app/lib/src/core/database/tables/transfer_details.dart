import 'package:drift/drift.dart';
import 'members.dart';
import 'transactions.dart';

class TransferDetails extends Table {
  TextColumn get txId => text().references(Transactions, #id)();
  TextColumn get fromMemberId => text().references(Members, #id)();
  TextColumn get toMemberId => text().references(Members, #id)();
  IntColumn get amountMinor => integer()();

  @override
  Set<Column> get primaryKey => {txId};
}
