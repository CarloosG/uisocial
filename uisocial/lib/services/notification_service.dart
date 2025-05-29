import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uisocial/models/notification_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final SupabaseClient supabase;

  NotificationService(this.supabase);

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<List<EventNotification>> getNotifications(String userId) async {
    final response = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return response.map<EventNotification>((notification) {
      // Asegurarse de que la fecha se maneje como UTC
      final createdAt = DateTime.parse(notification['created_at']).toUtc();
      return EventNotification.fromJson({
        ...notification,
        'created_at': createdAt.toIso8601String(),
      });
    }).toList();
  }

  Future<void> createEventNotification(String eventId, String eventName, String eventType, DateTime eventDate, TimeOfDay eventTime, String location, String creatorId, String creatorEmail, String visibility) async {
    try {
      // Obtener todos los usuarios excepto el creador
      final usersResponse = await supabase
          .from('profiles')
          .select('id')
          .neq('id', creatorId);

      final List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(usersResponse);

      if (visibility == 'public') {
        for (var user in users) {
          final notification = EventNotification(
            userId: user['id'],
            type: 'event_created',
            title: 'Nuevo Evento: $eventName',
            message: '''${creatorEmail} ha creado un nuevo evento:
Nombre: $eventName
Tipo: $eventType
Fecha: ${DateFormat('dd/MM/yyyy').format(eventDate)}
Hora: ${_formatTimeOfDay(eventTime)}
Lugar: $location''',
            eventId: eventId,
            visibility: visibility,
            createdAt: DateTime.now().toUtc(), // Asegurarse de guardar en UTC
          );

          await supabase.from('notifications').insert(notification.toJson());
        }
      } else if (visibility == 'friends') {
        // Obtener solo los amigos del creador
        final friendsResponse = await supabase
            .from('friends')
            .select('friend_id')
            .eq('user_id', creatorId);

        final List<Map<String, dynamic>> friends = List<Map<String, dynamic>>.from(friendsResponse);
        final friendIds = friends.map((f) => f['friend_id']).toSet();

        for (var user in users) {
          if (friendIds.contains(user['id'])) {
            final notification = EventNotification(
              userId: user['id'],
              type: 'event_created',
              title: 'Nuevo Evento: $eventName',
              message: '''${creatorEmail} ha creado un nuevo evento:
Nombre: $eventName
Tipo: $eventType
Fecha: ${DateFormat('dd/MM/yyyy').format(eventDate)}
Hora: ${_formatTimeOfDay(eventTime)}
Lugar: $location''',
              eventId: eventId,
              visibility: visibility,
              createdAt: DateTime.now().toUtc(), // Asegurarse de guardar en UTC
            );

            await supabase.from('notifications').insert(notification.toJson());
          }
        }
      }
    } catch (e) {
      print('Error creating notifications: $e');
      rethrow;
    }
  }

  Future<void> createFriendRequestNotification(String userId, String friendId, String senderUsername) async {
    final notification = EventNotification(
      userId: friendId,
      type: 'friend_request',
      title: 'Nueva solicitud de amistad',
      message: '$senderUsername quiere ser tu amigo',
      eventId: null,
    );

    await supabase.from('notifications').insert(notification.toJson());
  }

  Future<void> createFriendAcceptedNotification(String userId, String friendId, String accepterUsername) async {
    try {
      final notification = EventNotification(
        userId: userId,
        type: 'friend_accepted',
        title: 'Solicitud de amistad aceptada',
        message: '$accepterUsername ha aceptado tu solicitud de amistad',
        eventId: null,
      );

      await supabase.from('notifications').insert(notification.toJson());
    } catch (e) {
      print('Error creating friend accepted notification: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> deleteNotification(String notificationId) async {
    await supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId);
  }
} 