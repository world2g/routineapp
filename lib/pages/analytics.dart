import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import '../models/app_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  /// How many days back to look when calculating the window.
  int _windowDays = 7;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: AppState.completedEvents,
      builder: (context, completedSet, _) {
        final controller = CalendarControllerProvider.of(context).controller;
        final stats = _computeStats(controller);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              const Text(
                "ANALYTICS",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Your schedule compliance at a glance.",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),

              const SizedBox(height: 20),

              // ── Window selector ───────────────────────────────────────────
              _WindowSelector(
                selected: _windowDays,
                onChanged: (v) => setState(() => _windowDays = v),
              ),

              const SizedBox(height: 20),

              // ── Compliance ring ───────────────────────────────────────────
              _ComplianceRing(
                percentage: stats.compliance,
                total: stats.total,
                completed: stats.completed,
              ),

              const SizedBox(height: 24),

              // ── Stat cards ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.event_note,
                      iconColor: Colors.blueGrey,
                      label: "Total Events",
                      value: stats.total.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle,
                      iconColor: Colors.green,
                      label: "Completed",
                      value: stats.completed.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.cancel_outlined,
                      iconColor: Colors.redAccent,
                      label: "Missed",
                      value: stats.missed.toString(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Daily breakdown ───────────────────────────────────────────
              const Text(
                "DAILY BREAKDOWN",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.black54),
              ),
              const SizedBox(height: 12),
              _DailyBreakdown(
                windowDays: _windowDays,
                controller: controller,
              ),

              const SizedBox(height: 24),

              // ── Upcoming / pending events ─────────────────────────────────
              const Text(
                "PENDING TODAY",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.black54),
              ),
              const SizedBox(height: 12),
              _PendingToday(controller: controller),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Stats computation
  // ---------------------------------------------------------------------------

  _Stats _computeStats(EventController controller) {
    final now = DateTime.now();
    int total = 0;
    int completed = 0;

    for (int i = 0; i < _windowDays; i++) {
      final day = now.subtract(Duration(days: i));
      final events = controller.getEventsOnDay(day);
      total += events.length;
      completed += events.where(AppState.isCompleted).length;
    }

    final missed = total - completed;
    final compliance = total == 0 ? 0.0 : completed / total;
    return _Stats(total: total, completed: completed, missed: missed, compliance: compliance);
  }
}

class _Stats {
  final int total;
  final int completed;
  final int missed;
  final double compliance;
  const _Stats({
    required this.total,
    required this.completed,
    required this.missed,
    required this.compliance,
  });
}

// ---------------------------------------------------------------------------
// Window selector
// ---------------------------------------------------------------------------

class _WindowSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _WindowSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [7, 14, 30];
    const labels = ["7 Days", "14 Days", "30 Days"];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final isSelected = selected == options[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(options[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blueGrey[700] : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compliance ring
// ---------------------------------------------------------------------------

class _ComplianceRing extends StatelessWidget {
  final double percentage; // 0.0 – 1.0
  final int total;
  final int completed;

  const _ComplianceRing({
    required this.percentage,
    required this.total,
    required this.completed,
  });

  Color get _ringColor {
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.redAccent;
  }

  String get _label {
    if (total == 0) return "No events yet";
    if (percentage >= 0.8) return "Great job! 🎉";
    if (percentage >= 0.5) return "Keep it up!";
    return "Needs improvement";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    color: Colors.blueGrey[100],
                  ),
                ),
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    color: _ringColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${(percentage * 100).round()}%",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Compliance",
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _ringColor,
            ),
          ),
          if (total > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "$completed of $total events completed",
                style: const TextStyle(fontSize: 13, color: Colors.black45),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat card
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily breakdown bar chart
// ---------------------------------------------------------------------------

class _DailyBreakdown extends StatelessWidget {
  final int windowDays;
  final EventController controller;

  const _DailyBreakdown({
    required this.windowDays,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Show last 7 days regardless of window (to keep the chart readable)
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.map((day) {
              final events = controller.getEventsOnDay(day);
              final total = events.length;
              final done = events.where(AppState.isCompleted).length;
              final ratio = total == 0 ? 0.0 : done / total;

              return _DayBar(
                dayLabel: _dayAbbrev(day),
                ratio: ratio,
                total: total,
                done: done,
                isToday: day.day == now.day &&
                    day.month == now.month &&
                    day.year == now.year,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: Colors.green, label: "Completed"),
              const SizedBox(width: 16),
              _Legend(color: Colors.blueGrey[200]!, label: "Remaining"),
            ],
          ),
        ],
      ),
    );
  }

  String _dayAbbrev(DateTime d) {
    const names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return names[d.weekday - 1];
  }
}

class _DayBar extends StatelessWidget {
  final String dayLabel;
  final double ratio;
  final int total;
  final int done;
  final bool isToday;

  const _DayBar({
    required this.dayLabel,
    required this.ratio,
    required this.total,
    required this.done,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    const maxHeight = 80.0;
    final barHeight = total == 0 ? 6.0 : 16.0 + (ratio * (maxHeight - 16));
    final filledHeight = total == 0 ? 0.0 : ratio * barHeight;

    return Column(
      children: [
        // Small label above bar
        Text(
          total == 0 ? "" : "$done/$total",
          style: const TextStyle(fontSize: 10, color: Colors.black45),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: maxHeight,
          width: 30,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Background bar
              Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Filled bar
              if (filledHeight > 0)
                Container(
                  height: filledHeight,
                  decoration: BoxDecoration(
                    color: ratio >= 0.8 ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? Colors.blueGrey[700] : Colors.black45,
          ),
        ),
        if (isToday)
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.blueGrey[700],
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pending today list
// ---------------------------------------------------------------------------

class _PendingToday extends StatelessWidget {
  final EventController controller;

  const _PendingToday({required this.controller});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final events = controller
        .getEventsOnDay(today)
        .where((e) => !AppState.isCompleted(e))
        .toList();

    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text("All done for today! 🎉",
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final e = events[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: e.color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: e.color.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.radio_button_unchecked, color: e.color, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  e.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              if (e.startTime != null)
                Text(
                  _formatTime(e.startTime!),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'pm' : 'am';
    final display = hour % 12 == 0 ? 12 : hour % 12;
    return "$display:$minute $period";
  }
}