import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/repositories/tag_repository.dart';
import 'package:trustguard/src/core/models/tag.dart' as model;
import 'package:trustguard/src/core/models/transaction.dart';

void main() {
  late AppDatabase db;
  late TagRepository repository;

  const groupId = 'group-1';
  const tagId = 'tag-1';
  const testTag = model.Tag(id: tagId, groupId: groupId, name: 'Food');

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftTagRepository(db);

    // Create a group for foreign key constraints
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: groupId,
            name: 'Test Group',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('TagRepository', () {
    test('createTag and getTagsByGroup', () async {
      await repository.createTag(testTag);
      final tags = await repository.getTagsByGroup(groupId);
      expect(tags, hasLength(1));
      expect(tags.first, equals(testTag));
    });

    test('createTag throws on duplicate name in same group', () async {
      await repository.createTag(testTag);
      final duplicateTag = testTag.copyWith(id: 'tag-2');

      expect(() => repository.createTag(duplicateTag), throwsException);
    });

    test('watchTagsByGroup emits updates', () async {
      final stream = repository.watchTagsByGroup(groupId);
      expect(
        stream,
        emitsInOrder([
          <model.Tag>[],
          [testTag],
        ]),
      );

      await repository.createTag(testTag);
    });

    test('updateTag updates name', () async {
      await repository.createTag(testTag);
      final updatedTag = testTag.copyWith(name: 'Groceries');

      await repository.updateTag(updatedTag);
      final tags = await repository.getTagsByGroup(groupId);
      expect(tags.first.name, equals('Groceries'));
    });

    test('updateTag throws on duplicate name with another tag', () async {
      await repository.createTag(testTag);
      final tag2 = const model.Tag(
        id: 'tag-2',
        groupId: groupId,
        name: 'Travel',
      );
      await repository.createTag(tag2);

      final updatedTag = tag2.copyWith(name: 'Food');
      expect(() => repository.updateTag(updatedTag), throwsException);
    });

    test('deleteTag removes tag and associations', () async {
      await repository.createTag(testTag);

      // Create a transaction and associate tag
      const txId = 'tx-1';
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: txId,
              groupId: groupId,
              type: TransactionType.expense,
              note: 'Test note',
              occurredAt: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      await repository.assignTagsToTransaction(txId, [tagId]);

      await repository.deleteTag(tagId);

      final tags = await repository.getTagsByGroup(groupId);
      expect(tags, isEmpty);

      final txTags = await repository.getTagsByTransaction(txId);
      expect(txTags, isEmpty);
    });

    test('assignTagsToTransaction and getTagsByTransaction', () async {
      await repository.createTag(testTag);
      final tag2 = const model.Tag(
        id: 'tag-2',
        groupId: groupId,
        name: 'Travel',
      );
      await repository.createTag(tag2);

      const txId = 'tx-1';
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: txId,
              groupId: groupId,
              type: TransactionType.expense,
              note: 'Test note',
              occurredAt: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      await repository.assignTagsToTransaction(txId, [tagId, 'tag-2']);

      final assignedTags = await repository.getTagsByTransaction(txId);
      expect(assignedTags, hasLength(2));
      expect(assignedTags.map((t) => t.id), containsAll([tagId, 'tag-2']));

      // Re-assign (replace)
      await repository.assignTagsToTransaction(txId, [tagId]);
      final updatedAssignedTags = await repository.getTagsByTransaction(txId);
      expect(updatedAssignedTags, hasLength(1));
      expect(updatedAssignedTags.first.id, equals(tagId));
    });

    test('updateTagOrder updates indices and queries return sorted', () async {
      await repository.createTag(
        const model.Tag(id: 'tag-1', groupId: groupId, name: 'C'),
      );
      await repository.createTag(
        const model.Tag(id: 'tag-2', groupId: groupId, name: 'A'),
      );
      await repository.createTag(
        const model.Tag(id: 'tag-3', groupId: groupId, name: 'B'),
      );

      // Initial order should be alphabetical because orderIndex is default 0
      var tags = await repository.getTagsByGroup(groupId);
      expect(tags.map((t) => t.name).toList(), equals(['A', 'B', 'C']));

      // Update order to C, B, A
      await repository.updateTagOrder(groupId, ['tag-1', 'tag-3', 'tag-2']);

      tags = await repository.getTagsByGroup(groupId);
      expect(
        tags.map((t) => t.id).toList(),
        equals(['tag-1', 'tag-3', 'tag-2']),
      );
      expect(tags.map((t) => t.name).toList(), equals(['C', 'B', 'A']));
    });
  });
}
