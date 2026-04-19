import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/device.dart';
 
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tasks    = provider.tasks;
    final devices  = provider.devices;
    final total    = tasks.length;
    final done     = tasks.where((t) => t.isDone).length;
    final pct      = total == 0 ? 0.0 : done / total;
 
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ANALYTICS',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
 
          // ── Completion ring ────────────────────────────────────────────
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 160,
                  width:  160,
                  child: CircularProgressIndicator(
                    value:           pct,
                    strokeWidth:     14,
                    color:           Colors.green,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                Column(
                  children: [
                    Text('${(pct * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold)),
                    const Text('complete',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
 
          // ── Stats cards ────────────────────────────────────────────────
          Row(
            children: [
              _StatCard(label: 'Total',     value: '$total',         icon: Icons.list_alt),
              const SizedBox(width: 12),
              _StatCard(label: 'Done',      value: '$done',          icon: Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 12),
              _StatCard(label: 'Remaining', value: '${total - done}', icon: Icons.pending_outlined,     color: Colors.orange),
            ],
          ),
          const SizedBox(height: 32),
 
          // ── Recurring stats ────────────────────────────────────────────
          if (tasks.any((t) => t.isRecurring)) ...[
            const Text('Recurring Tasks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...tasks.where((t) => t.isRecurring).map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.repeat, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.title)),
                      Text(t.frequency ?? '',
                          style: const TextStyle(
                              color: Colors.blueGrey, fontSize: 12)),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
          ],
 
          // ── Device stats ───────────────────────────────────────────────
          const Text('Device Stats',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
 
          if (devices.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.devices_outlined, color: Colors.grey.shade400),
                  const SizedBox(width: 12),
                  Text('No devices linked yet.',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          else
            ...devices.map((d) => _DeviceStatCard(
                  device: d,
                  totalTasks: total,
                  doneTasks:  done,
                )),
 
          const SizedBox(height: 24),
 
          // ── Task breakdown ─────────────────────────────────────────────
          if (tasks.isNotEmpty) ...[
            const Text('Today\'s Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...tasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        t.isDone
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: t.isDone ? Colors.green : Colors.grey,
                        size:  20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t.title)),
                      Text('${t.startTime}–${t.endTime}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
 
// ── Device stat card ───────────────────────────────────────────────────────────
 
class _DeviceStatCard extends StatelessWidget {
  final Device device;
  final int    totalTasks;
  final int    doneTasks;
 
  const _DeviceStatCard({
    required this.device,
    required this.totalTasks,
    required this.doneTasks,
  });
 
  @override
  Widget build(BuildContext context) {
    final pct     = totalTasks == 0 ? 0.0 : doneTasks / totalTasks;
    final lastSeen = device.lastSeen == null
        ? 'Never'
        : DateFormat('MMM d, h:mm a').format(device.lastSeen!);
 
    return Container(
      margin:  const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width:  48,
            height: 48,
            decoration: BoxDecoration(
              color:        Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(device.icon, color: Colors.blueGrey.shade600),
          ),
          const SizedBox(width: 14),
 
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(device.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: device.isOnline
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        device.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 10,
                          color: device.isOnline
                              ? Colors.green.shade700
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Last sync: $lastSeen',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11)),
                const SizedBox(height: 6),
                // Mini progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:           pct,
                    minHeight:       6,
                    color:           Colors.green,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(height: 2),
                Text('$doneTasks / $totalTasks tasks completed today',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
 
// ── Stat card ──────────────────────────────────────────────────────────────────
 
class _StatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color?   color;
 
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });
 
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        (color ?? Colors.blueGrey).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? Colors.blueGrey),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
 