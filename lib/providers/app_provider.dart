import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/mqtt_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService     _auth = AuthService();
  final DatabaseService _db   = DatabaseService();
  final MqttService     _mqtt = MqttService();

  AppUser?    _user;
  List<Task>  _tasks       = [];
  WatchStatus _watchStatus = WatchStatus.disconnected;
  bool        _isLoading   = false;
  String?     _error;

  AppUser?    get user        => _user;
  List<Task>  get tasks       => List.unmodifiable(_tasks);
  WatchStatus get watchStatus => _watchStatus;
  bool        get isLoading   => _isLoading;
  String?     get error       => _error;
  bool        get isLoggedIn  => _user != null;

  String get todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

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

  Future<void> login({
    required String email,
    required String password,
  }) async {
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
    _watchStatus = WatchStatus.disconnected;
    notifyListeners();
  }

  Future<void> loadTodayTasks() async {
    if (_user == null) return;
    _tasks = await _db.getTasksForDate(_user!.id, todayDate);
    notifyListeners();
    _mqtt.publishTasks(_tasks, todayDate);
  }

  Future<void> addTask({required String title, required String time}) async {
    if (_user == null) return;
    final task = Task(
      userId: _user!.id,
      title:  title,
      time:   time,
      date:   todayDate,
    );
    await _db.insertTask(task);
    await loadTodayTasks();
  }

  Future<void> toggleTaskDone(Task task) async {
    final updated = task.copyWith(isDone: !task.isDone);
    await _db.updateTask(updated);
    _tasks = await _db.getTasksForDate(_user!.id, todayDate);
    notifyListeners();
    _mqtt.publishTasks(_tasks, todayDate);
  }

  Future<void> deleteTask(Task task) async {
    if (task.id == null) return;
    await _db.deleteTask(_user!.id, task.id!);
    _tasks = await _db.getTasksForDate(_user!.id, todayDate);
    notifyListeners();
    _mqtt.publishTasks(_tasks, todayDate);
  }

  Future<void> _afterLogin() async {
    await loadTodayTasks();
    try {
      await _connectMqtt();
    } catch (_) {}
  }

  Future<void> _connectMqtt() async {
    _mqtt.onWatchStatusChanged = (status) {
      _watchStatus = status;
      notifyListeners();
    };
    _mqtt.onTaskDoneFromWatch = (taskId) async {
      final task = _tasks.cast<Task?>().firstWhere(
            (t) => t?.id == taskId,
            orElse: () => null,
          );
      if (task != null && !task.isDone) await toggleTaskDone(task);
    };
    await _mqtt.connect(_user!.id);
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? v) { _error = v; notifyListeners(); }
}
