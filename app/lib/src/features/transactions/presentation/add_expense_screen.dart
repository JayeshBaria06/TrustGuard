import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/transaction.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../ui/theme/app_theme.dart';
import '../../groups/presentation/groups_providers.dart';
import 'transactions_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? transactionId;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    this.transactionId,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _occurredAt = DateTime.now();
  String? _payerMemberId;
  final Set<String> _selectedMemberIds = {};
  bool _isLoading = false;
  bool _isInitialized = false;
  DateTime _createdAt = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _occurredAt) {
      setState(() {
        _occurredAt = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_payerMemberId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a payer')));
      return;
    }
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one participant')),
      );
      return;
    }

    final amountDouble = double.tryParse(_amountController.text);
    if (amountDouble == null || amountDouble <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final totalAmountMinor = MoneyUtils.toMinorUnits(amountDouble);
      final participantCount = _selectedMemberIds.length;
      final splitAmounts = MoneyUtils.splitEqual(
        totalAmountMinor,
        participantCount,
      );

      final participantList = _selectedMemberIds.toList()..sort();
      final participants = <ExpenseParticipant>[];
      for (int i = 0; i < participantList.length; i++) {
        participants.add(
          ExpenseParticipant(
            memberId: participantList[i],
            owedAmountMinor: splitAmounts[i],
          ),
        );
      }

      final validation = Validators.validateExpense(
        totalAmountMinor: totalAmountMinor,
        participantAmountsMinor: splitAmounts,
      );

      if (!validation.isValid) {
        throw Exception(validation.errorMessage);
      }

      final repository = ref.read(transactionRepositoryProvider);
      final now = DateTime.now();

      final transaction = Transaction(
        id: widget.transactionId ?? const Uuid().v4(),
        groupId: widget.groupId,
        type: TransactionType.expense,
        occurredAt: _occurredAt,
        note: _noteController.text.trim(),
        createdAt: widget.transactionId != null ? _createdAt : now,
        updatedAt: now,
        expenseDetail: ExpenseDetail(
          payerMemberId: _payerMemberId!,
          totalAmountMinor: totalAmountMinor,
          splitType: SplitType.equal,
          participants: participants,
        ),
      );

      if (widget.transactionId == null) {
        await repository.createTransaction(transaction);
      } else {
        await repository.updateTransaction(transaction);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving expense: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersByGroupProvider(widget.groupId));
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));
    final isEdit = widget.transactionId != null;

    if (isEdit && !_isInitialized) {
      final txAsync = ref.watch(transactionProvider(widget.transactionId!));
      txAsync.whenData((tx) {
        if (tx != null && tx.expenseDetail != null) {
          _amountController.text = MoneyUtils.fromMinorUnits(
            tx.expenseDetail!.totalAmountMinor,
          ).toStringAsFixed(2);
          _noteController.text = tx.note;
          _occurredAt = tx.occurredAt;
          _createdAt = tx.createdAt;
          _payerMemberId = tx.expenseDetail!.payerMemberId;
          _selectedMemberIds.clear();
          _selectedMemberIds.addAll(
            tx.expenseDetail!.participants.map((p) => p.memberId),
          );
          _isInitialized = true;
          setState(() {});
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _save,
              icon: const Icon(Icons.check),
              tooltip: 'Save',
            ),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('Add members to the group first'));
          }

          if (!_isInitialized && !isEdit) {
            // Default to first member as payer and all members as participants
            _payerMemberId ??= members.first.id;
            if (_selectedMemberIds.isEmpty) {
              _selectedMemberIds.addAll(members.map((m) => m.id));
            }
            _isInitialized = true;
          }

          return groupAsync.when(
            data: (group) {
              final currency = group?.currencyCode ?? 'USD';
              return _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _amountController,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixText: '$currency ',
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an amount';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                              autofocus: !isEdit,
                            ),
                            const SizedBox(height: AppTheme.space16),
                            TextFormField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                labelText: 'Note',
                                hintText: 'What was this for?',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                            const SizedBox(height: AppTheme.space16),
                            ListTile(
                              title: const Text('Date'),
                              subtitle: Text(
                                DateFormat.yMMMd().format(_occurredAt),
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () => _selectDate(context),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space24),
                            Text(
                              'Paid by',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppTheme.space8),
                            DropdownButtonFormField<String>(
                              initialValue: _payerMemberId,
                              items: members.map((m) {
                                return DropdownMenuItem(
                                  value: m.id,
                                  child: Text(m.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _payerMemberId = value);
                                }
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Split between',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      if (_selectedMemberIds.length ==
                                          members.length) {
                                        _selectedMemberIds.clear();
                                      } else {
                                        _selectedMemberIds.addAll(
                                          members.map((m) => m.id),
                                        );
                                      }
                                    });
                                  },
                                  child: Text(
                                    _selectedMemberIds.length == members.length
                                        ? 'Select None'
                                        : 'Select All',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                children: members.map((m) {
                                  return CheckboxListTile(
                                    title: Text(m.displayName),
                                    value: _selectedMemberIds.contains(m.id),
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked == true) {
                                          _selectedMemberIds.add(m.id);
                                        } else {
                                          _selectedMemberIds.remove(m.id);
                                        }
                                      });
                                    },
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space32),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _save,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                isEdit ? 'Update Expense' : 'Add Expense',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading group: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading members: $e')),
      ),
    );
  }
}
