import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uisocial/models/friendship_model.dart';
import 'package:uisocial/services/friendship_service.dart';
import 'package:uisocial/services/notification_service.dart';
import 'package:uisocial/widgets/custom_bottom_navigation.dart';
import 'package:uisocial/models/notification_model.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final int _currentIndex = 4; // Índice para la pestaña de amigos
  final _searchController = TextEditingController();
  late final FriendshipService _friendshipService;
  late final NotificationService _notificationService;
  List<Map<String, dynamic>> _friends = [];
  List<Friendship> _pendingRequests = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  late int _selectedTabIndex;

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _friendshipService = FriendshipService(supabase);
    _notificationService = NotificationService(supabase);
    _selectedTabIndex = 0; // Por defecto, muestra la pestaña de amigos
    
    // Verificar si hay un tab inicial especificado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('initialTab')) {
        setState(() {
          _selectedTabIndex = args['initialTab'];
        });
      }
      _loadFriends();
      _loadPendingRequests();
    });
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final friends = await _friendshipService.getFriends(userId);
      setState(() {
        _friends = friends;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar amigos: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPendingRequests() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final requests = await _friendshipService.getPendingFriendRequests(userId);
      setState(() {
        _pendingRequests = requests;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar solicitudes: $e')),
      );
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .neq('id', currentUserId)
          .limit(10);

      final friends = await _friendshipService.getFriends(currentUserId);
      final friendIds = friends.map((f) => f['friend_id']).toSet();

      final filteredResults = List<Map<String, dynamic>>.from(response)
          .where((user) => !friendIds.contains(user['id']))
          .toList();

      setState(() {
        _searchResults = filteredResults;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar usuarios: $e')),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _sendFriendRequest(String friendId, String friendUsername) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final userProfile = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .single();

      await _friendshipService.sendFriendRequest(userId, friendId);
      await _notificationService.createFriendRequestNotification(
        userId,
        friendId,
        userProfile['username'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitud enviada a $friendUsername')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar solicitud: $e')),
      );
    }
  }

  Future<void> _acceptFriendRequest(Friendship request) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final userProfile = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .single();

      // Primero aceptar la solicitud de amistad
      await _friendshipService.acceptFriendRequest(
        request.id!,
        userId,
        request.userId,
      );

      // Si la aceptación fue exitosa, crear la notificación
      final notification = EventNotification(
        userId: request.userId,
        type: 'friend_accepted',
        title: 'Solicitud de amistad aceptada',
        message: '${userProfile['username']} ha aceptado tu solicitud de amistad',
        eventId: null,
      );

      await Supabase.instance.client
          .from('notifications')
          .insert(notification.toJson());

      await _loadFriends();
      await _loadPendingRequests();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud aceptada')),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aceptar solicitud: $e')),
      );
    }
  }

  Future<void> _rejectFriendRequest(String friendshipId) async {
    try {
      await _friendshipService.rejectFriendRequest(friendshipId);
      await _loadPendingRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud rechazada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al rechazar solicitud: $e')),
      );
    }
  }

  Future<void> _removeFriend(String friendId, String friendUsername) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      
      // Mostrar diálogo de confirmación
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar amigo'),
          content: Text('¿Estás seguro de que quieres eliminar a $friendUsername de tus amigos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _friendshipService.removeFriend(userId, friendId);
        
        // Actualizar la lista de amigos
        setState(() {
          _friends.removeWhere((friend) => friend['friend_id'] == friendId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$friendUsername eliminado de amigos')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar amigo: $e')),
        );
      }
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
        Navigator.pushReplacementNamed(context, '/eventos');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/notifications');
        break;
      case 4:
        // Ya estamos en la página de amigos
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amigos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar usuarios',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchUsers,
            ),
          ),
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user['avatar_url'] != null
                          ? NetworkImage(user['avatar_url'])
                          : null,
                      child: user['avatar_url'] == null
                          ? Text(user['username'][0].toUpperCase())
                          : null,
                    ),
                    title: Text(user['username']),
                    trailing: TextButton(
                      onPressed: () => _sendFriendRequest(
                        user['id'],
                        user['username'],
                      ),
                      child: const Text('Agregar'),
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: DefaultTabController(
                length: 2,
                initialIndex: _selectedTabIndex,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Mis Amigos'),
                        Tab(text: 'Solicitudes'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Pestaña de amigos
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _friends.isEmpty
                                  ? const Center(
                                      child: Text('No tienes amigos agregados'))
                                  : ListView.builder(
                                      itemCount: _friends.length,
                                      itemBuilder: (context, index) {
                                        final friend = _friends[index];
                                        final profile = friend['profiles'];
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundImage:
                                                profile['avatar_url'] != null
                                                    ? NetworkImage(
                                                        profile['avatar_url'])
                                                    : null,
                                            child: profile['avatar_url'] == null
                                                ? Text(profile['username'][0]
                                                    .toUpperCase())
                                                : null,
                                          ),
                                          title: Text(profile['username']),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.person_remove),
                                            onPressed: () => _removeFriend(
                                              friend['friend_id'],
                                              profile['username'],
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                          // Pestaña de solicitudes pendientes
                          _pendingRequests.isEmpty
                              ? const Center(
                                  child:
                                      Text('No tienes solicitudes pendientes'))
                              : ListView.builder(
                                  itemCount: _pendingRequests.length,
                                  itemBuilder: (context, index) {
                                    final request = _pendingRequests[index];
                                    return FutureBuilder(
                                      future: Supabase.instance.client
                                          .from('profiles')
                                          .select()
                                          .eq('id', request.userId)
                                          .single(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const SizedBox();
                                        }

                                        final profile =
                                            snapshot.data as Map<String, dynamic>;
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundImage:
                                                profile['avatar_url'] != null
                                                    ? NetworkImage(
                                                        profile['avatar_url'])
                                                    : null,
                                            child: profile['avatar_url'] == null
                                                ? Text(profile['username'][0]
                                                    .toUpperCase())
                                                : null,
                                          ),
                                          title: Text(profile['username']),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.check,
                                                    color: Colors.green),
                                                onPressed: () =>
                                                    _acceptFriendRequest(request),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _rejectFriendRequest(
                                                        request.id!),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}