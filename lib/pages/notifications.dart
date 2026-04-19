import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
 
class NotificationCentre extends StatelessWidget {
  const NotificationCentre({super.key});
 
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tasks    = provider.tasks;
    final enabled  = provider.notificationsEnabled;
 
    // Pending = not done and endTime is in the future
    final now       = TimeOfDay.now();
    final pending   = tasks.where((t) {
      if (t.isDone) return false;
      final parts = t.endTime.split(':');
      if (parts.length < 2) return false;
      final end = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      return end.hour > now.hour ||
          (end.hour == now.hour && end.minute > now.minute);
    }).toList();
 
    final overdue = tasks.where((t) {
      if (t.isDone) return false;
      final parts = t.endTime.split(':');
      if (parts.length < 2) return false;
      final end = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      return end.hour < now.hour ||
          (end.hour == now.hour && end.minute <= now.minute);
    }).toList();
 
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Toggle card ──────────────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  enabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  color: enabled
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                title: const Text('Push Notifications',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  enabled
                      ? 'You\'ll be notified when a task is not completed in time'
                      : 'Notifications are currently disabled',
                  style: const TextStyle(fontSize: 12),
                ),
                value:    enabled,
                onChanged: (val) =>
                    context.read<AppProvider>().toggleNotifications(val),
              ),
            ),
          ),
 
          const SizedBox(height: 24),
 
          if (!enabled) ...[
            Center(
              child: Column(
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Notifications are off',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ] else if (tasks.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(Icons.task_alt, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No tasks for today',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ] else ...[
            // ── Overdue section ──────────────────────────────────────────
            if (overdue.isNotEmpty) ...[
              _SectionHeader(
                label: 'Overdue',
                color: Colors.red.shade700,
                icon:  Icons.warning_amber_outlined,
              ),
              const SizedBox(height: 8),
              ...overdue.map((t) => _NotificationTile(
                    title:    t.title,
                    subtitle: 'Was due by ${t.endTime}',
                    color:    Colors.red,
                    icon:     Icons.alarm_off_outlined,
                  )),
              const SizedBox(height: 20),
            ],
 
            // ── Pending section ──────────────────────────────────────────
            if (pending.isNotEmpty) ...[
              _SectionHeader(
                label: 'Upcoming reminders',
                color: Colors.blueGrey.shade700,
                icon:  Icons.schedule_outlined,
              ),
              const SizedBox(height: 8),
              ...pending.map((t) => _NotificationTile(
                    title:    t.title,
                    subtitle: 'Reminder at ${t.endTime}',
                    color:    Colors.blueGrey,
                    icon:     Icons.notifications_outlined,
                  )),
            ],
 
            if (overdue.isEmpty && pending.isEmpty) ...[
              Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 56, color: Colors.green.shade300),
                    const SizedBox(height: 12),
                    const Text('All tasks completed!',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('No pending notifications.',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
 
class _SectionHeader extends StatelessWidget {
  final String   label;
  final Color    color;
  final IconData icon;
  const _SectionHeader(
      {required this.label, required this.color, required this.icon});
 
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ],
    );
  }
}
 
class _NotificationTile extends StatelessWidget {
  final String   title;
  final String   subtitle;
  final Color    color;
  final IconData icon;
  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}