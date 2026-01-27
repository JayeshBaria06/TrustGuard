import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/repositories/group_repository.dart';
import 'package:trustguard/src/core/database/repositories/member_repository.dart';
import 'package:trustguard/src/core/models/group.dart' as model_group;
import 'package:trustguard/src/core/models/member.dart' as model_member;

void main() {
  late AppDatabase db;
  late MemberRepository repository;
  late GroupRepository groupRepository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftMemberRepository(db);
    groupRepository = DriftGroupRepository(db);

    // Create a group first for foreign key constraints
    await groupRepository.createGroup(
      model_group.Group(
        id: 'group-1',
        name: 'Test Group',
        currencyCode: 'USD',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('MemberRepository', () {
    final testMember = model_member.Member(
      id: 'member-1',
      groupId: 'group-1',
      displayName: 'Test Member',
      createdAt: DateTime(2026, 1, 1),
    );

    test('createMember and getMemberById', () async {
      await repository.createMember(testMember);
      final member = await repository.getMemberById('member-1');
      expect(member, equals(testMember));
    });

    test('getMembersByGroup and watchMembersByGroup', () async {
      await repository.createMember(testMember);
      await repository.createMember(
        testMember.copyWith(id: 'member-2', displayName: 'Another Member'),
      );

      final members = await repository.getMembersByGroup('group-1');
      expect(members, hasLength(2));
      expect(members.any((m) => m.id == 'member-1'), isTrue);
      expect(members.any((m) => m.id == 'member-2'), isTrue);

      final membersStream = repository.watchMembersByGroup('group-1');
      expect(membersStream, emits(hasLength(2)));
    });

    test('updateMember', () async {
      await repository.createMember(testMember);
      final updatedMember = testMember.copyWith(displayName: 'Updated Name');

      await repository.updateMember(updatedMember);
      final member = await repository.getMemberById('member-1');
      expect(member?.displayName, equals('Updated Name'));
    });

    test('soft delete and undo soft delete member', () async {
      await repository.createMember(testMember);

      await repository.softDeleteMember('member-1');
      var member = await repository.getMemberById('member-1');
      expect(member?.removedAt, isNotNull);

      final activeMembers = await repository.getMembersByGroup(
        'group-1',
        includeRemoved: false,
      );
      expect(activeMembers, isEmpty);

      final allMembers = await repository.getMembersByGroup(
        'group-1',
        includeRemoved: true,
      );
      expect(allMembers, hasLength(1));

      await repository.undoSoftDeleteMember('member-1');
      member = await repository.getMemberById('member-1');
      expect(member?.removedAt, isNull);

      final activeMembersAfter = await repository.getMembersByGroup(
        'group-1',
        includeRemoved: false,
      );
      expect(activeMembersAfter, hasLength(1));
    });

    test('ordering by display name', () async {
      await repository.createMember(
        testMember.copyWith(id: 'm1', displayName: 'B Member'),
      );
      await repository.createMember(
        testMember.copyWith(id: 'm2', displayName: 'A Member'),
      );
      await repository.createMember(
        testMember.copyWith(id: 'm3', displayName: 'C Member'),
      );

      final members = await repository.getMembersByGroup('group-1');
      expect(members[0].displayName, equals('A Member'));
      expect(members[1].displayName, equals('B Member'));
      expect(members[2].displayName, equals('C Member'));
    });

    test('ordering by orderIndex then display name', () async {
      await repository.createMember(
        testMember.copyWith(id: 'm1', displayName: 'B Member', orderIndex: 2),
      );
      await repository.createMember(
        testMember.copyWith(id: 'm2', displayName: 'A Member', orderIndex: 1),
      );
      await repository.createMember(
        testMember.copyWith(id: 'm3', displayName: 'C Member', orderIndex: 1),
      );

      final members = await repository.getMembersByGroup('group-1');
      // m2 and m3 both have orderIndex 1, so they should be ordered by displayName
      expect(members[0].id, equals('m2')); // A Member, orderIndex 1
      expect(members[1].id, equals('m3')); // C Member, orderIndex 1
      expect(members[2].id, equals('m1')); // B Member, orderIndex 2
    });

    test('updateMemberOrder updates orderIndex correctly', () async {
      await repository.createMember(
        testMember.copyWith(id: 'm1', displayName: 'B Member'),
      );
      await repository.createMember(
        testMember.copyWith(id: 'm2', displayName: 'A Member'),
      );

      await repository.updateMemberOrder('group-1', ['m1', 'm2']);

      final members = await repository.getMembersByGroup('group-1');
      expect(members[0].id, equals('m1'));
      expect(members[0].orderIndex, equals(0));
      expect(members[1].id, equals('m2'));
      expect(members[1].orderIndex, equals(1));
    });
  });
}
