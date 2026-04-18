import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String? id;
  final String  userId;
  final String  title;
  final String  time;
  final String  date;
  final bool    isDone;

  const Task({this.id, required this.userId, required this.title,
      required this.time, required this.date, this.isDone = false});

  Task copyWith({String? id, String? userId, String? title,
      String? time, String? date, bool? isDone}) =>
      Task(
        id:     id     ?? this.id,
        userId: userId ?? this.userId,
        title:  title  ?? this.title,
        time:   time   ?? this.time,
        date:   date   ?? this.date,
        isDone: isDone ?? this.isDone,
      );

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id:     doc.id,
      userId: data['userId'] as String,
      title:  data['title']  as String,
      time:   data['time']   as String,
      date:   data['date']   as String,
      isDone: data['isDone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId, 'title': title, 'time': time,
        'date': date, 'isDone': isDone,
      };

  Map<String, dynamic> toJson() => {
        'id': id, 'userId': userId, 'title': title,
        'time': time, 'date': date, 'isDone': isDone,
      };

  @override
  String toString() => 'Task(id: $id, title: $title, time: $time, date: $date, done: $isDone)';
}
