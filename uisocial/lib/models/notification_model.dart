import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class EventNotification {
  final String? id;
  final String userId;
  final String type; // 'event_created', etc.
  final String title;
  final String message;
  final String? eventId;
  final String? visibility;
  final bool isRead;
  final DateTime createdAt;

  EventNotification({
    String? id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.eventId,
    this.visibility,
    this.isRead = false,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory EventNotification.fromJson(Map<String, dynamic> json) {
    return EventNotification(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      eventId: json['event_id'],
      visibility: json['visibility'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'event_id': eventId,
      'visibility': visibility,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  EventNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    String? eventId,
    String? visibility,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return EventNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      eventId: eventId ?? this.eventId,
      visibility: visibility ?? this.visibility,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 