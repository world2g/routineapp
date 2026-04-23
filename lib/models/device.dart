import 'package:flutter/material.dart' show IconData, Icons;
 
class Device {
  final String    id;
  final String    name;
  final String    type;      // 'watch' only (phone/tablet reserved for future)
  final bool      isOnline;
  final DateTime? lastSeen;
 
  const Device({
    required this.id,
    required this.name,
    required this.type,
    this.isOnline = false,
    this.lastSeen,
  });
 
  // ── Supabase ────────────────────────────────────────────────────────────────
  factory Device.fromJson(Map<String, dynamic> data) => Device(
        id:       data['id']        as String,
        name:     data['name']      as String,
        type:     data['type']      as String,
        isOnline: data['is_online'] as bool? ?? false,
        lastSeen: data['last_seen'] == null
            ? null
            : DateTime.parse(data['last_seen'] as String),
      );
 
  Map<String, dynamic> toSupabase() => {
        'name':      name,
        'type':      type,
        'is_online': isOnline,
        if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
      };
 
  Device copyWith({
    String?   id,
    String?   name,
    String?   type,
    bool?     isOnline,
    DateTime? lastSeen,
  }) =>
      Device(
        id:       id       ?? this.id,
        name:     name     ?? this.name,
        type:     type     ?? this.type,
        isOnline: isOnline ?? this.isOnline,
        lastSeen: lastSeen ?? this.lastSeen,
      );
 
  IconData get icon => Icons.watch;
}
 
