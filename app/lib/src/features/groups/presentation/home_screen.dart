import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../ui/theme/app_theme.dart';
import 'groups_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsWithMemberCountProvider);
    final showArchived = ref.watch(showArchivedGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TrustGuard'),
        actions: [
          IconButton(
            icon: Icon(showArchived ? Icons.archive : Icons.archive_outlined),
            onPressed: () =>
                ref.read(showArchivedGroupsProvider.notifier).state =
                    !showArchived,
            tooltip: showArchived ? 'Hide Archived' : 'Show Archived',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      showArchived
                          ? Icons.archive_outlined
                          : Icons.group_off_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: AppTheme.space24),
                    Text(
                      showArchived ? 'No archived groups' : 'No groups yet',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      showArchived
                          ? 'Archived groups will appear here'
                          : 'Create a group to start tracking expenses and settlements with your friends.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.space16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final item = groups[index];
              final group = item.group;
              final isArchived = group.archivedAt != null;

              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: AppTheme.space16),
                child: ListTile(
                  title: Text(
                    group.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: isArchived
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    '${item.memberCount} members • ${group.currencyCode}',
                    style: TextStyle(
                      fontStyle: isArchived ? FontStyle.italic : null,
                    ),
                  ),
                  trailing: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Balance', style: TextStyle(fontSize: 11)),
                      Text(
                        'Settled',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => context.push('/group/${group.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: AppTheme.space16),
              Text('Error loading groups: $error'),
              const SizedBox(height: AppTheme.space16),
              ElevatedButton(
                onPressed: () => ref.refresh(groupsWithMemberCountProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/group/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
      ),
    );
  }
}
