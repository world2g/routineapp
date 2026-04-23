// lib/services/database_service.dart
//
// Supabase (PostgreSQL) backend for tasks, devices, and notification prefs.
//
// Required tables (run in Supabase SQL editor):
//
//   create table tasks (
//     id           uuid default gen_random_uuid() primary key,
//     user_id      uuid references auth.users on delete cascade not null,
//     title        text not null,
//     start_time   text not null,
//     end_time     text not null,
//     date         text not null,
//     is_done      boolean default false,
//     is_recurring boolean default false,
//     frequency    text
//   );
//
//   create table devices (
//     id        uuid default gen_random_uuid() primary key,
//     user_id   uuid references auth.users on delete cascade not null,
//     name      text not null,
//     type      text not null default 'watch',
//     is_online boolean default false,
//     last_seen timestamptz
//   );
//
//   create table profiles (
//     id                    uuid references auth.users on delete cascade primary key,
//     notifications_enabled boolean default true
//   );
//
//   -- Enable Row Level Security on all three tables, then add policies:
//   alter table tasks    enable row level security;
//   alter table devices  enable row level security;
//   alter table profiles enable row level security;
//
//   create policy "own tasks"    on tasks    for all using (auth.uid() = user_id);
//   create policy "own devices"  on devices  for all using (auth.uid() = user_id);
//   create policy "own profile"  on profiles for all using (auth.uid() = id);
 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/device.dart';
 
class DatabaseService {
  final _supabase = Supabase.instance.client;
 
  // ── Tasks ──────────────────────────────────────────────────────────────────
 
  Future<List<Task>> getTasksForDate(String userId, String date) async {
    final rows = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .eq('date', date)
        .order('start_time');
    return rows.map(Task.fromJson).toList();
  }
 
  Future<Task> insertTask(Task task) async {
    final row = await _supabase
        .from('tasks')
        .insert(task.toSupabase())
        .select()
        .single();
    return Task.fromJson(row);
  }
 
  Future<void> updateTask(Task task) async {
    if (task.id == null) return;
    await _supabase
        .from('tasks')
        .update(task.toSupabase())
        .eq('id', task.id!);
  }
 
  Future<void> deleteTask(String userId, String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }
 
  // ── Devices ────────────────────────────────────────────────────────────────
 
  Future<List<Device>> getDevices(String userId) async {
    final rows = await _supabase
        .from('devices')
        .select()
        .eq('user_id', userId);
    return rows.map(Device.fromJson).toList();
  }
 
  Future<Device> addDevice(String userId, Device device) async {
    final row = await _supabase
        .from('devices')
        .insert({...device.toSupabase(), 'user_id': userId})
        .select()
        .single();
    return Device.fromJson(row);
  }
 
  Future<void> updateDevice(String userId, Device device) async {
    await _supabase
        .from('devices')
        .update(device.toSupabase())
        .eq('id', device.id);
  }
 
  Future<void> deleteDevice(String userId, String deviceId) async {
    await _supabase.from('devices').delete().eq('id', deviceId);
  }
 
  Future<void> setDeviceOnline(
      String userId, String deviceId, bool isOnline) async {
    await _supabase.from('devices').update({
      'is_online': isOnline,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', deviceId);
  }
 
  // ── Notification preference ────────────────────────────────────────────────
 
  Future<bool> getNotificationsEnabled(String userId) async {
    final row = await _supabase
        .from('profiles')
        .select('notifications_enabled')
        .eq('id', userId)
        .maybeSingle();
    return row?['notifications_enabled'] as bool? ?? true;
  }
 
  Future<void> setNotificationsEnabled(String userId, bool enabled) async {
    await _supabase.from('profiles').upsert({
      'id':                    userId,
      'notifications_enabled': enabled,
    });
  }
}
 
