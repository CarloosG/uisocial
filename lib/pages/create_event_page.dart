import 'package:flutter/material.dart';
import '../widgets/create_event_form.dart';
import '../models/event.dart';
import 'package:uuid/uuid.dart';

class CreateEventPage extends StatelessWidget { // <-- CAMBIADO
  final List<Event> events = [];

  void _handleCreateEvent(Map<String, dynamic> data) {
    final newEvent = Event(
      id: const Uuid().v4(),
      title: data['title'],
      type: data['type'],
      date: DateTime.parse(data['date']),
      location: data['location'],
      participants: data['participants'],
      creatorId: 'demo_user', // Temporal
      createdAt: DateTime.now(),
    );
    events.add(newEvent);
    print('Evento creado: ${newEvent.title}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crear Evento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CreateEventForm(onCreate: _handleCreateEvent),
      ),
    );
  }
}