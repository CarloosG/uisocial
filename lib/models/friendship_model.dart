import 'package:supabase_flutter/supabase_flutter.dart';

class Friendship {
  final String? id;
  final String userId;
  final String friendId;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Friendship({
    this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'],
      userId: json['user_id'],
      friendId: json['friend_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'friend_id': friendId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
} 