import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../app/providers.dart';
import '../../../core/models/expense_template.dart';
import '../../../ui/components/empty_state.dart';

class TemplatePickerSheet extends ConsumerStatefulWidget {
  final String groupId;
  final void Function(ExpenseTemplate) onSelected;

  const TemplatePickerSheet({
    super.key,
    required this.groupId,
    required this.onSelected,
  });

  @override
  ConsumerState<TemplatePickerSheet> createState() =>
      _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends ConsumerState<TemplatePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider(widget.groupId));
    final theme = Theme.of(context);
    final moneyFormatter = ref.watch(moneyFormatterProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Use Template', style: theme.textTheme.titleLarge),
                      TextButton(
                        onPressed: () {
                          // Close sheet first
                          Navigator.pop(context);
                          // Navigate to management (will be implemented later)
                          // For now, we can maybe show a snackbar or just do nothing if route not ready
                          // context.push('/groups/${widget.groupId}/templates');
                        },
                        child: const Text('Manage Templates'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search templates...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: templatesAsync.when(
                data: (templates) {
                  final filteredTemplates = templates.where((t) {
                    return t.name.toLowerCase().contains(_searchQuery) ||
                        (t.description?.toLowerCase().contains(_searchQuery) ??
                            false);
                  }).toList();

                  if (filteredTemplates.isEmpty) {
                    if (_searchQuery.isNotEmpty) {
                      return const Center(child: Text('No matching templates'));
                    }
                    return const SingleChildScrollView(
                      child: EmptyState(
                        icon: Icons.file_copy_outlined,
                        title: 'No Templates Yet',
                        message:
                            'Save your frequent expenses as templates to use them quickly.',
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filteredTemplates.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final template = filteredTemplates[index];
                      return Slidable(
                        key: ValueKey(template.id),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          dismissible: DismissiblePane(
                            onDismissed: () {
                              ref
                                  .read(templateRepositoryProvider)
                                  .deleteTemplate(template.id);
                            },
                          ),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                ref
                                    .read(templateRepositoryProvider)
                                    .deleteTemplate(template.id);
                              },
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () {
                            widget.onSelected(template);
                            Navigator.pop(context);
                          },
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor:
                                theme.colorScheme.onPrimaryContainer,
                            child: const Icon(Icons.description_outlined),
                          ),
                          title: Text(
                            template.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle:
                              template.description != null &&
                                  template.description!.isNotEmpty
                              ? Text(
                                  template.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (template.amountMinor != null)
                                Text(
                                  moneyFormatter(
                                    template.amountMinor!,
                                    currencyCode: template.currencyCode,
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                Text(
                                  'Variable',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              if (template.usageCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Used ${template.usageCount}x',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        );
      },
    );
  }
}
