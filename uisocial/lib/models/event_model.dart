import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart' show TimeOfDay;

class Event {
  final String? id;
  final String name;
  final String type;
  final DateTime date;
  final TimeOfDay time;
  final String location;
  final int participants;
  final String userId;
  final String? createdBy;
  final DateTime? createdAt;
  final String visibility; // 'public' or 'friends'

  Event({
    this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.time,
    required this.location,
    required this.participants,
    required this.userId,
    this.createdBy,
    this.createdAt,
    required this.visibility,
  });

  // Convertir de JSON a Event
  factory Event.fromJson(Map<String, dynamic> json) {
    final timeStr = json['time'] as String;
    final timeParts = timeStr.split(':');
    
    return Event(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      date: DateTime.parse(json['date']),
      time: TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
      location: json['location'],
      participants: json['participants'],
      userId: json['user_id'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      visibility: json['visibility'] ?? 'public',
    );
  }

  // Convertir de Event a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id ?? const Uuid().v4(), // Genera UUID si id es null
      'name': name,
      'type': type,
      'date': date.toIso8601String(),
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'location': location,
      'participants': participants,
      'user_id': userId,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'visibility': visibility,
    };
  }
}

// Clase para manejar operaciones CRUD con eventos
class EventService {
  final SupabaseClient supabase;

  EventService(this.supabase);

  // Obtener todos los eventos
  Future<List<Event>> getEvents() async {
    final response = await supabase
        .from('events')
        .select()
        .order('date', ascending: true);
    
    return response.map((event) => Event.fromJson(event)).toList();
  }

  // Obtener eventos por usuario
  Future<List<Event>> getEventsByUser(String userId) async {
    final response = await supabase
        .from('events')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: true);
    
    return response.map((event) => Event.fromJson(event)).toList();
  }

  // Buscar eventos por nombre o tipo
  Future<List<Event>> searchEvents(String query) async {
    final response = await supabase
        .from('events')
        .select()
        .or('name.ilike.%$query%,type.ilike.%$query%,location.ilike.%$query%')
        .order('date', ascending: true);
    
    return response.map((event) => Event.fromJson(event)).toList();
  }

  // Crear un nuevo evento
  Future<Event> createEvent(Event event) async {
    final response = await supabase
        .from('events')
        .insert(event.toJson())
        .select()
        .single();
    
    return Event.fromJson(response);
  }

  // Actualizar un evento existente
  Future<Event> updateEvent(Event event) async {
    final response = await supabase
        .from('events')
        .update(event.toJson())
        .eq('id', event.id as Object)
        .select()
        .single();
    
    return Event.fromJson(response);
  }

  // Eliminar un evento
  Future<void> deleteEvent(String id) async {
    await supabase
        .from('events')
        .delete()
        .eq('id', id);
  }
}