import 'package:drift/drift.dart';
import 'transactions.dart';

/// Table for transaction attachments (scaffolded for v1.1+).
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get txId => text().references(Transactions, #id)();
  TextColumn get path => text()();
  TextColumn get mime => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
