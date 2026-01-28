import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/models/budget.dart';
import '../../../core/utils/money.dart';
import '../../groups/presentation/groups_providers.dart';

class BudgetSettingsScreen extends ConsumerStatefulWidget {
  final String groupId;
  final Budget? budget;

  const BudgetSettingsScreen({super.key, required this.groupId, this.budget});

  @override
  ConsumerState<BudgetSettingsScreen> createState() =>
      _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends ConsumerState<BudgetSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  late int _limitMinor;
  late String _currencyCode;
  late BudgetPeriod _period;
  late DateTime _startDate;
  DateTime? _endDate;
  String? _selectedTagId;
  late int _alertThreshold;
  late bool _isActive;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    final budget = widget.budget;
    if (budget != null) {
      _nameController = TextEditingController(text: budget.name);
      _limitMinor = budget.limitMinor;
      _amountController = TextEditingController(
        text: MoneyUtils.fromMinorUnits(_limitMinor).toStringAsFixed(2),
      );
      _currencyCode = budget.currencyCode;
      _period = budget.period;
      _startDate = budget.startDate;
      _endDate = budget.endDate;
      _selectedTagId = budget.tagId;
      _alertThreshold = budget.alertThreshold;
      _isActive = budget.isActive;
    } else {
      _nameController = TextEditingController();
      _limitMinor = 0;
      _amountController = TextEditingController();
      _currencyCode = 'USD'; // Will be updated when group loads
      _period = BudgetPeriod.monthly;
      final now = DateTime.now();
      // Default to start of current month
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = null;
      _selectedTagId = null;
      _alertThreshold = 80;
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before new start date, reset end date?
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final doubleVal = double.tryParse(_amountController.text) ?? 0.0;
    _limitMinor = MoneyUtils.toMinorUnits(doubleVal);

    if (_limitMinor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a limit greater than 0')),
      );
      return;
    }
    if (_period == BudgetPeriod.custom && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an end date for custom period'),
        ),
      );
      return;
    }

    final repository = ref.read(budgetRepositoryProvider);

    final budget = Budget(
      id: widget.budget?.id ?? const Uuid().v4(),
      groupId: widget.groupId,
      name: _nameController.text.trim(),
      limitMinor: _limitMinor,
      currencyCode: _currencyCode,
      period: _period,
      startDate: _startDate,
      endDate: _period == BudgetPeriod.custom ? _endDate : null,
      tagId: _selectedTagId,
      alertThreshold: _alertThreshold,
      isActive: _isActive,
      createdAt: widget.budget?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.budget == null) {
        await repository.createBudget(budget);
      } else {
        await repository.updateBudget(budget);
      }
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving budget: $e')));
      }
    }
  }

  Future<void> _deleteBudget() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: const Text(
          'Are you sure you want to delete this budget? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && widget.budget != null) {
      final repository = ref.read(budgetRepositoryProvider);
      await repository.deleteBudget(widget.budget!.id);
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));

    if (widget.budget == null && !_isInitialized) {
      groupAsync.whenData((group) {
        if (group != null) {
          setState(() {
            _currencyCode = group.currencyCode;
            _isInitialized = true;
          });
        }
      });
    }

    final tagsAsync = ref.watch(tagsProvider(widget.groupId));
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget == null ? 'New Budget' : 'Edit Budget'),
        actions: [
          if (widget.budget != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteBudget,
              tooltip: 'Delete Budget',
            ),
          TextButton(onPressed: _saveBudget, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Budget Name',
                hintText: 'e.g., Groceries, Transport',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Limit
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Limit Amount',
                prefixText: NumberFormat.simpleCurrency(
                  name: _currencyCode,
                ).currencySymbol,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if ((double.tryParse(value) ?? 0) <= 0) return 'Must be > 0';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Period
            DropdownButtonFormField<BudgetPeriod>(
              // ignore: deprecated_member_use
              value: _period,
              decoration: const InputDecoration(
                labelText: 'Period',
                border: OutlineInputBorder(),
              ),
              items: BudgetPeriod.values.map((p) {
                return DropdownMenuItem(value: p, child: Text(p.label));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _period = val);
                }
              },
            ),
            const SizedBox(height: 16),

            // Dates
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(dateFormat.format(_startDate)),
                    ),
                  ),
                ),
                if (_period == BudgetPeriod.custom) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEndDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _endDate != null
                              ? dateFormat.format(_endDate!)
                              : 'Select',
                          style: _endDate == null
                              ? TextStyle(color: theme.hintColor)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Tag (Optional)
            tagsAsync.when(
              data: (tags) {
                return DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: _selectedTagId,
                  decoration: const InputDecoration(
                    labelText: 'Category (Optional)',
                    helperText: 'Leave empty for all expenses',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...tags.map(
                      (tag) => DropdownMenuItem<String?>(
                        value: tag.id,
                        child: Text(tag.name),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedTagId = val);
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => const SizedBox(),
            ),
            const SizedBox(height: 24),

            // Alert Threshold
            Text(
              'Alert Threshold: $_alertThreshold%',
              style: theme.textTheme.titleMedium,
            ),
            Slider(
              value: _alertThreshold.toDouble(),
              min: 50,
              max: 100,
              divisions: 10,
              label: '$_alertThreshold%',
              onChanged: (val) {
                setState(() => _alertThreshold = val.round());
              },
            ),
            Text(
              'Notify when spending reaches $_alertThreshold% of the limit.',
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: 16),

            // Active Toggle
            SwitchListTile(
              title: const Text('Active Budget'),
              subtitle: const Text('Pause tracking without deleting'),
              value: _isActive,
              onChanged: (val) {
                setState(() => _isActive = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
