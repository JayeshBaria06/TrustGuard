import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/features/import/services/csv_import_service.dart';

void main() {
  late CsvImportService service;
  late String splitwiseCsv;
  late String tricountCsv;

  setUp(() {
    service = CsvImportService();
    // Assuming tests are run from the 'app' directory
    splitwiseCsv = File(
      'test/fixtures/sample_splitwise.csv',
    ).readAsStringSync();
    tricountCsv = File('test/fixtures/sample_tricount.csv').readAsStringSync();
  });

  group('CsvImportService - Format Detection', () {
    test('detects Splitwise format', () {
      expect(service.detectCsvFormat(splitwiseCsv), CsvFormat.splitwise);
    });

    test('detects Tricount format', () {
      expect(service.detectCsvFormat(tricountCsv), CsvFormat.tricount);
    });

    test('returns unknown for invalid CSV', () {
      expect(
        service.detectCsvFormat('Invalid,Header\nValue,1'),
        CsvFormat.unknown,
      );
    });
  });

  group('CsvImportService - Member Name Extraction', () {
    test('extracts member names from Splitwise CSV', () async {
      final names = await service.getMemberNamesFromSplitwiseCsv(splitwiseCsv);
      expect(names, containsAll(['Member 1', 'Member 2']));
    });

    test('extracts member names from Tricount CSV', () async {
      final names = await service.getMemberNamesFromTricountCsv(tricountCsv);
      expect(names, containsAll(['Alice', 'Bob']));
    });
  });

  group('CsvImportService - Splitwise Import', () {
    test('imports Splitwise transactions correctly', () async {
      final mapping = {'Member 1': 'm1', 'Member 2': 'm2'};
      final result = await service.importSplitwiseCsv(
        splitwiseCsv,
        'g1',
        memberMapping: mapping,
      );

      expect(result.successCount, 2);
      expect(result.failedCount, 0);
      expect(result.transactions.length, 2);

      final t1 = result.transactions.first;
      expect(t1.note, contains('Groceries'));
      expect(t1.expenseDetail?.payerMemberId, 'm1');
      expect(t1.expenseDetail?.totalAmountMinor, 10000);
      expect(t1.expenseDetail?.participants.length, 2);
    });

    test('reports errors for unmapped payers in Splitwise', () async {
      final mapping = {'Member 1': 'm1'}; // Member 2 is missing
      final result = await service.importSplitwiseCsv(
        splitwiseCsv,
        'g1',
        memberMapping: mapping,
      );

      // Second row has Member 2 as payer
      expect(result.successCount, 1);
      expect(result.failedCount, 1);
      expect(
        result.errors.any((e) => e.message.contains('Payer not mapped')),
        true,
      );
    });
  });

  group('CsvImportService - Tricount Import', () {
    test('imports Tricount transactions correctly with "Everybody"', () async {
      final mapping = {'Alice': 'a1', 'Bob': 'b1'};
      final result = await service.importTricountCsv(
        tricountCsv,
        'g1',
        memberMapping: mapping,
      );

      expect(result.successCount, 2);
      expect(result.transactions.length, 2);

      final t1 = result.transactions.first; // Gas, 40.00, Alice, Everybody
      expect(t1.note, 'Gas');
      expect(t1.expenseDetail?.payerMemberId, 'a1');
      expect(t1.expenseDetail?.totalAmountMinor, 4000);
      expect(t1.expenseDetail?.participants.length, 2); // Alice and Bob
      expect(
        t1.expenseDetail?.participants.any((p) => p.owedAmountMinor == 2000),
        true,
      );
    });

    test('imports Tricount transactions with specific beneficiaries', () async {
      final mapping = {'Alice': 'a1', 'Bob': 'b1'};
      final result = await service.importTricountCsv(
        tricountCsv,
        'g1',
        memberMapping: mapping,
      );

      final t2 = result.transactions[1]; // Snacks, 15.00, Bob, Alice;Bob
      expect(t2.note, 'Snacks');
      expect(t2.expenseDetail?.payerMemberId, 'b1');
      expect(t2.expenseDetail?.totalAmountMinor, 1500);
      expect(t2.expenseDetail?.participants.length, 2);
      // 1500 / 2 = 750
      expect(
        t2.expenseDetail?.participants.every((p) => p.owedAmountMinor == 750),
        true,
      );
    });
  });

  group('CsvImportService - Unified Import', () {
    test('auto-detects and imports Splitwise', () async {
      final mapping = {'Member 1': 'm1', 'Member 2': 'm2'};
      final result = await service.importCsv(
        splitwiseCsv,
        'g1',
        memberMapping: mapping,
      );
      expect(result.successCount, 2);
    });

    test('auto-detects and imports Tricount', () async {
      final mapping = {'Alice': 'a1', 'Bob': 'b1'};
      final result = await service.importCsv(
        tricountCsv,
        'g1',
        memberMapping: mapping,
      );
      expect(result.successCount, 2);
    });
  });

  group('CsvImportService - Edge Cases', () {
    test('reports missing columns in Splitwise', () async {
      const csv = 'Invalid,Header\nValue,1';
      final result = await service.importSplitwiseCsv(csv, 'g1');
      expect(result.failedCount, isPositive);
      expect(result.errors.first.message, contains('Missing required columns'));
    });

    test('reports missing columns in Tricount', () async {
      const csv = 'Invalid,Header\nValue,1';
      final result = await service.importTricountCsv(csv, 'g1');
      expect(result.failedCount, isPositive);
      expect(result.errors.first.message, contains('Missing required columns'));
    });

    test('handles various date formats', () async {
      // Splitwise parser is used here as it's flexible with dates
      final mapping = {'Alice': 'a1'};
      const csv =
          'Date,Description,Cost,Alice\n'
          '2026-01-01,ISO,10.00,10.00\n'
          '01/02/2026,US or UK,20.00,20.00\n'
          '15.04.2026,European,30.00,30.00';

      final result = await service.importSplitwiseCsv(
        csv,
        'g1',
        memberMapping: mapping,
      );
      expect(result.successCount, 3);
      expect(result.transactions[0].occurredAt.month, 1);
      expect(result.transactions[1].occurredAt.year, 2026);
      expect(
        result.transactions[2].occurredAt.month,
        4,
      ); // 15.04.2026 -> April 15th
    });
  });
}
