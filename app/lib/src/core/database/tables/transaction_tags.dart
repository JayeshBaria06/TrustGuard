import 'package:drift/drift.dart';
import 'transactions.dart';
import 'tags.dart';

class TransactionTags extends Table {
  TextColumn get txId => text().references(Transactions, #id)();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {txId, tagId};
}
