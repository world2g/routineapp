import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<AppProvider>().tasks;
    final total = tasks.length;
    final done  = tasks.where((t) => t.isDone).length;
    final pct   = total == 0 ? 0.0 : done / total;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ANALYTICS',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // ── Completion ring ──────────────────────────────────────────────
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 160,
                  width:  160,
                  child: CircularProgressIndicator(
                    value:       pct,
                    strokeWidth: 14,
                    color:       Colors.green,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${(pct * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const Text('complete',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Stats cards ──────────────────────────────────────────────────
          Row(
            children: [
              _StatCard(
                  label: 'Total', value: '$total', icon: Icons.list_alt),
              const SizedBox(width: 12),
              _StatCard(
                  label: 'Done',
                  value: '$done',
                  icon: Icons.check_circle_outline,
                  color: Colors.green),
              const SizedBox(width: 12),
              _StatCard(
                  label: 'Remaining',
                  value: '${total - done}',
                  icon: Icons.pending_outlined,
                  color: Colors.orange),
            ],
          ),

          const SizedBox(height: 32),

          // ── Task breakdown ───────────────────────────────────────────────
          if (tasks.isNotEmpty) ...[
            const Text('Breakdown',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...tasks.map(
              (t) => Padding(
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
                    Text(t.time,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

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
          color: (color ?? Colors.blueGrey).withOpacity(0.1),
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
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}