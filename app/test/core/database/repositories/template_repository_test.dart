import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/repositories/template_repository.dart';
import 'package:trustguard/src/core/models/expense_template.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late DriftTemplateRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftTemplateRepository(db);

    // Create required dependencies for foreign keys
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: 'group1',
            name: 'Test Group',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        );

    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'user1',
            groupId: 'group1',
            displayName: 'Test User',
            createdAt: DateTime.now(),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('TemplateRepository', () {
    test('createTemplate adds a new template', () async {
      final template = ExpenseTemplate(
        id: const Uuid().v4(),
        groupId: 'group1',
        name: 'Test Template',
        currencyCode: 'USD',
        payerId: 'user1',
        splitType: SplitType.equal,
        tagIds: [],
        orderIndex: 0,
        createdAt: DateTime.now(),
        usageCount: 0,
      );

      await repository.createTemplate(template);

      final retrieved = await repository.getTemplateById(template.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Test Template');
    });

    test(
      'getTemplatesByGroup returns templates ordered by usage then orderIndex',
      () async {
        final t1 = ExpenseTemplate(
          id: 't1',
          groupId: 'group1',
          name: 'Low Usage',
          currencyCode: 'USD',
          payerId: 'user1',
          splitType: SplitType.equal,
          tagIds: [],
          orderIndex: 0,
          createdAt: DateTime.now(),
          usageCount: 0,
        );

        final t2 = ExpenseTemplate(
          id: 't2',
          groupId: 'group1',
          name: 'High Usage',
          currencyCode: 'USD',
          payerId: 'user1',
          splitType: SplitType.equal,
          tagIds: [],
          orderIndex: 0,
          createdAt: DateTime.now(),
          usageCount: 5,
        );

        final t3 = ExpenseTemplate(
          id: 't3',
          groupId: 'group1',
          name: 'Low Usage 2',
          currencyCode: 'USD',
          payerId: 'user1',
          splitType: SplitType.equal,
          tagIds: [],
          orderIndex: 1, // Higher index than t1
          createdAt: DateTime.now(),
          usageCount: 0,
        );

        await repository.createTemplate(t1);
        await repository.createTemplate(t2);
        await repository.createTemplate(t3);

        final templates = await repository.getTemplatesByGroup('group1');
        expect(templates.length, 3);
        expect(templates[0].id, 't2'); // Highest usage
        expect(templates[1].id, 't1'); // Usage 0, Order 0
        expect(templates[2].id, 't3'); // Usage 0, Order 1
      },
    );

    test('updateUsageCount increments usage count', () async {
      final template = ExpenseTemplate(
        id: 't1',
        groupId: 'group1',
        name: 'Test',
        currencyCode: 'USD',
        payerId: 'user1',
        splitType: SplitType.equal,
        tagIds: [],
        orderIndex: 0,
        createdAt: DateTime.now(),
        usageCount: 0,
      );

      await repository.createTemplate(template);
      await repository.updateUsageCount('t1');

      final retrieved = await repository.getTemplateById('t1');
      expect(retrieved!.usageCount, 1);
    });

    test('deleteTemplate removes the template', () async {
      final template = ExpenseTemplate(
        id: 't1',
        groupId: 'group1',
        name: 'Test',
        currencyCode: 'USD',
        payerId: 'user1',
        splitType: SplitType.equal,
        tagIds: [],
        orderIndex: 0,
        createdAt: DateTime.now(),
        usageCount: 0,
      );

      await repository.createTemplate(template);
      await repository.deleteTemplate('t1');

      final retrieved = await repository.getTemplateById('t1');
      expect(retrieved, isNull);
    });

    test('updateTemplateOrder updates indices', () async {
      final t1 = ExpenseTemplate(
        id: 't1',
        groupId: 'group1',
        name: 'Template 1',
        currencyCode: 'USD',
        payerId: 'user1',
        splitType: SplitType.equal,
        tagIds: [],
        orderIndex: 0,
        createdAt: DateTime.now(),
        usageCount: 0,
      );

      final t2 = ExpenseTemplate(
        id: 't2',
        groupId: 'group1',
        name: 'Template 2',
        currencyCode: 'USD',
        payerId: 'user1',
        splitType: SplitType.equal,
        tagIds: [],
        orderIndex: 1,
        createdAt: DateTime.now(),
        usageCount: 0,
      );

      await repository.createTemplate(t1);
      await repository.createTemplate(t2);

      // Swap order
      await repository.updateTemplateOrder('group1', ['t2', 't1']);

      final updatedT1 = await repository.getTemplateById('t1');
      final updatedT2 = await repository.getTemplateById('t2');

      expect(updatedT1!.orderIndex, 1);
      expect(updatedT2!.orderIndex, 0);
    });
  });
}
