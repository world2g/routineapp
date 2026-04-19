import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'linked_devices_screen.dart';
import 'notifications.dart';
 
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user     = provider.user;
    final theme    = Theme.of(context);
 
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── User card ────────────────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      (user?.username ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
 
          const SizedBox(height: 24),
          Text('Settings', style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
 
          // ── Linked devices ───────────────────────────────────────────────
          _SettingsTile(
            icon:     Icons.devices_outlined,
            title:    'Linked Devices',
            subtitle: '${provider.devices.length} device(s) registered',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LinkedDevicesScreen()),
            ),
          ),
          const Divider(height: 1),
 
          // ── Notifications ────────────────────────────────────────────────
          _SettingsTile(
            icon:     Icons.notifications_outlined,
            title:    'Notifications',
            subtitle: provider.notificationsEnabled ? 'Enabled' : 'Disabled',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationCentre()),
            ),
          ),
 
          const SizedBox(height: 32),
 
          // ── Sign out ─────────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<AppProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            icon:  const Icon(Icons.logout, color: Colors.red),
            label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
 
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String?  subtitle;
  final VoidCallback onTap;
 
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading:  Icon(icon, color: Theme.of(context).colorScheme.primary),
      title:    Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap:    onTap,
    );
  }
}