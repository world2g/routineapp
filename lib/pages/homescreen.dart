import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/task.dart';
import '../services/mqtt_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh tasks whenever the home screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadTodayTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: const [
          WatchConnectionCard(),
          SizedBox(height: 24),
          Expanded(child: ScheduleSection()),
        ],
      ),
    );
  }
}

// Watch connection card 

class WatchConnectionCard extends StatelessWidget {
  const WatchConnectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AppProvider>().watchStatus;

    final (statusLabel, statusColor, icon) = switch (status) {
      WatchStatus.connected    => ('Connected',    Colors.green,  Icons.watch),
      WatchStatus.connecting   => ('Connecting…',  Colors.orange, Icons.sync),
      WatchStatus.disconnected => ('Disconnected', Colors.red,    Icons.watch_off_outlined),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 50),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'M11 WATCH',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (status == WatchStatus.connecting)
                      const SizedBox(
                        height: 10,
                        width:  10,
                        child:  CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(Icons.circle, color: statusColor, size: 12),
                    const SizedBox(width: 6),
                    Text(statusLabel),
                  ],
                ),
              ],
            ),
          ),
          // Manual sync button
          IconButton(
            tooltip: 'Sync tasks to watch',
            icon: const Icon(Icons.sync),
            onPressed: () {
              final provider = context.read<AppProvider>();
              provider.loadTodayTasks();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing tasks to watch…'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Schedule section 

class ScheduleSection extends StatelessWidget {
  const ScheduleSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tasks    = provider.tasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SCHEDULE',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              '${tasks.where((t) => t.isDone).length}/${tasks.length} done',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Date navigation (display-only for now)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Icon(Icons.arrow_back_ios, size: 16),
            Text('Today', style: TextStyle(fontSize: 18)),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),

        const SizedBox(height: 16),

        // Task list
        if (provider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (tasks.isEmpty)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.playlist_add, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No tasks yet.\nTap + to add one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount:     tasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => TaskTile(task: tasks[i]),
            ),
          ),
      ],
    );
  }
}

// ── Individual task tile ───────────────────────────────────────────────────────

class TaskTile extends StatelessWidget {
  final Task task;
  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => provider.deleteTask(task),
      child: GestureDetector(
        onTap: () => provider.toggleTaskDone(task),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: task.isDone ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: task.isDone ? Colors.green.shade300 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isDone
                      ? Colors.green
                      : Colors.transparent,
                  border: Border.all(
                    color: task.isDone ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: task.isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),

              const SizedBox(width: 14),

              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize:      16,
                        fontWeight:    FontWeight.w500,
                        decoration:   task.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: task.isDone ? Colors.grey : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.time,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Watch icon (tasks that are synced)
              Icon(
                Icons.watch_outlined,
                size:  18,
                color: Colors.blueGrey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}