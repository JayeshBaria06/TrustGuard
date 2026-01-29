import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/database/database.dart';

class TestDatabase extends AppDatabase {
  TestDatabase(super.executor);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      // Do nothing to allow manual setup
    },
    onUpgrade: (m, from, to) async {
      await super.migration.onUpgrade(m, from, to);
    },
  );
}

void main() {
  group('Migration v9', () {
    test('onUpgrade from 8 to 9 adds avatar columns to members table', () async {
      final executor = NativeDatabase.memory();
      final db = TestDatabase(executor);

      // 1. Manually setup v8 schema (simplified for members table)
      await db.customStatement('PRAGMA user_version = 8;');
      await db.customStatement('''
        CREATE TABLE groups (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          currency_code TEXT NOT NULL,
          created_at INTEGER NOT NULL
        );
      ''');
      await db.customStatement('''
        CREATE TABLE members (
          id TEXT NOT NULL PRIMARY KEY,
          group_id TEXT NOT NULL REFERENCES groups(id),
          display_name TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          removed_at INTEGER,
          order_index INTEGER NOT NULL DEFAULT 0
        );
      ''');

      // Insert data
      await db.customStatement(
        "INSERT INTO groups (id, name, currency_code, created_at) VALUES ('g1', 'Group 1', 'USD', 1600000000);",
      );
      await db.customStatement(
        "INSERT INTO members (id, group_id, display_name, created_at) VALUES ('m1', 'g1', 'Alice', 1600000000);",
      );

      // 2. Run migration
      final m = db.createMigrator();
      await db.migration.onUpgrade(m, 8, 9);

      // 3. Verify columns exist
      final members = await db.select(db.members).get();
      expect(members.length, 1);
      expect(members.first.displayName, 'Alice');
      expect(members.first.avatarPath, isNull);
      expect(members.first.avatarColor, isNull);

      // 4. Verify we can use the new columns
      await (db.update(db.members)..where((m) => m.id.equals('m1'))).write(
        const MembersCompanion(
          avatarPath: Value('path/to/avatar.jpg'),
          avatarColor: Value(0xFFF44336),
        ),
      );

      final updated = await (db.select(
        db.members,
      )..where((m) => m.id.equals('m1'))).getSingle();
      expect(updated.avatarPath, 'path/to/avatar.jpg');
      expect(updated.avatarColor, 0xFFF44336);

      await db.close();
    });
  });
}
