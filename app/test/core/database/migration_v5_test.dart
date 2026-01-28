import 'package:drift/drift.dart';
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
      // We'll call this manually or it will be called by Drift if we set user_version
      await super.migration.onUpgrade(m, from, to);
    },
  );
}

void main() {
  group('Migration v5', () {
    test('onUpgrade from 4 to 5 adds orderIndex columns and preserves data', () async {
      final executor = NativeDatabase.memory();
      final db = TestDatabase(executor);

      // 1. Manually setup v4 schema
      // This will NOT trigger onCreate because TestDatabase's onCreate is empty
      await db.customStatement('PRAGMA user_version = 4;');
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
          removed_at INTEGER
        );
      ''');
      await db.customStatement('''
        CREATE TABLE tags (
          id TEXT NOT NULL PRIMARY KEY,
          group_id TEXT NOT NULL REFERENCES groups(id),
          name TEXT NOT NULL COLLATE NOCASE
        );
      ''');
      await db.customStatement('''
        CREATE TABLE transactions (
          id TEXT NOT NULL PRIMARY KEY,
          group_id TEXT NOT NULL REFERENCES groups(id),
          type TEXT NOT NULL,
          occurred_at INTEGER NOT NULL,
          note TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER,
          is_recurring INTEGER NOT NULL DEFAULT 0
        );
      ''');

      // Insert data
      await db.customStatement(
        "INSERT INTO groups (id, name, currency_code, created_at) VALUES ('g1', 'Group 1', 'USD', 1600000000);",
      );
      await db.customStatement(
        "INSERT INTO members (id, group_id, display_name, created_at) VALUES ('m1', 'g1', 'Alice', 1600000000);",
      );
      await db.customStatement(
        "INSERT INTO tags (id, group_id, name) VALUES ('t1', 'g1', 'Tag 1');",
      );

      // 2. Run migration
      // Since we set user_version to 4, Drift SHOULD run onUpgrade when we call it?
      // Actually, Drift already ran its initialization when we called the first customStatement.
      // But since onCreate was empty, nothing happened.

      // Let's call onUpgrade manually.
      final m = db.createMigrator();
      await db.migration.onUpgrade(m, 4, 5);

      // 3. Verify columns exist
      final members = await db.select(db.members).get();
      expect(members.length, 1);
      expect(members.first.displayName, 'Alice');
      expect(members.first.orderIndex, 0);

      final tags = await db.select(db.tags).get();
      expect(tags.length, 1);
      expect(tags.first.name, 'Tag 1');
      expect(tags.first.orderIndex, 0);

      await db.close();
    });
  });
}
