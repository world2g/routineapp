import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/task.dart';
import '../models/device.dart';
import '../services/mqtt_service.dart';
import 'linked_devices_screen.dart';
 
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
 
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
 
class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadTodayTasks();
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          DevicesCard(),
          SizedBox(height: 24),
          Expanded(child: ScheduleSection()),
        ],
      ),
    );
  }
}
 
// ── Devices card ───────────────────────────────────────────────────────────────
 
class DevicesCard extends StatelessWidget {
  const DevicesCard({super.key});
 
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final devices  = provider.devices;
    final status   = provider.watchStatus;
 
    final onlineCount = devices.where((d) => d.isOnline).length;
 
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.blueGrey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // ── Header row ─────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.devices, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Linked Devices',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      devices.isEmpty
                          ? 'No devices registered'
                          : '$onlineCount of ${devices.length} online',
                      style: TextStyle(
                          color: Colors.blueGrey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Sync button
              IconButton(
                tooltip:  'Sync tasks to devices',
                icon:     const Icon(Icons.sync),
                onPressed: () {
                  context.read<AppProvider>().loadTodayTasks();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:  Text('Syncing tasks to devices…'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              // Manage button
              IconButton(
                tooltip:  'Manage devices',
                icon:     const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LinkedDevicesScreen()),
                ),
              ),
            ],
          ),
 
          // ── Device list ────────────────────────────────────────────────
          if (devices.isEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LinkedDevicesScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:        Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: Colors.blueGrey.shade600),
                    const SizedBox(width: 8),
                    Text('Add a device',
                        style: TextStyle(color: Colors.blueGrey.shade700)),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            // Watch-type devices show MQTT status; others show Firestore status
            ...devices.map((device) => _DeviceRow(device: device, mqttStatus: status)),
          ],
        ],
      ),
    );
  }
}
 
class _DeviceRow extends StatelessWidget {
  final Device     device;
  final WatchStatus mqttStatus;
  const _DeviceRow({required this.device, required this.mqttStatus});
 
  @override
  Widget build(BuildContext context) {
    // For watch-type devices use live MQTT status; others use Firestore flag
    final isOnline = device.type == 'watch'
        ? mqttStatus == WatchStatus.connected
        : device.isOnline;
    final isConnecting = device.type == 'watch' &&
        mqttStatus == WatchStatus.connecting;
 
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:        Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(device.icon, size: 22, color: Colors.blueGrey.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(device.name,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            if (isConnecting)
              const SizedBox(
                width: 10, height: 10,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.circle,
                  size:  10,
                  color: isOnline ? Colors.green : Colors.grey),
            const SizedBox(width: 6),
            Text(
              isConnecting
                  ? 'Connecting…'
                  : isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 12,
                color: isConnecting
                    ? Colors.orange
                    : isOnline ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── Schedule section ───────────────────────────────────────────────────────────
 
class ScheduleSection extends StatelessWidget {
  const ScheduleSection({super.key});
 
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tasks    = provider.tasks;
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('SCHEDULE',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(
              '${tasks.where((t) => t.isDone).length}/${tasks.length} done',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Icon(Icons.arrow_back_ios, size: 16),
            Text('Today', style: TextStyle(fontSize: 18)),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        const SizedBox(height: 16),
 
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
              itemCount:        tasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder:      (ctx, i) => TaskTile(task: tasks[i]),
            ),
          ),
      ],
    );
  }
}
 
// ── Task tile ──────────────────────────────────────────────────────────────────
 
class TaskTile extends StatelessWidget {
  final Task task;
  const TaskTile({super.key, required this.task});
 
  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
 
    return Dismissible(
      key:       ValueKey(task.taskId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding:   const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color:        Colors.red.shade400,
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
            color:        task.isDone ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: task.isDone ? Colors.green.shade300 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset:     const Offset(0, 2),
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
                  color: task.isDone ? Colors.green : Colors.transparent,
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
                        fontSize:   16,
                        fontWeight: FontWeight.w500,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: task.isDone ? Colors.grey : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${task.startTime} – ${task.endTime}',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12),
                        ),
                        if (task.isRecurring) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.repeat,
                              size: 12, color: Colors.blueGrey.shade400),
                          const SizedBox(width: 2),
                          Text(
                            task.frequency ?? 'recurring',
                            style: TextStyle(
                                fontSize: 11, color: Colors.blueGrey.shade400),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
 
              Icon(Icons.watch_outlined,
                  size: 18, color: Colors.blueGrey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}