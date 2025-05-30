// lib/pages/eventos_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uisocial/models/event_model.dart';
import 'package:uisocial/widgets/custom_bottom_navigation.dart';
import 'package:uisocial/auth/auth_service.dart';
import 'package:uisocial/services/notification_service.dart';

class EventosPage extends StatefulWidget {
  const EventosPage({super.key});

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  final int _currentIndex = 2;
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
  final Map<String, String> _locationNameMap = {
    '7.139912, -73.120300': 'Burladero',
    '7.140968, -73.120826': 'Biblioteca UIS',
    '7.139591, -73.118614': 'Cancha de Fútbol Principal',
    '7.139657, -73.117716': 'Gimnasio Principal',
    '7.139856, -73.119887': 'Auditorio Luis A.',
    '7.141962, -73.121980': 'Piscina UIS',
    '7.140353, -73.121930': 'Cafetería CT',
  };
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

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedVisibility = 'public';
  final authService = AuthService();
  late final EventService _eventService;
  late final NotificationService _notificationService;
  List<Event> _userEvents = [];
  bool _isLoading = false;
  bool _isEditing = false;
  String? _editEventId;

  // Colores del tema
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF81C784);
  static const Color backgroundWhite = Color(0xFFFAFAFA);
  static const Color cardWhite = Colors.white;
  static const Color textGray = Color(0xFF424242);
  static const Color lightGray = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _eventService = EventService(supabase);
    _notificationService = NotificationService(supabase);
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
      _showSnackBar('Error al cargar eventos: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : lightGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryGreen,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryGreen,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
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
      _selectedTime = TimeOfDay.now();
      _selectedVisibility = 'public';
      _isEditing = false;
      _editEventId = null;
    });
  }

  void _editEvent(Event event) {
    _nameController.text = event.name;
    _typeController.text = event.type;
    _selectedCoords = event.location;
    _participantsController.text = event.participants.toString();
    setState(() {
      _selectedDate = event.date;
      _selectedTime = event.time;
      _selectedVisibility = event.visibility;
      _isEditing = true;
      _editEventId = event.id;
    });
    
    // Scroll to top to show the form
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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
          time: _selectedTime,
          location: _selectedCoords!,
          participants: int.parse(_participantsController.text),
          userId: userId,
          createdBy: email,
          createdAt: _isEditing ? null : DateTime.now(),
          visibility: _selectedVisibility,
        );

        if (_isEditing) {
          await _eventService.updateEvent(event);
          _showSnackBar('Evento actualizado correctamente');
        } else {
          final createdEvent = await _eventService.createEvent(event);
          await _notificationService.createEventNotification(
            createdEvent.id!,
            createdEvent.name,
            createdEvent.type,
            createdEvent.date,
            createdEvent.time,
            _locationNameMap[createdEvent.location.trim()] ?? 'Ubicación desconocida',
            userId,
            email ?? 'Usuario',
            createdEvent.visibility,
          );
          _showSnackBar('Evento creado correctamente');
        }

        _clearForm();
        await _loadUserEvents();
      } catch (e) {
        _showSnackBar('Error al guardar evento: $e', isError: true);
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
      _showSnackBar('Evento eliminado correctamente');
      await _loadUserEvents();
    } catch (e) {
      _showSnackBar('Error al eliminar evento: $e', isError: true);
    }
  }

  Widget _buildEventTypeChip(String type) {
    final colors = {
      'Académico': Colors.blue.shade100,
      'Cultural': Colors.purple.shade100,
      'Deportivo': Colors.orange.shade100,
      'Recreativo': Colors.pink.shade100,
      'Voluntariado': accentGreen.withOpacity(0.2),
      'Charla': Colors.indigo.shade100,
      'Taller': Colors.teal.shade100,
      'Feria': Colors.amber.shade100,
      'Concierto': Colors.red.shade100,
      'Proyección de Cine': Colors.deepPurple.shade100,
      'Competencia': Colors.green.shade100,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors[type] ?? accentGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textGray,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Eventos',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.white),
              onPressed: _clearForm,
              tooltip: 'Cancelar edición',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Card
            Container(
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: lightGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _isEditing ? Icons.edit : Icons.add_circle_outline,
                              color: primaryGreen,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isEditing ? 'Editar Evento' : 'Crear Nuevo Evento',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textGray,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Nombre del evento
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del evento',
                          labelStyle: TextStyle(color: lightGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryGreen, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.event, color: primaryGreen),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Tipo de evento
                      DropdownButtonFormField<String>(
                        value: _typeController.text.isNotEmpty ? _typeController.text : null,
                        decoration: InputDecoration(
                          labelText: 'Tipo de evento',
                          labelStyle: TextStyle(color: lightGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryGreen, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.category, color: primaryGreen),
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
                      const SizedBox(height: 20),

                      // Lugar del evento
                      DropdownButtonFormField<String>(
                        value: _selectedCoords,
                        decoration: InputDecoration(
                          labelText: 'Lugar del evento',
                          labelStyle: TextStyle(color: lightGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryGreen, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.location_on, color: primaryGreen),
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
                      const SizedBox(height: 20),

                      // Fecha y Hora
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: lightGray.withOpacity(0.3)),
                              ),
                              child: InkWell(
                                onTap: () => _selectDate(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: primaryGreen, size: 20),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Fecha',
                                            style: TextStyle(
                                              color: lightGray,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                                            style: const TextStyle(
                                              color: textGray,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: lightGray.withOpacity(0.3)),
                              ),
                              child: InkWell(
                                onTap: () => _selectTime(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time, color: primaryGreen, size: 20),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hora',
                                            style: TextStyle(
                                              color: lightGray,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _selectedTime.format(context),
                                            style: const TextStyle(
                                              color: textGray,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Visibilidad
                      DropdownButtonFormField<String>(
                        value: _selectedVisibility,
                        decoration: InputDecoration(
                          labelText: 'Visibilidad',
                          labelStyle: TextStyle(color: lightGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryGreen, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.visibility, color: primaryGreen),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'public',
                            child: Text('Público'),
                          ),
                          DropdownMenuItem(
                            value: 'friends',
                            child: Text('Solo Amigos'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedVisibility = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Número de participantes
                      TextFormField(
                        controller: _participantsController,
                        decoration: InputDecoration(
                          labelText: 'Número de participantes',
                          labelStyle: TextStyle(color: lightGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryGreen, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.people, color: primaryGreen),
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
                      const SizedBox(height: 32),

                      // Botón de guardar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _isEditing ? 'Actualizar Evento' : 'Crear Evento',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Mis Eventos Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lightGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.event_note,
                    color: primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Mis Eventos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Lista de eventos
            _isLoading && _userEvents.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(lightGreen),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cargando eventos...',
                          style: TextStyle(color: lightGray),
                        ),
                      ],
                    ),
                  )
                : _userEvents.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: lightGray,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tienes eventos creados',
                              style: TextStyle(
                                fontSize: 16,
                                color: lightGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Crea tu primer evento usando el formulario de arriba',
                              style: TextStyle(
                                fontSize: 14,
                                color: lightGray,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _userEvents.length,
                        itemBuilder: (context, index) {
                          final event = _userEvents[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: cardWhite,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header del evento
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              event.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: textGray,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildEventTypeChip(event.type),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: lightGreen.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 20),
                                              color: primaryGreen,
                                              onPressed: () => _editEvent(event),
                                              tooltip: 'Editar evento',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 20),
                                              color: Colors.red.shade600,
                                              onPressed: () => _showDeleteDialog(event),
                                              tooltip: 'Eliminar evento',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),

                                  // Detalles del evento
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildEventDetailRow(
                                          Icons.calendar_today,
                                          'Fecha',
                                          DateFormat('dd/MM/yyyy').format(event.date),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildEventDetailRow(
                                          Icons.access_time,
                                          'Hora',
                                          event.time.format(context),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildEventDetailRow(
                                          Icons.location_on,
                                          'Lugar',
                                          _locationNameMap[event.location.trim()] ?? 'Ubicación desconocida',
                                        ),
                                        const SizedBox(height: 12),
                                        _buildEventDetailRow(
                                          Icons.people,
                                          'Participantes',
                                          '${event.participants}',
                                        ),
                                        const SizedBox(height: 12),
                                        _buildEventDetailRow(
                                          Icons.visibility,
                                          'Visibilidad',
                                          event.visibility == 'public' ? 'Público' : 'Solo Amigos',
                                        ),
                                      ],
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

  Widget _buildEventDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: primaryGreen,
          size: 18,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: lightGray,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: textGray,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Eliminar evento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${event.name}"? Esta acción no se puede deshacer.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: lightGray,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(event.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _participantsController.dispose();
    super.dispose();
  }
}