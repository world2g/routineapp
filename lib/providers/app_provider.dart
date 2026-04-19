import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/device.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/mqtt_service.dart';
import '../services/notification_service.dart';
 
class AppProvider extends ChangeNotifier {
  final AuthService     _auth = AuthService();
  final DatabaseService _db   = DatabaseService();
  final MqttService     _mqtt = MqttService();
 
  AppUser?     _user;
  List<Task>   _tasks                = [];
  List<Device> _devices              = [];
  WatchStatus  _watchStatus          = WatchStatus.disconnected;
  bool         _isLoading            = false;
  String?      _error;
  bool         _notificationsEnabled = true;
 
  AppUser?     get user                 => _user;
  List<Task>   get tasks                => List.unmodifiable(_tasks);
  List<Device> get devices              => List.unmodifiable(_devices);
  WatchStatus  get watchStatus          => _watchStatus;
  bool         get isLoading            => _isLoading;
  String?      get error                => _error;
  bool         get isLoggedIn           => _user != null;
  bool         get notificationsEnabled => _notificationsEnabled;
 
  String get todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());
 
  // ── Bootstrap ───────────────────────────────────────────────────────────────
  Future<void> init() async {
    _setLoading(true);
    try {
      _user = _auth.getCurrentUser();
      if (_user != null) await _afterLogin();
    } catch (_) {
      _user = null;
    } finally {
      _setLoading(false);
    }
  }
 
  // ── Auth ────────────────────────────────────────────────────────────────────
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _setError(null);
    _setLoading(true);
    try {
      _user = await _auth.register(username: username, email: email, password: password);
      await _afterLogin();
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }
 
  Future<void> login({required String email, required String password}) async {
    _setError(null);
    _setLoading(true);
    try {
      _user = await _auth.login(email: email, password: password);
      await _afterLogin();
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }
 
  Future<void> logout() async {
    if (_user == null) return;
    _mqtt.disconnect();
    await _auth.logout();
    _user        = null;
    _tasks       = [];
    _devices     = [];
    _watchStatus = WatchStatus.disconnected;
    notifyListeners();
  }
 
  // ── Tasks ───────────────────────────────────────────────────────────────────
  Future<void> loadTodayTasks() async {
    if (_user == null) return;
    _tasks = await _db.getTasksForDate(_user!.id, todayDate);
    notifyListeners();
    _mqtt.publishTasks(_tasks, todayDate);
  }
 
  Future<void> addTask({
    required String title,
    required String startTime,
    required String endTime,
    bool    isRecurring = false,
    String? frequency,
  }) async {
    if (_user == null) return;
    final task = Task(
      userId:      _user!.id,
      title:       title,
      startTime:   startTime,
      endTime:     endTime,
      date:        todayDate,
      isRecurring: isRecurring,
      frequency:   frequency,
    );
    final saved = await _db.insertTask(task);
    if (_notificationsEnabled) {
      await NotificationService.scheduleTaskReminder(saved);
    }
    await loadTodayTasks();
  }
 
  Future<void> toggleTaskDone(Task task) async {
    final updated = task.copyWith(isDone: !task.isDone);
    await _db.updateTask(updated);
    if (updated.isDone && task.id != null) {
      await NotificationService.cancelTaskReminder(task.id!);
    }
    _tasks = await _db.getTasksForDate(_user!.id, todayDate);
    notifyListeners();
    _mqtt.publishTasks(_tasks, todayDate);
  }
 
  Future<void> deleteTask(Task task) async {
    if (task.id == null) return;
    await _db.deleteTask(_user!.id, task.id!);
    await NotificationService.cancelTaskReminder(task.id!);
    _tasks = await _db.getTasksForDate(_user!.id, todayDate);
    notifyListeners();
    _mqtt.publishTasks(_tasks, todayDate);
  }
 
  // ── Devices ─────────────────────────────────────────────────────────────────
  Future<void> loadDevices() async {
    if (_user == null) return;
    _devices = await _db.getDevices(_user!.id);
    notifyListeners();
  }
 
  Future<void> addDevice({required String name, required String type}) async {
    if (_user == null) return;
    final device = Device(id: '', name: name, type: type);
    final saved  = await _db.addDevice(_user!.id, device);
    _devices = [..._devices, saved];
    notifyListeners();
  }
 
  Future<void> removeDevice(String deviceId) async {
    if (_user == null) return;
    await _db.deleteDevice(_user!.id, deviceId);
    _devices = _devices.where((d) => d.id != deviceId).toList();
    notifyListeners();
  }
 
  // ── Notifications ────────────────────────────────────────────────────────────
  Future<void> loadNotificationPref() async {
    if (_user == null) return;
    _notificationsEnabled = await _db.getNotificationsEnabled(_user!.id);
    notifyListeners();
  }
 
  Future<void> toggleNotifications(bool enabled) async {
    if (_user == null) return;
    _notificationsEnabled = enabled;
    await _db.setNotificationsEnabled(_user!.id, enabled);
    if (!enabled) await NotificationService.cancelAll();
    notifyListeners();
  }
 
  // ── Private ─────────────────────────────────────────────────────────────────
  Future<void> _afterLogin() async {
    await Future.wait([
      loadTodayTasks(),
      loadDevices(),
      loadNotificationPref(),
    ]);
    try {
      await _connectMqtt();
    } catch (_) {}
  }
 
  Future<void> _connectMqtt() async {
    _mqtt.onWatchStatusChanged = (status) {
      _watchStatus = status;
      // Mark first watch-type device online/offline in Firestore
      final watchDevice = _devices.cast<Device?>()
          .firstWhere((d) => d?.type == 'watch', orElse: () => null);
      if (watchDevice != null) {
        _db.setDeviceOnline(
          _user!.id,
          watchDevice.id,
          status == WatchStatus.connected,
        );
        final idx = _devices.indexWhere((d) => d.id == watchDevice.id);
        if (idx != -1) {
          _devices[idx] = watchDevice.copyWith(
            isOnline: status == WatchStatus.connected,
            lastSeen: DateTime.now(),
          );
        }
      }
      notifyListeners();
    };
 
    _mqtt.onTaskDoneFromWatch = (taskId) async {
      final task = _tasks.cast<Task?>()
          .firstWhere((t) => t?.id == taskId, orElse: () => null);
      if (task != null && !task.isDone) await toggleTaskDone(task);
    };
 
    await _mqtt.connect(_user!.id);
  }
 
  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? v) { _error = v; notifyListeners(); }
}
 