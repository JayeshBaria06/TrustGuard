import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/expense.dart';
import '../../../core/utils/money.dart';
import '../models/import_result.dart';

enum CsvFormat { splitwise, tricount, unknown }

class CsvImportService {
  final Uuid _uuid = const Uuid();

  List<List<dynamic>> _parseCsv(String content) {
    return CsvToListConverter(
      eol: content.contains('\r\n') ? '\r\n' : '\n',
    ).convert(content);
  }

  /// Automatically detects the CSV format based on headers.
  CsvFormat detectCsvFormat(String csvContent) {
    final List<List<dynamic>> rows = _parseCsv(csvContent);
    if (rows.isEmpty) return CsvFormat.unknown;

    final header = rows.first
        .map((e) => e.toString().trim().toLowerCase())
        .toList();

    // Splitwise markers
    if (_findColumn(header, ['Cost']) != -1 &&
        _findColumn(header, ['Category']) != -1) {
      return CsvFormat.splitwise;
    }

    // Tricount markers
    if (_findColumn(header, ['For whom']) != -1 ||
        (_findColumn(header, ['Paid by']) != -1 &&
            _findColumn(header, ['Amount']) != -1)) {
      return CsvFormat.tricount;
    }

    return CsvFormat.unknown;
  }

  /// Unified import method that auto-detects format.
  Future<ImportResult> importCsv(
    String csvContent,
    String targetGroupId, {
    Map<String, String>? memberMapping,
  }) async {
    final format = detectCsvFormat(csvContent);
    switch (format) {
      case CsvFormat.splitwise:
        return importSplitwiseCsv(
          csvContent,
          targetGroupId,
          memberMapping: memberMapping,
        );
      case CsvFormat.tricount:
        return importTricountCsv(
          csvContent,
          targetGroupId,
          memberMapping: memberMapping,
        );
      case CsvFormat.unknown:
        return const ImportResult(
          successCount: 0,
          failedCount: 0,
          errors: [
            ImportError(
              rowNumber: 1,
              message:
                  'Could not detect CSV format. Supported formats: Splitwise, Tricount.',
            ),
          ],
          transactions: [],
        );
    }
  }

  /// Extracts potential member names from a CSV file.
  Future<List<String>> getMemberNamesFromCsv(String csvContent) async {
    final format = detectCsvFormat(csvContent);
    switch (format) {
      case CsvFormat.splitwise:
        return getMemberNamesFromSplitwiseCsv(csvContent);
      case CsvFormat.tricount:
        return getMemberNamesFromTricountCsv(csvContent);
      case CsvFormat.unknown:
        return [];
    }
  }

  /// Extracts potential member names from a Tricount CSV.
  Future<List<String>> getMemberNamesFromTricountCsv(String csvContent) async {
    final List<List<dynamic>> rows = _parseCsv(csvContent);
    if (rows.isEmpty) return [];

    final header = rows.first.map((e) => e.toString().trim()).toList();
    final payerIdx = _findColumn(header, ['Paid by', 'Who Paid', 'Payer']);
    final forWhomIdx = _findColumn(header, ['For whom', 'Beneficiaries']);

    final memberNames = <String>{};
    final dataRows = rows.skip(1);

    for (final row in dataRows) {
      if (row.isEmpty) continue;

      // Add payer
      if (payerIdx != -1 && row.length > payerIdx) {
        final name = row[payerIdx].toString().trim();
        if (name.isNotEmpty) memberNames.add(name);
      }

      // Add beneficiaries from "For whom"
      if (forWhomIdx != -1 && row.length > forWhomIdx) {
        final whom = row[forWhomIdx].toString().trim();
        if (whom.isNotEmpty && whom.toLowerCase() != 'everybody') {
          // Tricount often uses comma or semicolon separator
          final names = whom.split(RegExp(r'[,;]'));
          for (final name in names) {
            final trimmed = name.trim();
            if (trimmed.isNotEmpty) memberNames.add(trimmed);
          }
        }
      }
    }

    return memberNames.toList()..sort();
  }

  /// Imports transactions from a Tricount CSV.
  Future<ImportResult> importTricountCsv(
    String csvContent,
    String targetGroupId, {
    Map<String, String>? memberMapping,
  }) async {
    final List<List<dynamic>> rows = _parseCsv(csvContent);
    if (rows.isEmpty) {
      return const ImportResult(
        successCount: 0,
        failedCount: 0,
        errors: [],
        transactions: [],
      );
    }

    final header = rows.first.map((e) => e.toString().trim()).toList();
    final dataRows = rows.skip(1).toList();

    // Identify standard columns
    final descIdx = _findColumn(header, ['Title', 'Description']);
    final amountIdx = _findColumn(header, ['Amount', 'Cost']);
    final payerIdx = _findColumn(header, ['Paid by', 'Who Paid', 'Payer']);
    final dateIdx = _findColumn(header, ['Date']);
    final forWhomIdx = _findColumn(header, ['For whom', 'Beneficiaries']);

    // Required columns
    if (descIdx == -1 || amountIdx == -1 || payerIdx == -1) {
      return ImportResult(
        successCount: 0,
        failedCount: dataRows.length,
        errors: [
          const ImportError(
            rowNumber: 1,
            message: 'Missing required columns (Title, Amount, or Paid by)',
          ),
        ],
        transactions: [],
      );
    }

    final List<Transaction> transactions = [];
    final List<ImportError> errors = [];
    int successCount = 0;

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final rowNumber = i + 2;

      try {
        if (row.isEmpty || row.length <= _max({descIdx, amountIdx, payerIdx})) {
          continue;
        }

        final String rawAmount = row[amountIdx].toString().replaceAll(
          RegExp(r'[^\d.-]'),
          '',
        );
        final double? amountValue = double.tryParse(rawAmount);
        if (amountValue == null || amountValue == 0) continue;

        final DateTime? occurredAt = dateIdx != -1
            ? _parseDate(row[dateIdx].toString())
            : DateTime.now();

        if (occurredAt == null) {
          errors.add(
            ImportError(
              rowNumber: rowNumber,
              message: 'Invalid date format: ${row[dateIdx]}',
            ),
          );
          continue;
        }

        final String description = row[descIdx].toString();
        final int totalAmountMinor = MoneyUtils.toMinorUnits(amountValue);

        // Find payer
        final String payerName = row[payerIdx].toString().trim();
        final String? payerId = memberMapping?[payerName];

        if (payerId == null && memberMapping != null && payerName.isNotEmpty) {
          errors.add(
            ImportError(
              rowNumber: rowNumber,
              message: 'Payer not mapped: $payerName',
            ),
          );
          continue;
        }

        // Handle participants (For whom)
        final participants = <ExpenseParticipant>[];
        if (forWhomIdx != -1 && row.length > forWhomIdx) {
          final forWhom = row[forWhomIdx].toString().trim();
          if (forWhom.toLowerCase() == 'everybody') {
            // Split among all mapped members
            if (memberMapping != null) {
              final share = totalAmountMinor ~/ memberMapping.length;
              var remainder = totalAmountMinor % memberMapping.length;

              for (final entry in memberMapping.entries) {
                participants.add(
                  ExpenseParticipant(
                    memberId: entry.value,
                    owedAmountMinor: share + (remainder > 0 ? 1 : 0),
                  ),
                );
                if (remainder > 0) remainder--;
              }
            }
          } else if (forWhom.isNotEmpty) {
            final names = forWhom
                .split(RegExp(r'[,;]'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            final mappedIds = <String>[];
            for (final name in names) {
              final id = memberMapping?[name];
              if (id != null) mappedIds.add(id);
            }

            if (mappedIds.isNotEmpty) {
              final share = totalAmountMinor ~/ mappedIds.length;
              var remainder = totalAmountMinor % mappedIds.length;

              for (final id in mappedIds) {
                participants.add(
                  ExpenseParticipant(
                    memberId: id,
                    owedAmountMinor: share + (remainder > 0 ? 1 : 0),
                  ),
                );
                if (remainder > 0) remainder--;
              }
            }
          }
        }

        // Fallback: split equally among all mapped members if no participants found
        if (participants.isEmpty && memberMapping != null) {
          final share = totalAmountMinor ~/ memberMapping.length;
          var remainder = totalAmountMinor % memberMapping.length;

          for (final entry in memberMapping.entries) {
            participants.add(
              ExpenseParticipant(
                memberId: entry.value,
                owedAmountMinor: share + (remainder > 0 ? 1 : 0),
              ),
            );
            if (remainder > 0) remainder--;
          }
        }

        final now = DateTime.now();
        transactions.add(
          Transaction(
            id: _uuid.v4(),
            groupId: targetGroupId,
            type: TransactionType.expense,
            occurredAt: occurredAt,
            note: description,
            createdAt: now,
            updatedAt: now,
            expenseDetail: ExpenseDetail(
              payerMemberId: payerId ?? 'unknown-payer',
              totalAmountMinor: totalAmountMinor,
              splitType:
                  SplitType.equal, // Usually equal in Tricount unless specified
              participants: participants,
            ),
          ),
        );
        successCount++;
      } catch (e) {
        errors.add(
          ImportError(
            rowNumber: rowNumber,
            message: 'Unexpected error: ${e.toString()}',
          ),
        );
      }
    }

    return ImportResult(
      successCount: successCount,
      failedCount: errors.length,
      errors: errors,
      transactions: transactions,
    );
  }

  /// Extracts potential member names from a Splitwise CSV.
  Future<List<String>> getMemberNamesFromSplitwiseCsv(String csvContent) async {
    final List<List<dynamic>> rows = _parseCsv(csvContent);
    if (rows.isEmpty) return [];

    final header = rows.first.map((e) => e.toString().trim()).toList();

    final standardIndices = _getStandardIndices(header);

    final memberNames = <String>{};
    for (int i = 0; i < header.length; i++) {
      if (!standardIndices.contains(i)) {
        memberNames.add(header[i]);
      }
    }

    // Also check "Payer Name" column for unique names
    final payerIdx = _findColumn(header, [
      'Payer',
      'Payer Name',
      'Paid By',
      'Who Paid',
    ]);
    if (payerIdx != -1) {
      final dataRows = rows.skip(1);
      for (final row in dataRows) {
        if (row.length > payerIdx) {
          final name = row[payerIdx].toString().trim();
          if (name.isNotEmpty) {
            memberNames.add(name);
          }
        }
      }
    }

    return memberNames.toList()..sort();
  }

  /// Imports transactions from a Splitwise CSV.
  Future<ImportResult> importSplitwiseCsv(
    String csvContent,
    String targetGroupId, {
    Map<String, String>? memberMapping,
  }) async {
    final List<List<dynamic>> rows = _parseCsv(csvContent);
    if (rows.isEmpty) {
      return const ImportResult(
        successCount: 0,
        failedCount: 0,
        errors: [],
        transactions: [],
      );
    }

    final header = rows.first.map((e) => e.toString().trim()).toList();
    final dataRows = rows.skip(1).toList();

    // Identify standard columns
    final dateIdx = _findColumn(header, ['Date']);
    final descIdx = _findColumn(header, ['Description', 'Title']);
    final costIdx = _findColumn(header, ['Cost', 'Amount']);
    final notesIdx = _findColumn(header, ['Notes', 'Note']);
    final payerIdx = _findColumn(header, [
      'Payer',
      'Payer Name',
      'Paid By',
      'Who Paid',
    ]);

    // Required columns
    if (dateIdx == -1 || descIdx == -1 || costIdx == -1) {
      return ImportResult(
        successCount: 0,
        failedCount: dataRows.length,
        errors: [
          const ImportError(
            rowNumber: 1,
            message: 'Missing required columns (Date, Description, or Cost)',
          ),
        ],
        transactions: [],
      );
    }

    final standardIndices = _getStandardIndices(header);
    final memberIndices = <int>[];
    for (int i = 0; i < header.length; i++) {
      if (!standardIndices.contains(i)) {
        memberIndices.add(i);
      }
    }

    final List<Transaction> transactions = [];
    final List<ImportError> errors = [];
    int successCount = 0;

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final rowNumber = i + 2;

      try {
        if (row.length <= _max(standardIndices) &&
            row.length <= _max(memberIndices.toSet())) {
          continue;
        }

        final String rawCost = row[costIdx].toString().replaceAll(
          RegExp(r'[^\d.-]'),
          '',
        );
        final double? costValue = double.tryParse(rawCost);
        if (costValue == null || costValue == 0) continue;

        final DateTime? occurredAt = _parseDate(row[dateIdx].toString());
        if (occurredAt == null) {
          errors.add(
            ImportError(
              rowNumber: rowNumber,
              message: 'Invalid date format: ${row[dateIdx]}',
            ),
          );
          continue;
        }

        final String description = row[descIdx].toString();
        final String notes = notesIdx != -1 ? row[notesIdx].toString() : '';
        final int totalAmountMinor = MoneyUtils.toMinorUnits(costValue);

        // Find payer
        final String? payerName = payerIdx != -1
            ? row[payerIdx].toString().trim()
            : null;
        final String? payerId = (payerName != null && memberMapping != null)
            ? memberMapping[payerName]
            : null;

        // If payer not found but we have member mapping, it's an error for this row
        if (payerId == null &&
            memberMapping != null &&
            payerName != null &&
            payerName.isNotEmpty) {
          errors.add(
            ImportError(
              rowNumber: rowNumber,
              message: 'Payer not mapped: $payerName',
            ),
          );
          continue;
        }

        // Handle participants
        final participants = <ExpenseParticipant>[];
        for (final mIdx in memberIndices) {
          if (row.length <= mIdx) continue;
          final rawShare = row[mIdx].toString().replaceAll(
            RegExp(r'[^\d.-]'),
            '',
          );
          final shareValue = double.tryParse(rawShare);
          if (shareValue != null && shareValue > 0) {
            final memberName = header[mIdx];
            final memberId = memberMapping?[memberName];
            if (memberId != null) {
              participants.add(
                ExpenseParticipant(
                  memberId: memberId,
                  owedAmountMinor: MoneyUtils.toMinorUnits(shareValue),
                ),
              );
            }
          }
        }

        // Fallback: if no participants found and member mapping exists, maybe it was a simple "X paid for group"
        // But Splitwise usually gives shares. If no shares, we can't be sure who was involved.
        if (participants.isEmpty &&
            memberMapping != null &&
            memberIndices.isNotEmpty) {
          errors.add(
            ImportError(
              rowNumber: rowNumber,
              message: 'No participants identified in member columns',
            ),
          );
          continue;
        }

        final now = DateTime.now();
        transactions.add(
          Transaction(
            id: _uuid.v4(),
            groupId: targetGroupId,
            type: TransactionType.expense,
            occurredAt: occurredAt,
            note: description + (notes.isNotEmpty ? '\n$notes' : ''),
            createdAt: now,
            updatedAt: now,
            expenseDetail: ExpenseDetail(
              payerMemberId: payerId ?? 'unknown-payer',
              totalAmountMinor: totalAmountMinor,
              splitType: SplitType.custom,
              participants: participants,
            ),
          ),
        );
        successCount++;
      } catch (e) {
        errors.add(
          ImportError(
            rowNumber: rowNumber,
            message: 'Unexpected error: ${e.toString()}',
          ),
        );
      }
    }

    return ImportResult(
      successCount: successCount,
      failedCount: errors.length,
      errors: errors,
      transactions: transactions,
    );
  }

  Set<int> _getStandardIndices(List<String> header) {
    return {
      _findColumn(header, ['Date']),
      _findColumn(header, ['Description', 'Title']),
      _findColumn(header, ['Category']),
      _findColumn(header, ['Cost', 'Amount']),
      _findColumn(header, ['Currency']),
      _findColumn(header, ['Notes', 'Note']),
      _findColumn(header, ['Payer', 'Payer Name', 'Paid By', 'Who Paid']),
    }..remove(-1);
  }

  int _findColumn(List<String> header, List<String> aliases) {
    for (var i = 0; i < header.length; i++) {
      final col = header[i].toLowerCase();
      for (final alias in aliases) {
        if (col == alias.toLowerCase() ||
            col.startsWith('${alias.toLowerCase()} ') ||
            col.endsWith(' ${alias.toLowerCase()}')) {
          return i;
        }
      }
    }
    return -1;
  }

  int _max(Set<int> values) {
    if (values.isEmpty) return -1;
    return values.reduce((a, b) => a > b ? a : b);
  }

  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    final parts = dateStr.split(RegExp(r'[/\.\-]'));
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);
      if (p0 != null && p1 != null && p2 != null) {
        if (p2 > 100) {
          if (p0 > 12) return DateTime(p2, p1, p0);
          return DateTime(p2, p0, p1);
        } else if (p0 > 100) {
          return DateTime(p0, p1, p2);
        }
      }
    }
    return null;
  }
}
