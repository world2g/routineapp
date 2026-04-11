import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import '../models/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          WatchConnectionCard(),
          SizedBox(height: 24),
          ScheduleSection(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Watch connection card (unchanged in structure, slightly polished)
// ---------------------------------------------------------------------------

class WatchConnectionCard extends StatelessWidget {
  const WatchConnectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.watch, size: 50),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "M11 WATCH",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 12),
                  SizedBox(width: 5),
                  Text("Connected"),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Schedule section – reads today's events from the shared EventController
// ---------------------------------------------------------------------------

class ScheduleSection extends StatefulWidget {
  const ScheduleSection({super.key});

  @override
  State<ScheduleSection> createState() => _ScheduleSectionState();
}

class _ScheduleSectionState extends State<ScheduleSection> {
  DateTime _selectedDay = DateTime.now();

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDay.year == now.year &&
        _selectedDay.month == now.month &&
        _selectedDay.day == now.day;
  }

  String get _dayLabel {
    if (_isToday) return "Today";
    final now = DateTime.now();
    final diff = _selectedDay.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 1) return "Tomorrow";
    if (diff == -1) return "Yesterday";
    return "${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}";
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDay = _selectedDay.subtract(const Duration(days: 1));
    });
  }

  void _goToNextDay() {
    setState(() {
      _selectedDay = _selectedDay.add(const Duration(days: 1));
    });
  }

  List<CalendarEventData> _eventsForDay(EventController controller) {
    return controller.getEventsOnDay(_selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    final controller = CalendarControllerProvider.of(context).controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SCHEDULE",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        // Day navigator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _goToPreviousDay,
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text(_dayLabel, style: const TextStyle(fontSize: 18)),
            IconButton(
              onPressed: _goToNextDay,
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Listen to completedEvents so ticking "done" refreshes the list
        ValueListenableBuilder<Set<String>>(
          valueListenable: AppState.completedEvents,
          builder: (context, _, _) {
            final events = _eventsForDay(controller);

            if (events.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.event_available,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        "No events scheduled",
                        style: TextStyle(color: Colors.grey[500], fontSize: 15),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Sort by start time
            events.sort((a, b) =>
                (a.startTime ?? a.date).compareTo(b.startTime ?? b.date));

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return ScheduleItem(event: events[index]);
              },
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Individual schedule item card
// ---------------------------------------------------------------------------

class ScheduleItem extends StatelessWidget {
  final CalendarEventData event;

  const ScheduleItem({super.key, required this.event});

  String _formatTime(DateTime? dt) {
    if (dt == null) return "--:--";
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return "$displayHour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    final isDone = AppState.isCompleted(event);
    final color = event.color;

    return Container(
      decoration: BoxDecoration(
        color: isDone ? Colors.grey[100] : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? Colors.grey[300]! : color.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: isDone ? Colors.grey : color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          event.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          "${_formatTime(event.startTime)} – ${_formatTime(event.endTime)}",
          style: TextStyle(
            fontSize: 13,
            color: isDone ? Colors.grey : Colors.black54,
          ),
        ),
        trailing: GestureDetector(
          onTap: () => AppState.toggleDone(event),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDone ? Colors.green : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? Colors.green : Colors.grey,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.check,
              size: 16,
              color: isDone ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}