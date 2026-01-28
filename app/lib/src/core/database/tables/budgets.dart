import 'package:drift/drift.dart';
import 'groups.dart';

@DataClassName('BudgetEntity')
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get name => text()();
  IntColumn get limitMinor => integer()();
  TextColumn get currencyCode => text()();
  TextColumn get period => text()(); // weekly, monthly, yearly, custom
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get tagId => text().nullable()();
  IntColumn get alertThreshold => integer().withDefault(const Constant(80))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
