// Manages a local SQLite database for tasks.
// Also provides methods to sync tasks with the Django REST backend so the
// app works offline and uploads changes when connectivity is restored.
//
// Expected Django endpoints:
//   GET    /api/tasks/?date=yyyy-MM-dd   → [{ id, user_id, title, time, date, is_done }, ...]
//   POST   /api/tasks/                   → { id, ... }
//   PATCH  /api/tasks/<id>/              → { id, ... }
//   DELETE /api/tasks/<id>/              → 204

import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class DatabaseService {
  static const String _baseUrl = 'http://192.168.1.100:8000/api';

  static Database? _db;

  // ── Open / create the local SQLite database ──────────────────────────────
  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'routine_planner.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            title   TEXT    NOT NULL,
            time    TEXT    NOT NULL,
            date    TEXT    NOT NULL,
            is_done INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // ── Local CRUD ────────────────────────────────────────────────────────────

  Future<List<Task>> getTasksForDate(int userId, String date) async {
    final db    = await database;
    final rows  = await db.query(
      'tasks',
      where:     'user_id = ? AND date = ?',
      whereArgs: [userId, date],
      orderBy:   'time ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<Task> insertTask(Task task) async {
    final db  = await database;
    final map = task.toMap()..remove('id'); // let SQLite auto-assign id
    final id  = await db.insert('tasks', map);
    return task.copyWith(id: id);
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where:     'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ── Django sync ───────────────────────────────────────────────────────────

  /// Pull today's tasks from Django and upsert them into SQLite.
  Future<void> syncFromServer({
    required int    userId,
    required String date,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks/?date=$date'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) return;

      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      final db = await database;

      for (final item in data) {
        final task = Task.fromJson(item as Map<String, dynamic>);
        final existing = await db.query(
          'tasks',
          where:     'id = ?',
          whereArgs: [task.id],
        );
        if (existing.isEmpty) {
          await db.insert('tasks', task.toMap());
        } else {
          await db.update(
            'tasks',
            task.toMap(),
            where:     'id = ?',
            whereArgs: [task.id],
          );
        }
      }
    } catch (_) {
      // Offline — local data is used as fallback
    }
  }

  /// Push a new task to Django and update the local row with the server-assigned id.
  Future<Task> pushTaskToServer(Task task, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tasks/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 201) {
        final data       = jsonDecode(response.body) as Map<String, dynamic>;
        final serverTask = Task.fromJson(data);
        // Update local row to use the server id
        await updateTask(serverTask);
        return serverTask;
      }
    } catch (_) {
      // Offline — keep local row, sync later
    }
    return task;
  }

  /// Mark a task as done on the server.
  Future<void> markDoneOnServer(Task task, String token) async {
    if (task.id == null) return;
    try {
      await http.patch(
        Uri.parse('$_baseUrl/tasks/${task.id}/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_done': true}),
      );
    } catch (_) {}
  }

  /// Delete a task from the server.
  Future<void> deleteFromServer(int taskId, String token) async {
    try {
      await http.delete(
        Uri.parse('$_baseUrl/tasks/$taskId/'),
        headers: {'Authorization': 'Token $token'},
      );
    } catch (_) {}
  }
}