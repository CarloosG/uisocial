import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uisocial/models/event_model.dart';
import 'package:uisocial/widgets/custom_bottom_navigation.dart';
import 'package:uisocial/widgets/participation_buttons.dart'; // 👈 Importante
import 'package:uisocial/auth/auth_service.dart';
import 'package:uisocial/pages/map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _currentIndex = 0;
  final authService = AuthService();
  late final EventService _eventService;
  List<Event> _events = [];
  bool _isLoading = false;
  String _filterType = 'Todos';
  List<String> _eventTypes = ['Todos'];
  late PageController _pageController;


  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _eventService = EventService(supabase);
    _loadEvents();
    _pageController = PageController(viewportFraction: 0.7);
  }

  final Map<String, String> _locationNameMap = {
    '7.139912, -73.120300': 'Burladero',
    '7.140968, -73.120826': 'Biblioteca UIS',
    '7.139591, -73.118614': 'Cancha de Fútbol Principal',
    '7.139657, -73.117716': 'Gimnasio Principal',
    '7.139856, -73.119887': 'Auditorio Luis A.',
    '7.141962, -73.121980': 'Piscina UIS',
    '7.140353, -73.121930': 'Cafetería CT',
  };

  final Map<String, String> _placeImages = {
    'Burladero': 'assets/images/lugares/burladero.jpg',
    'Biblioteca UIS': 'assets/images/lugares/biblioteca.jpg',
    'Cancha de Fútbol Principal': 'assets/images/lugares/cancha.jpg',
    'Gimnasio Principal': 'assets/images/lugares/gimnasio.jpg',
    'Auditorio Luis A.': 'assets/images/lugares/auditorio.jpg',
    'Piscina UIS': 'assets/images/lugares/piscina.jpg',
    'Cafetería CT': 'assets/images/lugares/cafeteria.jpg',
  };

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final events = await _eventService.getEvents();

      // Filtrar solo eventos con fecha igual o posterior a hoy
      final now = DateTime.now();
      final upcomingEvents =
          events
              .where(
                (e) => !e.date.isBefore(DateTime(now.year, now.month, now.day)),
              )
              .toList();

      // Ordenar de más cercano a más lejano
      upcomingEvents.sort((a, b) => a.date.compareTo(b.date));

      final types = upcomingEvents.map((e) => e.type).toSet().toList()..sort();

      setState(() {
        _events = upcomingEvents;
        _eventTypes = ['Todos', ...types];
      });
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
      case 1:
        Navigator.pushReplacementNamed(context, '/search');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/eventos');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/notifications');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  List<Event> get _filteredEvents {
    if (_filterType == 'Todos') return _events;
    return _events.where((event) => event.type == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos Disponibles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Actualizar eventos',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/chats');
            },
            tooltip: 'Chats',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Filtrar por tipo: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterType,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _filterType = value;
                        });
                      }
                    },
                    items:
                        _eventTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredEvents.isEmpty
                    ? const Center(child: Text('No hay eventos disponibles'))
                    : RefreshIndicator(
                      onRefresh: _loadEvents,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _filteredEvents.length,
                        itemBuilder: (context, index) {
                          return AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              double scale = 1.0;
                              if (_pageController.position.haveDimensions) {
                                double currentPage =
                                    _pageController.page ??
                                    _pageController.initialPage.toDouble();
                                scale = (1 -
                                        ((currentPage - index).abs() * 0.3))
                                    .clamp(0.7, 1.0);
                              }
                              return Center(
                                child: Transform.scale(
                                  scale: scale,
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 16,
                              ),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 6,
                                shadowColor: Colors.green.withOpacity(0.3),
                                color: Colors.white.withOpacity(0.9),
                                child: Column(
                                  children: [
                                    // --- imagen ---
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: Stack(
                                        children: [
                                          Image.asset(
                                            _placeImages[_locationNameMap[_filteredEvents[index]
                                                        .location
                                                        .trim()] ??
                                                    ''] ??
                                                'assets/images/lugares/default.jpg',
                                            width: double.infinity,
                                            height: 350,
                                            fit: BoxFit.cover,
                                          ),
                                          Container(
                                            height: 350,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color.fromARGB(
                                                    0,
                                                    255,
                                                    255,
                                                    255,
                                                  ),
                                                  const Color.fromARGB(
                                                    66,
                                                    0,
                                                    0,
                                                    0,
                                                  ).withOpacity(0.5),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(16),
                                                  ),
                                            ),
                                          ),
                                          if (_filteredEvents[index]
                                                      .date
                                                      .year ==
                                                  DateTime.now().year &&
                                              _filteredEvents[index]
                                                      .date
                                                      .month ==
                                                  DateTime.now().month &&
                                              _filteredEvents[index].date.day ==
                                                  DateTime.now().day)
                                            Positioned(
                                              top: 12,
                                              right: 12,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade700,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors
                                                          .green
                                                          .shade700
                                                          .withOpacity(0.5),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: const Text(
                                                  'HOY',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // --- contenido textual ---
                                    ListTile(
                                      onTap: () {
                                        final defaultLocation =
                                            "7.119349,-73.122741";
                                        final safeLocation =
                                            (_filteredEvents[index]
                                                    .location
                                                    .isNotEmpty)
                                                ? _filteredEvents[index]
                                                    .location
                                                : defaultLocation;

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => MapPage(
                                                  eventName:
                                                      _filteredEvents[index]
                                                          .name,
                                                  location: safeLocation,
                                                ),
                                          ),
                                        );
                                      },
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                      title: Text(
                                        _filteredEvents[index].name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20,
                                          color: Colors.green.shade900,
                                          shadows: [
                                            Shadow(
                                              color: Colors.green.shade100
                                                  .withOpacity(0.7),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          _buildEventDetail(
                                            Icons.category,
                                            'Tipo',
                                            _filteredEvents[index].type,
                                          ),
                                          _buildEventDetail(
                                            Icons.calendar_today,
                                            'Fecha',
                                            DateFormat(
                                              'EEEE, d MMMM yyyy',
                                              'es',
                                            ).format(
                                              _filteredEvents[index].date,
                                            ),
                                          ),
                                          _buildEventDetail(
                                            Icons.location_on,
                                            'Lugar',
                                            _locationNameMap[_filteredEvents[index]
                                                    .location
                                                    .trim()] ??
                                                'Ubicación desconocida',
                                          ),
                                          _buildEventDetail(
                                            Icons.people,
                                            'Participantes',
                                            _filteredEvents[index].participants
                                                .toString(),
                                          ),
                                          if (_filteredEvents[index]
                                                  .createdBy !=
                                              null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: Text(
                                                'Creado por: ${_filteredEvents[index].createdBy}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green.shade700
                                                      .withOpacity(0.7),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ParticipationButtons(
                                            eventId: _filteredEvents[index].id!,
                                          ),
                                        ],
                                      ),
                                      isThreeLine: true,
                                    ),

                                    // --- botón de calendario ---
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 20,
                                        bottom: 12,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: OutlinedButton.icon(
                                          icon: Icon(
                                            Icons.calendar_month,
                                            color: Colors.green.shade700,
                                          ),
                                          label: Text(
                                            'Agregar al calendario',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: Colors.green.shade700,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                          ),
                                          onPressed: () {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Función de calendario próximamente',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _navigateToPage,
      ),
    );
  }

  Widget _buildEventDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green.shade600),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.green.shade900.withOpacity(0.85)),
            ),
          ),
        ],
      ),
    );
  }
}
