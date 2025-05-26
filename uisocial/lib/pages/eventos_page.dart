
// lib/pages/eventos_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uisocial/models/event_model.dart';
import 'package:uisocial/widgets/custom_bottom_navigation.dart';
import 'package:uisocial/auth/auth_service.dart';

class EventosPage extends StatefulWidget {
  const EventosPage({super.key});

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  final int _currentIndex = 2; // Índice para Eventos (cambiado de la pestaña "Publicar")
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<String> _eventTypes = [
    'Académico',
    'Cultural',
    'Deportivo',
    'Recreativo',
    'Voluntariado',
    'Charla',
    'Taller',
    'Feria',
    'Concierto',
    'Proyección de Cine',
    'Competencia',
  ];
  final TextEditingController _typeController = TextEditingController();
  final List<Map<String, String>> _availableLocations = [
    {'name': 'Burladero', 'coords': '7.139912, -73.120300'},
    {'name': 'Biblioteca UIS', 'coords': '7.140968, -73.120826'},
    {'name': 'Cancha de Fútbol Principal', 'coords': '7.139591, -73.118614'},
    {'name': 'Gimnasio Principal', 'coords': '7.139657, -73.117716'},
    {'name': 'Auditorio Luis A.', 'coords': '7.139856, -73.119887'},
    {'name': 'Piscina UIS', 'coords': '7.141962, -73.121980'},
    {'name': 'Cafetería CT', 'coords': '7.140353, -73.121930'},
  ];
  String? _selectedCoords;
  final _participantsController = TextEditingController();
  final List<String> _visibilityOptions = ['Público', 'Solo amigos'];
  String _selectedVisibility = 'Público';

  DateTime _selectedDate = DateTime.now();
  final authService = AuthService();
  late final EventService _eventService;
  late final Map<String, String> _locationNameMap;
  List<Event> _userEvents = [];
  bool _isLoading = false;
  bool _isEditing = false;
  String? _editEventId;

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _eventService = EventService(supabase);
    _locationNameMap = {for (var loc in _availableLocations) loc['coords']!: loc['name']!};
    _loadUserEvents();
  }

  Future<void> _loadUserEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = authService.getCurrentUserId();
      if (userId != null) {
        final events = await _eventService.getEventsByUser(userId);
        setState(() {
          _userEvents = events;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar eventos: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToPage(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/search');
        break;
      case 2:
        // Ya estamos en la página de eventos
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/notifications');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _typeController.clear();
    _selectedCoords = null;
    _participantsController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _isEditing = false;
      _editEventId = null;
      _selectedVisibility = 'Público';
    });
  }

  void _editEvent(Event event) {
    _nameController.text = event.name;
    _typeController.text = event.type;
    _selectedCoords = event.location;
    _participantsController.text = event.participants.toString();
    _selectedVisibility = event.visibility == 'friends' ? 'Solo amigos' : 'Público';
    setState(() {
      _selectedDate = event.date;
      _isEditing = true;
      _editEventId = event.id;
    });
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userId = authService.getCurrentUserId();
        final email = authService.getCurrentUserEmaiil();

        if (userId == null) {
          throw Exception('Usuario no autenticado');
        }

        final event = Event(
          id: _isEditing ? _editEventId : null,
          name: _nameController.text,
          type: _typeController.text,
          date: _selectedDate,
          location: _selectedCoords!,
          participants: int.parse(_participantsController.text),
          userId: userId,
          createdBy: email,
          createdAt: _isEditing ? null : DateTime.now(),
          visibility: _selectedVisibility == 'Público' ? 'public' : 'friends',
        );

        if (_isEditing) {
          await _eventService.updateEvent(event);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evento actualizado correctamente')),
          );
        } else {
          await _eventService.createEvent(event);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evento creado correctamente')),
          );
        }

        _clearForm();
        await _loadUserEvents();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar evento: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteEvent(String id) async {
    try {
      await _eventService.deleteEvent(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado correctamente')),
      );
      await _loadUserEvents();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar evento: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _clearForm,
              tooltip: 'Cancelar edición',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Editar Evento' : 'Crear Nuevo Evento',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del evento',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _typeController.text.isNotEmpty
                            ? _typeController.text
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de evento',
                          border: OutlineInputBorder(),
                        ),
                        items: _eventTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _typeController.text = newValue!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona un tipo de evento';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCoords,
                        decoration: const InputDecoration(
                          labelText: 'Lugar del evento',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableLocations.map((location) {
                          return DropdownMenuItem<String>(
                            value: location['coords'],
                            child: Text(location['name']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCoords = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona una ubicación';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedVisibility,
                        decoration: const InputDecoration(
                          labelText: 'Visibilidad del evento',
                          border: OutlineInputBorder(),
                        ),
                        items: _visibilityOptions.map((String option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedVisibility = newValue!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona la visibilidad';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha del evento',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _participantsController,
                        decoration: const InputDecoration(
                          labelText: 'Número de participantes',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el número de participantes';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Por favor ingresa un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveEvent,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isEditing
                                      ? 'Actualizar Evento'
                                      : 'Crear Evento',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Mis Eventos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _isLoading && _userEvents.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _userEvents.isEmpty
                    ? const Center(child: Text('No tienes eventos creados'))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _userEvents.length,
                        itemBuilder: (context, index) {
                          final event = _userEvents[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              title: Text(event.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Tipo: ${event.type}'),
                                  Text(
                                    'Fecha: ${DateFormat('dd/MM/yyyy').format(event.date)}',
                                  ),
                                  Text(
                                    'Lugar: ${_locationNameMap[event.location.trim()] ?? event.location}',
                                  ),
                                  Text('Participantes: ${event.participants}'),
                                  Text(
                                    'Visibilidad: ${event.visibility == 'friends' ? 'Solo amigos' : 'Público'}',
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editEvent(event),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Eliminar evento'),
                                        content: const Text(
                                          '¿Estás seguro de que quieres eliminar este evento?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deleteEvent(event.id!);
                                            },
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _navigateToPage,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _selectedCoords = null;
    _participantsController.dispose();
    super.dispose();
  }
}
