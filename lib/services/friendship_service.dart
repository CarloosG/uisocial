import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uisocial/models/friendship_model.dart';

class FriendshipService {
  final SupabaseClient supabase;

  FriendshipService(this.supabase);

  // Obtener todas las solicitudes de amistad pendientes
  Future<List<Friendship>> getPendingFriendRequests(String userId) async {
    final response = await supabase
        .from('friendships')
        .select()
        .eq('friend_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return response.map((data) => Friendship.fromJson(data)).toList();
  }

  // Obtener lista de amigos
  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    final response = await supabase
        .from('friends')
        .select('friend_id, profiles:friend_id(username, avatar_url)')
        .eq('user_id', userId);

    // Convertir la respuesta a una lista y eliminar duplicados basados en friend_id
    final List<Map<String, dynamic>> friends = List<Map<String, dynamic>>.from(response);
    final uniqueFriends = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var friend in friends) {
      if (!seenIds.contains(friend['friend_id'])) {
        seenIds.add(friend['friend_id']);
        uniqueFriends.add(friend);
      }
    }

    return uniqueFriends;
  }

  // Enviar solicitud de amistad
  Future<void> sendFriendRequest(String userId, String friendId) async {
    // Verificar si ya son amigos
    final existingFriendship = await supabase
        .from('friends')
        .select()
        .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)');

    if (existingFriendship.isNotEmpty) {
      throw Exception('Ya son amigos');
    }

    // Verificar si ya existe una solicitud activa
    final existingRequests = await supabase
        .from('friendships')
        .select()
        .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)')
        .not('status', 'eq', 'removed');

    if (existingRequests.isNotEmpty) {
      throw Exception('Ya existe una solicitud de amistad pendiente');
    }

    // Eliminar cualquier registro anterior con estado 'removed'
    await supabase
        .from('friendships')
        .delete()
        .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)')
        .eq('status', 'removed');

    // Crear nueva solicitud
    await supabase.from('friendships').insert({
      'user_id': userId,
      'friend_id': friendId,
      'status': 'pending'
    });
  }

  // Aceptar solicitud de amistad
  Future<void> acceptFriendRequest(String friendshipId, String userId, String friendId) async {
    try {
      // Actualizar el estado de la solicitud a 'accepted'
      await supabase
          .from('friendships')
          .update({
            'status': 'accepted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId);

      // Eliminar registros existentes si los hay
      await supabase
          .from('friends')
          .delete()
          .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)');

      // Crear registros bidireccionales en la tabla friends
      await supabase.from('friends').insert([
        {'user_id': userId, 'friend_id': friendId},
        {'user_id': friendId, 'friend_id': userId},
      ]);
    } catch (e) {
      print('Error accepting friend request: $e');
      rethrow;
    }
  }

  // Rechazar solicitud de amistad
  Future<void> rejectFriendRequest(String friendshipId) async {
    await supabase
        .from('friendships')
        .update({'status': 'rejected', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', friendshipId);
  }

  // Eliminar amistad
  Future<void> removeFriend(String userId, String friendId) async {
    try {
      // Eliminar registros de ambas tablas
      final response = await supabase.rpc('remove_friendship', params: {
        'user_id_param': userId,
        'friend_id_param': friendId
      });
      
      // Verificar que la amistad se eliminó correctamente
      final remainingFriends = await supabase
          .from('friends')
          .select()
          .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)');
      
      if (remainingFriends.isNotEmpty) {
        throw Exception('La amistad no se eliminó correctamente');
      }
    } catch (e) {
      print('Error al eliminar amistad: $e');
      rethrow;
    }
  }

  // Verificar si son amigos
  Future<bool> areFriends(String userId, String friendId) async {
    final response = await supabase
        .from('friends')
        .select()
        .eq('user_id', userId)
        .eq('friend_id', friendId);

    return response.isNotEmpty;
  }
} 