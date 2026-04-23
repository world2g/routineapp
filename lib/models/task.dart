class Task {
  final String? id;
  final String  userId;
  final String  title;
  final String  startTime;   // "HH:mm"
  final String  endTime;     // "HH:mm"
  final String  date;        // "yyyy-MM-dd"
  final bool    isDone;
  final bool    isRecurring;
  final String? frequency;   // 'daily' | 'weekdays' | 'weekly' | 'monthly'
 
  const Task({
    this.id,
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
        id:          id          ?? this.id,
        userId:      userId      ?? this.userId,
        title:       title       ?? this.title,
        startTime:   startTime   ?? this.startTime,
        endTime:     endTime     ?? this.endTime,
        date:        date        ?? this.date,
        isDone:      isDone      ?? this.isDone,
        isRecurring: isRecurring ?? this.isRecurring,
        frequency:   frequency   ?? this.frequency,
      );
 
  // ── Supabase ────────────────────────────────────────────────────────────────
  factory Task.fromJson(Map<String, dynamic> data) => Task(
        id:          data['id']           as String?,
        userId:      data['user_id']      as String,
        title:       data['title']        as String,
        startTime:   data['start_time']   as String,
        endTime:     data['end_time']     as String,
        date:        data['date']         as String,
        isDone:      data['is_done']      as bool? ?? false,
        isRecurring: data['is_recurring'] as bool? ?? false,
        frequency:   data['frequency']    as String?,
      );
 
  Map<String, dynamic> toSupabase() => {
        'user_id':      userId,
        'title':        title,
        'start_time':   startTime,
        'end_time':     endTime,
        'date':         date,
        'is_done':      isDone,
        'is_recurring': isRecurring,
        if (frequency != null) 'frequency': frequency,
      };
 
  // ── MQTT payload ────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id':          id,
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
      'Task(id: $id, title: $title, $startTime–$endTime, date: $date, done: $isDone)';
}
 
