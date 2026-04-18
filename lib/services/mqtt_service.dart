// Connects to your Mosquitto broker and keeps the watch in sync.
//
// Topic layout (all scoped to the logged-in user):
//
//   routine/user/<userId>/tasks      ← app PUBLISHES today's task list (JSON)
//   routine/user/<userId>/task/done  ← watch PUBLISHES task id when completed
//   routine/user/<userId>/sync       ← app PUBLISHES "sync" to request the
//                                       watch to refresh its display
//   routine/watch/status             ← watch PUBLISHES its connection status
//
// Payload for the tasks topic:
//   { "date": "yyyy-MM-dd", "tasks": [{ "id": 1, "time": "08:00", "title": "..." }, ...] }
//
// Payload for the done topic:
//   { "task_id": 1 }

import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/task.dart';

enum WatchStatus { disconnected, connecting, connected }

class MqttService {
  // ── Change to your Mosquitto broker address ──────────────────────────────
  static const String _broker = '192.168.1.100';
  static const int    _port   = 1883;
  // ─────────────────────────────────────────────────────────────────────────

  MqttServerClient? _client;
  String? _userId;

  WatchStatus _watchStatus = WatchStatus.disconnected;
  WatchStatus get watchStatus => _watchStatus;

  // Callbacks the AppProvider (or UI) can listen to
  void Function(WatchStatus)? onWatchStatusChanged;
  void Function(int taskId)? onTaskDoneFromWatch;

  // ── Connect ──────────────────────────────────────────────────────────────
  Future<bool> connect(String userId) async {
    _userId = userId;
    _watchStatus = WatchStatus.connecting;
    onWatchStatusChanged?.call(_watchStatus);

    final clientId = 'routine_app_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient(_broker, clientId)
      ..port               = _port
      ..keepAlivePeriod    = 30
      ..connectTimeoutPeriod = 5000
      ..logging(on: false)
      ..onDisconnected       = _onDisconnected
      ..onConnected          = _onConnected
      ..onSubscribed         = _onSubscribed;

    _client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillTopic('routine/user/$userId/app/status')
        .withWillMessage('offline')
        .withWillRetain()
        .startClean();

    try {
      await _client!.connect();
    } catch (e) {
      _client!.disconnect();
      _watchStatus = WatchStatus.disconnected;
      onWatchStatusChanged?.call(_watchStatus);
      return false;
    }

    if (_client!.connectionStatus!.state != MqttConnectionState.connected) {
      _watchStatus = WatchStatus.disconnected;
      onWatchStatusChanged?.call(_watchStatus);
      return false;
    }

    // Subscribe to watch status & task-done topics
    _subscribe('routine/watch/status');
    _subscribe('routine/user/$userId/task/done');

    // Listen to all incoming messages
    _client!.updates!.listen(_onMessage);

    return true;
  }

  // ── Disconnect ───────────────────────────────────────────────────────────
  void disconnect() {
    _client?.disconnect();
  }

  // ── Publish today's tasks to the watch ──────────────────────────────────
  void publishTasks(List<Task> tasks, String date) {
    if (_client == null ||
        _client!.connectionStatus!.state != MqttConnectionState.connected) {
      return;
    }

    final payload = jsonEncode({
      'date': date,
      'tasks': tasks
          .map((t) => {'id': t.id, 'time': t.time, 'title': t.title})
          .toList(),
    });

    _publish('routine/user/$_userId/tasks', payload, retain: true);
  }

  /// Tell the watch to refresh its display.
  void requestSync() {
    _publish('routine/user/$_userId/sync', 'sync');
  }

  // ── Private helpers ──────────────────────────────────────────────────────
  void _subscribe(String topic) {
    _client!.subscribe(topic, MqttQos.atLeastOnce);
  }

  void _publish(String topic, String payload, {bool retain = false}) {
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: retain,
    );
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final msg in messages) {
      final topic   = msg.topic;
      final payload = MqttPublishPayload.bytesToStringAsString(
        (msg.payload as MqttPublishMessage).payload.message,
      );

      if (topic == 'routine/watch/status') {
        if (payload == 'online') {
          _watchStatus = WatchStatus.connected;
        } else {
          _watchStatus = WatchStatus.disconnected;
        }
        onWatchStatusChanged?.call(_watchStatus);
      }

      if (topic == 'routine/user/$_userId/task/done') {
        try {
          final data   = jsonDecode(payload) as Map<String, dynamic>;
          final taskId = data['task_id'] as int;
          onTaskDoneFromWatch?.call(taskId);
        } catch (_) {}
      }
    }
  }

  void _onConnected()  {}
  void _onDisconnected() {
    _watchStatus = WatchStatus.disconnected;
    onWatchStatusChanged?.call(_watchStatus);
  }
  void _onSubscribed(String topic) {}
}