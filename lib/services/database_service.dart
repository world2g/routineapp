// Firestore backend for tasks and devices.
//
// Structure:
//   users/{userId}/tasks/{taskId}
//   users/{userId}/devices/{deviceId}
//   users/{userId}  ← notificationsEnabled field
 
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../models/device.dart';
 
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
 
  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _db.collection('users').doc(userId);
 
  CollectionReference<Map<String, dynamic>> _tasksRef(String userId) =>
      _userDoc(userId).collection('tasks');
 
  CollectionReference<Map<String, dynamic>> _devicesRef(String userId) =>
      _userDoc(userId).collection('devices');
 
  // ── Tasks ──────────────────────────────────────────────────────────────────
 
  Future<List<Task>> getTasksForDate(String userId, String date) async {
    final snapshot = await _tasksRef(userId)
        .where('date', isEqualTo: date)
        .orderBy('startTime')
        .get();
    return snapshot.docs.map(Task.fromFirestore).toList();
  }
 
  Future<Task> insertTask(Task task) async {
    final ref = await _tasksRef(task.userId).add(task.toFirestore());
    return task.copyWith(id: ref.id);
  }
 
  Future<void> updateTask(Task task) async {
    if (task.taskId == null) return;
    await _tasksRef(task.userId).doc(task.taskId).update(task.toFirestore());
  }
 
  Future<void> deleteTask(String userId, String taskId) async {
    await _tasksRef(userId).doc(taskId).delete();
  }
 
  // ── Devices ────────────────────────────────────────────────────────────────
 
  Future<List<Device>> getDevices(String userId) async {
    final snapshot = await _devicesRef(userId).get();
    return snapshot.docs.map(Device.fromFirestore).toList();
  }
 
  Future<Device> addDevice(String userId, Device device) async {
    final ref = await _devicesRef(userId).add(device.toFirestore());
    return device.copyWith(id: ref.id);
  }
 
  Future<void> updateDevice(String userId, Device device) async {
    await _devicesRef(userId).doc(device.id).update(device.toFirestore());
  }
 
  Future<void> deleteDevice(String userId, String deviceId) async {
    await _devicesRef(userId).doc(deviceId).delete();
  }
 
  Future<void> setDeviceOnline(String userId, String deviceId, bool isOnline) async {
    await _devicesRef(userId).doc(deviceId).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
 
  // ── Notification preference ────────────────────────────────────────────────
 
  Future<bool> getNotificationsEnabled(String userId) async {
    final doc = await _userDoc(userId).get();
    return doc.data()?['notificationsEnabled'] as bool? ?? true;
  }
 
  Future<void> setNotificationsEnabled(String userId, bool enabled) async {
    await _userDoc(userId).set(
      {'notificationsEnabled': enabled},
      SetOptions(merge: true),
    );
  }
}
 