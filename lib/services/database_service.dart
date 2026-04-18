import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasksRef(String userId) =>
      _db.collection('users').doc(userId).collection('tasks');

  Future<List<Task>> getTasksForDate(String userId, String date) async {
    final snapshot = await _tasksRef(userId)
        .where('date', isEqualTo: date)
        .orderBy('time')
        .get();
    return snapshot.docs.map(Task.fromFirestore).toList();
  }

  Future<Task> insertTask(Task task) async {
    final ref = await _tasksRef(task.userId).add(task.toFirestore());
    return task.copyWith(id: ref.id);
  }

  Future<void> updateTask(Task task) async {
    if (task.id == null) return;
    await _tasksRef(task.userId).doc(task.id).update(task.toFirestore());
  }

  Future<void> deleteTask(String userId, String taskId) async {
    await _tasksRef(userId).doc(taskId).delete();
  }
}
