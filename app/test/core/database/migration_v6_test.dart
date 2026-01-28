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
  group('Migration v6', () {
    test('onUpgrade from 5 to 6 adds sourceId column', () async {
      final executor = NativeDatabase.memory();
      final db = TestDatabase(executor);

      // 1. Manually setup v5 schema
      await db.customStatement('PRAGMA user_version = 5;');
      await db.customStatement('''
        CREATE TABLE groups (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          currency_code TEXT NOT NULL,
          created_at INTEGER NOT NULL
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
        "INSERT INTO transactions (id, group_id, type, occurred_at, note, created_at, updated_at, is_recurring) VALUES ('tx1', 'g1', 'expense', 1600000000, 'Lunch', 1600000000, 1600000000, 0);",
      );

      // 2. Run migration
      final m = db.createMigrator();
      await db.migration.onUpgrade(m, 5, 6);

      // 3. Verify column exists
      final txs = await db.select(db.transactions).get();
      expect(txs.length, 1);
      expect(txs.first.note, 'Lunch');
      expect(txs.first.sourceId, isNull);

      // 4. Verify we can use the new column
      await (db.update(db.transactions)..where((t) => t.id.equals('tx1')))
          .write(const TransactionsCompanion(sourceId: Value('source_123')));

      final updated = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('tx1'))).getSingle();
      expect(updated.sourceId, 'source_123');

      await db.close();
    });
  });
}
