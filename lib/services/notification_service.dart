// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'task_reminders';
  static const String _channelName = 'Task Reminders';

  // ── Init ────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings:  InitializationSettings(android: android, iOS: ios),
    );

    // Request Android permissions
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Request iOS permissions
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ── Schedule Notification ───────────────────────────────────────────────
  static Future<void> scheduleTaskReminder(Task task) async {
    if (task.id == null) return;

    final scheduled = _taskEndDateTime(task);
    if (scheduled == null) return;

    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: _generateId(task.id!),
      title: 'Task not completed',
      body: '${task.title} was due at ${task.endTime}',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders for overdue tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ── Cancel Notification ─────────────────────────────────────────────────
  static Future<void> cancelTaskReminder(String? taskId) async {
    if (taskId == null) return;
    await _plugin.cancel(
      id: _generateId(taskId)
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static int _generateId(String taskId) {
    return taskId.codeUnits.fold(0, (sum, unit) => sum + unit);
  }

  static tz.TZDateTime? _taskEndDateTime(Task task) {
    try {
      final dateParts = task.date.split('-');    // yyyy-MM-dd
      final timeParts = task.endTime.split(':'); // HH:mm

      if (dateParts.length != 3 || timeParts.length != 2) return null;

      return tz.TZDateTime(
        tz.local,
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (_) {
      return null;
    }
  }
}
