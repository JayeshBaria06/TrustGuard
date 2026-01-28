import 'package:drift/drift.dart';
import '../database.dart';
import '../mappers/expense_template_mapper.dart';
import '../../models/expense_template.dart' as model;

abstract class TemplateRepository {
  Future<List<model.ExpenseTemplate>> getTemplatesByGroup(String groupId);
  Stream<List<model.ExpenseTemplate>> watchTemplatesByGroup(String groupId);
  Future<model.ExpenseTemplate?> getTemplateById(String id);
  Future<void> createTemplate(model.ExpenseTemplate template);
  Future<void> updateTemplate(model.ExpenseTemplate template);
  Future<void> deleteTemplate(String id);
  Future<void> updateUsageCount(String id);
  Future<void> updateTemplateOrder(String groupId, List<String> orderedIds);
}

class DriftTemplateRepository implements TemplateRepository {
  final AppDatabase _db;

  DriftTemplateRepository(this._db);

  @override
  Future<List<model.ExpenseTemplate>> getTemplatesByGroup(
    String groupId,
  ) async {
    final query = _db.select(_db.expenseTemplates)
      ..where((t) => t.groupId.equals(groupId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.orderIndex, mode: OrderingMode.asc),
      ]);

    final rows = await query.get();
    return rows.map((row) => row.toModel()).toList();
  }

  @override
  Stream<List<model.ExpenseTemplate>> watchTemplatesByGroup(String groupId) {
    final query = _db.select(_db.expenseTemplates)
      ..where((t) => t.groupId.equals(groupId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.orderIndex, mode: OrderingMode.asc),
      ]);

    return query.watch().map(
      (rows) => rows.map((row) => row.toModel()).toList(),
    );
  }

  @override
  Future<model.ExpenseTemplate?> getTemplateById(String id) async {
    final query = _db.select(_db.expenseTemplates)
      ..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row?.toModel();
  }

  @override
  Future<void> createTemplate(model.ExpenseTemplate template) async {
    await _db.into(_db.expenseTemplates).insert(template.toCompanion());
  }

  @override
  Future<void> updateTemplate(model.ExpenseTemplate template) async {
    await (_db.update(
      _db.expenseTemplates,
    )..where((t) => t.id.equals(template.id))).write(template.toCompanion());
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await (_db.delete(
      _db.expenseTemplates,
    )..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> updateUsageCount(String id) async {
    // We need to fetch the current count first, or use a custom query to increment
    // Since Drift doesn't support 'usageCount = usageCount + 1' easily in Dart API without custom expression,
    // we'll use a custom expression or read-update-write.
    // Read-update-write is safer for logic, but less atomic without transaction.
    // Let's use a transaction.
    await _db.transaction(() async {
      final template = await (_db.select(
        _db.expenseTemplates,
      )..where((t) => t.id.equals(id))).getSingleOrNull();

      if (template != null) {
        await (_db.update(
          _db.expenseTemplates,
        )..where((t) => t.id.equals(id))).write(
          ExpenseTemplatesCompanion(usageCount: Value(template.usageCount + 1)),
        );
      }
    });
  }

  @override
  Future<void> updateTemplateOrder(
    String groupId,
    List<String> orderedIds,
  ) async {
    await _db.transaction(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.expenseTemplates)
              ..where((t) => t.id.equals(orderedIds[i])))
            .write(ExpenseTemplatesCompanion(orderIndex: Value(i)));
      }
    });
  }
}
