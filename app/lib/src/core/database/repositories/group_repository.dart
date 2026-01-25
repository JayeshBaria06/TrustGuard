import 'package:drift/drift.dart';
import '../database.dart';
import '../mappers/group_mapper.dart';
import '../../models/group.dart' as model;

abstract class GroupRepository {
  Future<List<model.Group>> getAllGroups({bool includeArchived = false});
  Stream<List<model.Group>> watchGroups({bool includeArchived = false});
  Stream<List<model.GroupWithMemberCount>> watchGroupsWithMemberCount({
    bool includeArchived = false,
  });
  Future<model.Group?> getGroupById(String id);
  Stream<model.Group?> watchGroupById(String id);
  Future<void> createGroup(model.Group group);
  Future<void> updateGroup(model.Group group);
  Future<void> archiveGroup(String id);
  Future<void> unarchiveGroup(String id);
}

class DriftGroupRepository implements GroupRepository {
  final AppDatabase _db;

  DriftGroupRepository(this._db);

  @override
  Future<List<model.Group>> getAllGroups({bool includeArchived = false}) async {
    final query = _db.select(_db.groups);
    if (!includeArchived) {
      query.where((t) => t.archivedAt.isNull());
    }
    final rows = await query.get();
    return rows.map(GroupMapper.toModel).toList();
  }

  @override
  Stream<List<model.Group>> watchGroups({bool includeArchived = false}) {
    final query = _db.select(_db.groups);
    if (!includeArchived) {
      query.where((t) => t.archivedAt.isNull());
    }
    return query.watch().map((rows) => rows.map(GroupMapper.toModel).toList());
  }

  @override
  Stream<List<model.GroupWithMemberCount>> watchGroupsWithMemberCount({
    bool includeArchived = false,
  }) {
    final countMembers = _db.members.id.count();
    final query = _db.select(_db.groups).join([
      leftOuterJoin(_db.members, _db.members.groupId.equalsExp(_db.groups.id)),
    ]);

    if (!includeArchived) {
      query.where(_db.groups.archivedAt.isNull());
    }

    // Only count members that are not removed
    query.where(_db.members.removedAt.isNull() | _db.members.id.isNull());

    query.addColumns([countMembers]);
    query.groupBy([_db.groups.id]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final group = GroupMapper.toModel(row.readTable(_db.groups));
        final memberCount = row.read(countMembers) ?? 0;
        return model.GroupWithMemberCount(
          group: group,
          memberCount: memberCount,
        );
      }).toList();
    });
  }

  @override
  Future<model.Group?> getGroupById(String id) async {
    final query = _db.select(_db.groups)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? GroupMapper.toModel(row) : null;
  }

  @override
  Stream<model.Group?> watchGroupById(String id) {
    final query = _db.select(_db.groups)..where((t) => t.id.equals(id));
    return query.watchSingleOrNull().map(
      (row) => row != null ? GroupMapper.toModel(row) : null,
    );
  }

  @override
  Future<void> createGroup(model.Group group) async {
    await _db.into(_db.groups).insert(GroupMapper.toCompanion(group));
  }

  @override
  Future<void> updateGroup(model.Group group) async {
    await (_db.update(_db.groups)..where((t) => t.id.equals(group.id))).write(
      GroupMapper.toCompanion(group),
    );
  }

  @override
  Future<void> archiveGroup(String id) async {
    await (_db.update(_db.groups)..where((t) => t.id.equals(id))).write(
      GroupsCompanion(archivedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<void> unarchiveGroup(String id) async {
    await (_db.update(_db.groups)..where((t) => t.id.equals(id))).write(
      const GroupsCompanion(archivedAt: Value(null)),
    );
  }
}
