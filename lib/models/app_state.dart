import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

/// Central place for shared state across all pages.
class AppState {
  AppState._();

  /// Single EventController shared across all views.
  static final EventController controller = EventController();

  /// Tracks which events have been marked "Done" (simulating watch button press).
  static final ValueNotifier<Set<String>> completedEvents =
      ValueNotifier<Set<String>>({});

  /// Mark an event as done (called when watch sends "done" signal).
  static void markDone(CalendarEventData event) {
    final updated = Set<String>.from(completedEvents.value)
      ..add(_eventKey(event));
    completedEvents.value = updated;
  }

  /// Toggle done state (for demo purposes via UI).
  static void toggleDone(CalendarEventData event) {
    final key = _eventKey(event);
    final updated = Set<String>.from(completedEvents.value);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    completedEvents.value = updated;
  }

  static bool isCompleted(CalendarEventData event) =>
      completedEvents.value.contains(_eventKey(event));

  static String _eventKey(CalendarEventData event) =>
      '${event.title}_${event.date.toIso8601String().substring(0, 10)}';
}