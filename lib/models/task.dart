import 'package:cloud_firestore/cloud_firestore.dart';
 
class Task {
  final String? taskId;
  final String  userId;
  final String  title;
  final String  startTime;   // "HH:mm"
  final String  endTime;     // "HH:mm"
  final String  date;        // "yyyy-MM-dd"
  final bool    isDone;
  final bool    isRecurring;
  final String? frequency;   // 'daily' | 'weekdays' | 'weekly' | 'monthly'
 
  const Task({
    this.taskId,
    required this.userId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.date,
    this.isDone      = false,
    this.isRecurring = false,
    this.frequency,
  });
 
  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? startTime,
    String? endTime,
    String? date,
    bool?   isDone,
    bool?   isRecurring,
    String? frequency,
  }) =>
      Task(
        taskId:          id          ?? taskId,
        userId:      userId      ?? this.userId,
        title:       title       ?? this.title,
        startTime:   startTime   ?? this.startTime,
        endTime:     endTime     ?? this.endTime,
        date:        date        ?? this.date,
        isDone:      isDone      ?? this.isDone,
        isRecurring: isRecurring ?? this.isRecurring,
        frequency:   frequency   ?? this.frequency,
      );
 
  // ── Firestore ───────────────────────────────────────────────────────────────
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      taskId:          doc.id,
      userId:      data['userId']      as String,
      title:       data['title']       as String,
      startTime:   data['startTime']   as String,
      endTime:     data['endTime']     as String,
      date:        data['date']        as String,
      isDone:      data['isDone']      as bool? ?? false,
      isRecurring: data['isRecurring'] as bool? ?? false,
      frequency:   data['frequency']   as String?,
    );
  }
 
  Map<String, dynamic> toFirestore() => {
        'userId':      userId,
        'title':       title,
        'startTime':   startTime,
        'endTime':     endTime,
        'date':        date,
        'isDone':      isDone,
        'isRecurring': isRecurring,
        if (frequency != null) 'frequency': frequency,
      };
 
  // ── MQTT payload ────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id':          taskId,
        'title':       title,
        'startTime':   startTime,
        'endTime':     endTime,
        'date':        date,
        'isDone':      isDone,
        'isRecurring': isRecurring,
        if (frequency != null) 'frequency': frequency,
      };
 
  @override
  String toString() =>
      'Task(id: $taskId, title: $title, $startTime–$endTime, date: $date, done: $isDone)';
}
 