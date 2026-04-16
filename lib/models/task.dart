class Task {
  final int? id;
  final int userId;
  final String title;
  final String time;   // "HH:mm"  e.g. "08:00"
  final String date;   // "yyyy-MM-dd"
  final bool isDone;

  const Task({
    this.id,
    required this.userId,
    required this.title,
    required this.time,
    required this.date,
    this.isDone = false,
  });

  Task copyWith({
    int? id,
    int? userId,
    String? title,
    String? time,
    String? date,
    bool? isDone,
  }) =>
      Task(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        time: time ?? this.time,
        date: date ?? this.date,
        isDone: isDone ?? this.isDone,
      );

  // ── SQLite ──────────────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'time': time,
        'date': date,
        'is_done': isDone ? 1 : 0,
      };

  factory Task.fromMap(Map<String, dynamic> m) => Task(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        title: m['title'] as String,
        time: m['time'] as String,
        date: m['date'] as String,
        isDone: (m['is_done'] as int) == 1,
      );

  // ── JSON (Django API / MQTT payload) ────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'time': time,
        'date': date,
        'is_done': isDone,
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as int?,
        userId: j['user_id'] as int,
        title: j['title'] as String,
        time: j['time'] as String,
        date: j['date'] as String,
        isDone: j['is_done'] as bool? ?? false,
      );

  @override
  String toString() => 'Task(id: $id, title: $title, time: $time, date: $date, done: $isDone)';
}