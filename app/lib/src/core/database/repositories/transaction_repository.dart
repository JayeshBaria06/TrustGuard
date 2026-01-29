import 'package:drift/drift.dart';
import '../database.dart';
import '../mappers/transaction_mapper.dart';
import '../../models/transaction.dart' as model;
import '../../models/transaction_filter.dart';
import '../../../features/transactions/services/attachment_service.dart';

abstract class TransactionRepository {
  Future<List<model.Transaction>> getAllTransactions();
  Stream<List<model.Transaction>> watchAllTransactions();
  Future<List<model.Transaction>> getTransactionsByGroup(
    String groupId, {
    bool includeDeleted = false,
    TransactionFilter? filter,
  });
  Future<List<model.Transaction>> getTransactionsByGroupPaginated(
    String groupId, {
    int limit = 20,
    int offset = 0,
    bool includeDeleted = false,
    TransactionFilter? filter,
  });
  Future<int> getTransactionCountByGroup(
    String groupId, {
    bool includeDeleted = false,
    TransactionFilter? filter,
  });
  Stream<List<model.Transaction>> watchTransactionsByGroup(
    String groupId, {
    bool includeDeleted = false,
    TransactionFilter? filter,
  });
  Future<model.Transaction?> getTransactionById(String id);
  Future<void> createTransaction(model.Transaction transaction);
  Future<void> updateTransaction(model.Transaction transaction);
  Future<void> softDeleteTransaction(String id);
  Future<void> undoSoftDeleteTransaction(String id);
  Future<void> hardDeleteTransaction(String id);
  Future<model.Transaction?> findBySourceId(String sourceId);
}

class DriftTransactionRepository implements TransactionRepository {
  final AppDatabase _db;
  final AttachmentService _attachmentService;
  final void Function()? onChanged;

  DriftTransactionRepository(
    this._db,
    this._attachmentService, {
    this.onChanged,
  });

  @override
  Future<List<model.Transaction>> getAllTransactions() async {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.expenseDetails,
        _db.expenseDetails.txId.equalsExp(_db.transactions.id),
      ),
      leftOuterJoin(
        _db.transferDetails,
        _db.transferDetails.txId.equalsExp(_db.transactions.id),
      ),
    ]);

    final rows = await query.get();
    return _mapRowsToTransactions(rows);
  }

  @override
  Stream<List<model.Transaction>> watchAllTransactions() {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.expenseDetails,
        _db.expenseDetails.txId.equalsExp(_db.transactions.id),
      ),
      leftOuterJoin(
        _db.transferDetails,
        _db.transferDetails.txId.equalsExp(_db.transactions.id),
      ),
    ]);
    query.orderBy([OrderingTerm.desc(_db.transactions.occurredAt)]);
    return query.watch().asyncMap(_mapRowsToTransactions);
  }

  @override
  Future<List<model.Transaction>> getTransactionsByGroup(
    String groupId, {
    bool includeDeleted = false,
    TransactionFilter? filter,
  }) async {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.expenseDetails,
        _db.expenseDetails.txId.equalsExp(_db.transactions.id),
      ),
      leftOuterJoin(
        _db.transferDetails,
        _db.transferDetails.txId.equalsExp(_db.transactions.id),
      ),
    ])..where(_db.transactions.groupId.equals(groupId));

    if (!includeDeleted) {
      query.where(_db.transactions.deletedAt.isNull());
    }

    _applyFilter(query, filter);

    query.orderBy([OrderingTerm.desc(_db.transactions.occurredAt)]);

    final rows = await query.get();
    return _mapRowsToTransactions(rows);
  }

  @override
  Future<List<model.Transaction>> getTransactionsByGroupPaginated(
    String groupId, {
    int limit = 20,
    int offset = 0,
    bool includeDeleted = false,
    TransactionFilter? filter,
  }) async {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.expenseDetails,
        _db.expenseDetails.txId.equalsExp(_db.transactions.id),
      ),
      leftOuterJoin(
        _db.transferDetails,
        _db.transferDetails.txId.equalsExp(_db.transactions.id),
      ),
    ])..where(_db.transactions.groupId.equals(groupId));

    if (!includeDeleted) {
      query.where(_db.transactions.deletedAt.isNull());
    }

    _applyFilter(query, filter);

    query.orderBy([OrderingTerm.desc(_db.transactions.occurredAt)]);
    query.limit(limit, offset: offset);

    final rows = await query.get();
    return _mapRowsToTransactions(rows);
  }

  @override
  Future<int> getTransactionCountByGroup(
    String groupId, {
    bool includeDeleted = false,
    TransactionFilter? filter,
  }) async {
    final countExp = _db.transactions.id.count();
    final query =
        _db.selectOnly(_db.transactions).join([
            leftOuterJoin(
              _db.expenseDetails,
              _db.expenseDetails.txId.equalsExp(_db.transactions.id),
            ),
            leftOuterJoin(
              _db.transferDetails,
              _db.transferDetails.txId.equalsExp(_db.transactions.id),
            ),
          ])
          ..addColumns([countExp])
          ..where(_db.transactions.groupId.equals(groupId));

    if (!includeDeleted) {
      query.where(_db.transactions.deletedAt.isNull());
    }

    _applyFilter(query, filter);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Stream<List<model.Transaction>> watchTransactionsByGroup(
    String groupId, {
    bool includeDeleted = false,
    TransactionFilter? filter,
  }) {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.expenseDetails,
        _db.expenseDetails.txId.equalsExp(_db.transactions.id),
      ),
      leftOuterJoin(
        _db.transferDetails,
        _db.transferDetails.txId.equalsExp(_db.transactions.id),
      ),
    ])..where(_db.transactions.groupId.equals(groupId));

    if (!includeDeleted) {
      query.where(_db.transactions.deletedAt.isNull());
    }

    _applyFilter(query, filter);

    query.orderBy([OrderingTerm.desc(_db.transactions.occurredAt)]);

    return query.watch().asyncMap(_mapRowsToTransactions);
  }

  void _applyFilter(
    JoinedSelectStatement<HasResultSet, dynamic> query,
    TransactionFilter? filter,
  ) {
    if (filter == null || filter.isEmpty) return;

    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      query.where(_db.transactions.note.like('%${filter.searchQuery}%'));
    }

    if (filter.startDate != null) {
      query.where(
        _db.transactions.occurredAt.isBiggerOrEqualValue(filter.startDate!),
      );
    }

    if (filter.endDate != null) {
      query.where(
        _db.transactions.occurredAt.isSmallerOrEqualValue(filter.endDate!),
      );
    }

    if (filter.tagIds != null && filter.tagIds!.isNotEmpty) {
      query.where(
        existsQuery(
          _db.select(_db.transactionTags)..where(
            (t) =>
                t.txId.equalsExp(_db.transactions.id) &
                t.tagId.isIn(filter.tagIds!),
          ),
        ),
      );
    }

    if (filter.memberIds != null && filter.memberIds!.isNotEmpty) {
      query.where(
        _db.expenseDetails.payerMemberId.isIn(filter.memberIds!) |
            existsQuery(
              _db.select(_db.expenseParticipants)..where(
                (t) =>
                    t.txId.equalsExp(_db.transactions.id) &
                    t.memberId.isIn(filter.memberIds!),
              ),
            ) |
            _db.transferDetails.fromMemberId.isIn(filter.memberIds!) |
            _db.transferDetails.toMemberId.isIn(filter.memberIds!),
      );
    }
  }

  @override
  Future<model.Transaction?> getTransactionById(String id) async {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.expenseDetails,
        _db.expenseDetails.txId.equalsExp(_db.transactions.id),
      ),
      leftOuterJoin(
        _db.transferDetails,
        _db.transferDetails.txId.equalsExp(_db.transactions.id),
      ),
    ])..where(_db.transactions.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final tx = row.readTable(_db.transactions);
    final expenseDetail = row.readTableOrNull(_db.expenseDetails);
    final transferDetail = row.readTableOrNull(_db.transferDetails);

    List<ExpenseParticipant>? participants;
    if (expenseDetail != null) {
      participants = await (_db.select(
        _db.expenseParticipants,
      )..where((t) => t.txId.equals(tx.id))).get();
    }

    final tags = await (_db.select(_db.tags).join([
      innerJoin(
        _db.transactionTags,
        _db.transactionTags.tagId.equalsExp(_db.tags.id),
      ),
    ])..where(_db.transactionTags.txId.equals(tx.id))).get();

    return TransactionMapper.toModel(
      transaction: tx,
      expenseDetail: expenseDetail,
      participants: participants,
      transferDetail: transferDetail,
      tags: tags.map((r) => r.readTable(_db.tags)).toList(),
    );
  }

  @override
  Future<void> createTransaction(model.Transaction transaction) async {
    await _db.transaction(() async {
      await _db
          .into(_db.transactions)
          .insert(TransactionMapper.toTransactionCompanion(transaction));

      final expenseCompanion = TransactionMapper.toExpenseDetailCompanion(
        transaction,
      );
      if (expenseCompanion != null) {
        await _db.into(_db.expenseDetails).insert(expenseCompanion);
        final participantsCompanions =
            TransactionMapper.toExpenseParticipantsCompanions(transaction);
        if (participantsCompanions.isNotEmpty) {
          await _db.batch((batch) {
            batch.insertAll(_db.expenseParticipants, participantsCompanions);
          });
        }
      }

      final transferCompanion = TransactionMapper.toTransferDetailCompanion(
        transaction,
      );
      if (transferCompanion != null) {
        await _db.into(_db.transferDetails).insert(transferCompanion);
      }

      final tagsCompanions = TransactionMapper.toTransactionTagsCompanions(
        transaction,
      );
      if (tagsCompanions.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.transactionTags, tagsCompanions);
        });
      }
    });
    onChanged?.call();
  }

  @override
  Future<void> updateTransaction(model.Transaction transaction) async {
    await _db.transaction(() async {
      // Update base transaction
      await (_db.update(_db.transactions)
            ..where((t) => t.id.equals(transaction.id)))
          .write(TransactionMapper.toTransactionCompanion(transaction));

      // Handle expense details
      final expenseCompanion = TransactionMapper.toExpenseDetailCompanion(
        transaction,
      );
      if (expenseCompanion != null) {
        await _db
            .into(_db.expenseDetails)
            .insertOnConflictUpdate(expenseCompanion);

        // Update participants: delete old ones and insert new ones
        await (_db.delete(
          _db.expenseParticipants,
        )..where((t) => t.txId.equals(transaction.id))).go();
        final participantsCompanions =
            TransactionMapper.toExpenseParticipantsCompanions(transaction);
        if (participantsCompanions.isNotEmpty) {
          await _db.batch((batch) {
            batch.insertAll(_db.expenseParticipants, participantsCompanions);
          });
        }
      } else {
        // If it's no longer an expense, clean up
        await (_db.delete(
          _db.expenseDetails,
        )..where((t) => t.txId.equals(transaction.id))).go();
        await (_db.delete(
          _db.expenseParticipants,
        )..where((t) => t.txId.equals(transaction.id))).go();
      }

      // Handle transfer details
      final transferCompanion = TransactionMapper.toTransferDetailCompanion(
        transaction,
      );
      if (transferCompanion != null) {
        await _db
            .into(_db.transferDetails)
            .insertOnConflictUpdate(transferCompanion);
      } else {
        // If it's no longer a transfer, clean up
        await (_db.delete(
          _db.transferDetails,
        )..where((t) => t.txId.equals(transaction.id))).go();
      }

      // Handle tags: delete old ones and insert new ones
      await (_db.delete(
        _db.transactionTags,
      )..where((t) => t.txId.equals(transaction.id))).go();
      final tagsCompanions = TransactionMapper.toTransactionTagsCompanions(
        transaction,
      );
      if (tagsCompanions.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(_db.transactionTags, tagsCompanions);
        });
      }
    });
    onChanged?.call();
  }

  @override
  Future<void> softDeleteTransaction(String id) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    onChanged?.call();
  }

  @override
  Future<void> undoSoftDeleteTransaction(String id) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
    onChanged?.call();
  }

  @override
  Future<void> hardDeleteTransaction(String id) async {
    await _attachmentService.deleteAllAttachments(id);
    await _db.transaction(() async {
      await (_db.delete(_db.attachments)..where((t) => t.txId.equals(id))).go();
      await (_db.delete(
        _db.expenseParticipants,
      )..where((t) => t.txId.equals(id))).go();
      await (_db.delete(
        _db.expenseDetails,
      )..where((t) => t.txId.equals(id))).go();
      await (_db.delete(
        _db.transferDetails,
      )..where((t) => t.txId.equals(id))).go();
      await (_db.delete(
        _db.transactionTags,
      )..where((t) => t.txId.equals(id))).go();
      await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
    });
    onChanged?.call();
  }

  @override
  Future<model.Transaction?> findBySourceId(String sourceId) async {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
        _db.expenseDetails,
        _db.expenseDetails.txId.equalsExp(_db.transactions.id),
      ),
      leftOuterJoin(
        _db.transferDetails,
        _db.transferDetails.txId.equalsExp(_db.transactions.id),
      ),
    ])..where(_db.transactions.sourceId.equals(sourceId));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final tx = row.readTable(_db.transactions);
    final expenseDetail = row.readTableOrNull(_db.expenseDetails);
    final transferDetail = row.readTableOrNull(_db.transferDetails);

    List<ExpenseParticipant>? participants;
    if (expenseDetail != null) {
      participants = await (_db.select(
        _db.expenseParticipants,
      )..where((t) => t.txId.equals(tx.id))).get();
    }

    final tags = await (_db.select(_db.tags).join([
      innerJoin(
        _db.transactionTags,
        _db.transactionTags.tagId.equalsExp(_db.tags.id),
      ),
    ])..where(_db.transactionTags.txId.equals(tx.id))).get();

    return TransactionMapper.toModel(
      transaction: tx,
      expenseDetail: expenseDetail,
      participants: participants,
      transferDetail: transferDetail,
      tags: tags.map((r) => r.readTable(_db.tags)).toList(),
    );
  }

  Future<List<model.Transaction>> _mapRowsToTransactions(
    List<TypedResult> rows,
  ) async {
    final transactions = <model.Transaction>[];

    for (final row in rows) {
      final tx = row.readTable(_db.transactions);
      final expenseDetail = row.readTableOrNull(_db.expenseDetails);
      final transferDetail = row.readTableOrNull(_db.transferDetails);

      List<ExpenseParticipant>? participants;
      if (expenseDetail != null) {
        participants = await (_db.select(
          _db.expenseParticipants,
        )..where((t) => t.txId.equals(tx.id))).get();
      }

      final tags = await (_db.select(_db.tags).join([
        innerJoin(
          _db.transactionTags,
          _db.transactionTags.tagId.equalsExp(_db.tags.id),
        ),
      ])..where(_db.transactionTags.txId.equals(tx.id))).get();

      transactions.add(
        TransactionMapper.toModel(
          transaction: tx,
          expenseDetail: expenseDetail,
          participants: participants,
          transferDetail: transferDetail,
          tags: tags.map((r) => r.readTable(_db.tags)).toList(),
        ),
      );
    }

    return transactions;
  }
}
