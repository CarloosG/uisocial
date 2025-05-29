import 'package:supabase_flutter/supabase_flutter.dart';

class EventService {
  final Supabase supabase;

  EventService({required this.supabase});

  Future<List<Event>> getEvents() async {
    final userId = supabase.auth.currentUser!.id;
    
    // Obtener los IDs de los amigos del usuario actual
    final friendsResponse = await supabase
        .from('friends')
        .select('friend_id')
        .eq('user_id', userId);
    
    final friendIds = (friendsResponse as List)
        .map((friend) => friend['friend_id'] as String)
        .toList();
    
    // Obtener eventos públicos y eventos de amigos
    final response = await supabase
        .from('events')
        .select()
        .or('visibility.eq.public,and(visibility.eq.friends,user_id.in.(${[userId, ...friendIds].join(',')}))')
        .order('created_at', ascending: false); // Ordenar por fecha de creación, más recientes primero
    
    return response.map((event) => Event.fromJson(event)).toList();
  }
} 