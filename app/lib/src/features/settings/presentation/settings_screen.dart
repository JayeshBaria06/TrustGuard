import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/lock_providers.dart';
import '../../../app/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(appLockStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Security'),
          ListTile(
            leading: const Icon(Icons.pin),
            title: Text(lockState.hasPin ? 'Change PIN' : 'Set PIN'),
            subtitle: Text(
              lockState.hasPin ? 'PIN is active' : 'PIN is not set',
            ),
            onTap: () => context.push('/settings/pin-setup'),
          ),
          if (lockState.hasPin) ...[
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric Unlock'),
              subtitle: const Text('Use fingerprint or face ID'),
              value: lockState.isBiometricEnabled,
              onChanged: (value) => ref
                  .read(appLockStateProvider.notifier)
                  .setBiometricEnabled(value),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.timer_outlined),
              title: const Text('Lock on Background'),
              subtitle: const Text('Lock app when minimized'),
              value: lockState.lockOnBackground,
              onChanged: (value) => ref
                  .read(appLockStateProvider.notifier)
                  .setLockOnBackground(value),
            ),
            ListTile(
              leading: const Icon(Icons.no_encryption_gmailerrorred_outlined),
              title: const Text('Remove PIN'),
              textColor: Theme.of(context).colorScheme.error,
              iconColor: Theme.of(context).colorScheme.error,
              onTap: () => _showRemovePinDialog(context, ref),
            ),
          ],
          const Divider(),
          _buildSectionHeader(context, 'Data'),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: const Text('Export & Backup'),
            onTap: () {
              // TODO: Navigate to export/backup screen
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('TrustGuard'),
            subtitle: Text('Version 1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text(
              'Fully offline, your data never leaves your device.',
            ),
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showRemovePinDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PIN?'),
        content: const Text(
          'This will disable app lock. Your data will no longer be protected by a PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(appLockServiceProvider).removePin();
      await ref.read(appLockStateProvider.notifier).init();
    }
  }
}
