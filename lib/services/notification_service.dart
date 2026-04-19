// lib/services/notification_service.dart
//
// Schedules a local push notification for the endTime of each task.
// If the task is completed before its endTime the notification is cancelled.
//
// Android setup required:
//   • Add SCHEDULE_EXACT_ALARM permission to AndroidManifest.xml
//   • Add USE_EXACT_ALARM for Android 13+ (targetSdkVersion 33+)
//
// iOS setup required:
//   • Add notification permissions to Info.plist
 
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';
 
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
 
  static const _channelId   = 'task_reminders';
  static const _channelName = 'Task Reminders';
 
  // ── Init (call once from main.dart before runApp) ───────────────────────────
  static Future<void> init() async {
    tz.initializeTimeZones();
 
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: false, // request at runtime instead
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
 
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios) 
    );
 
    // Request permissions
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
 
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
 
  // ── Schedule ────────────────────────────────────────────────────────────────
  static Future<void> scheduleTaskReminder(Task task) async {
    final scheduled = _taskEndDateTime(task);
    if (scheduled == null) return;
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
 
    await _plugin.zonedSchedule(
      _id(task.id!),
      'Task not completed',
      '${task.title} was due at ${task.endTime}',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders for overdue tasks',
          importance: Importance.high,
          priority:   Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
 
  // ── Cancel ──────────────────────────────────────────────────────────────────
  static Future<void> cancelTaskReminder(String taskId) async {
    await _plugin.cancel(_id(taskId));
  }
 
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
 
  // ── Helpers ─────────────────────────────────────────────────────────────────
  static int _id(String taskId) => taskId.hashCode & 0x7FFFFFFF;
 
  static tz.TZDateTime? _taskEndDateTime(Task task) {
    try {
      final dateParts = task.date.split('-');
      final timeParts = task.endTime.split(':');
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