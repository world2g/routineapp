import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show IconData, Icons;
 
class Device {
  final String    id;
  final String    name;
  final String    type;      // 'watch' | 'phone' | 'tablet'
  final bool      isOnline;
  final DateTime? lastSeen;
 
  const Device({
    required this.id,
    required this.name,
    required this.type,
    this.isOnline = false,
    this.lastSeen,
  });
 
  factory Device.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Device(
      id:       doc.id,
      name:     data['name']     as String,
      type:     data['type']     as String,
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
    );
  }
 
  Map<String, dynamic> toFirestore() => {
        'name':     name,
        'type':     type,
        'isOnline': isOnline,
        if (lastSeen != null) 'lastSeen': Timestamp.fromDate(lastSeen!),
      };
 
  Device copyWith({
    String? id,
    String? name,
    String? type,
    bool?   isOnline,
    DateTime? lastSeen,
  }) =>
      Device(
        id:       id       ?? this.id,
        name:     name     ?? this.name,
        type:     type     ?? this.type,
        isOnline: isOnline ?? this.isOnline,
        lastSeen: lastSeen ?? this.lastSeen,
      );
 
  IconData get icon {
    switch (type) {
      case 'phone':  return Icons.smartphone;
      case 'tablet': return Icons.tablet;
      default:       return Icons.watch;
    }
  }
}
 