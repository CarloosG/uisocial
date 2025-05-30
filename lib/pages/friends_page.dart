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

class _FriendsPageState extends State<FriendsPage> with TickerProviderStateMixin {
  final int _currentIndex = 4;
  final _searchController = TextEditingController();
  late final FriendshipService _friendshipService;
  late final NotificationService _notificationService;
  late TabController _tabController;
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
    _selectedTabIndex = 0;
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('initialTab')) {
        setState(() {
          _selectedTabIndex = args['initialTab'];
          _tabController.index = _selectedTabIndex;
        });
      }
      _loadFriends();
      _loadPendingRequests();
    });
  }

  // [Métodos existentes sin cambios - _loadFriends, _loadPendingRequests, etc.]
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
        SnackBar(
          content: Text('Solicitud enviada a $friendUsername'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar solicitud: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
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

      await _friendshipService.acceptFriendRequest(
        request.id!,
        userId,
        request.userId,
      );

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
        const SnackBar(
          content: Text('Solicitud aceptada'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aceptar solicitud: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectFriendRequest(String friendshipId) async {
    try {
      await _friendshipService.rejectFriendRequest(friendshipId);
      await _loadPendingRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud rechazada'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al rechazar solicitud: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removeFriend(String friendId, String friendUsername) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Eliminar amigo', style: TextStyle(fontSize: 20)),
            ],
          ),
          content: Text('¿Estás seguro de que quieres eliminar a $friendUsername de tus amigos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Eliminar'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _friendshipService.removeFriend(userId, friendId);
        
        setState(() {
          _friends.removeWhere((friend) => friend['friend_id'] == friendId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$friendUsername eliminado de amigos'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar amigo: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
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
        break;
    }
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No se encontraron usuarios',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              SizedBox(height: 8),
              Text(
                'Intenta con otro nombre de usuario',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Hero(
                tag: 'user_${user['id']}',
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: user['avatar_url'] != null
                      ? NetworkImage(user['avatar_url'])
                      : null,
                  child: user['avatar_url'] == null
                      ? Text(
                          user['username'][0].toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        )
                      : null,
                ),
              ),
              title: Text(
                user['username'],
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              trailing: ElevatedButton.icon(
                onPressed: () => _sendFriendRequest(user['id'], user['username']),
                icon: Icon(Icons.person_add, size: 18),
                label: Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 16),
            Text('Cargando amigos...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No tienes amigos agregados',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Busca personas para agregar como amigos',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        final profile = friend['profiles'];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Hero(
              tag: 'friend_${friend['friend_id']}',
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.green[100],
                backgroundImage: profile['avatar_url'] != null
                    ? NetworkImage(profile['avatar_url'])
                    : null,
                child: profile['avatar_url'] == null
                    ? Text(
                        profile['username'][0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      )
                    : null,
              ),
            ),
            title: Text(
              profile['username'],
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              'Amigo',
              style: TextStyle(color: Colors.green[600], fontSize: 12),
            ),
            trailing: IconButton(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: 20),
                        ListTile(
                          leading: Icon(Icons.person_remove, color: Colors.red),
                          title: Text('Eliminar amigo'),
                          onTap: () {
                            Navigator.pop(context);
                            _removeFriend(friend['friend_id'], profile['username']);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingRequests() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No tienes solicitudes pendientes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Las nuevas solicitudes aparecerán aquí',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
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
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(child: CircularProgressIndicator(strokeWidth: 2)),
                  title: Text('Cargando...'),
                ),
              );
            }

            final profile = snapshot.data as Map<String, dynamic>;
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.orange[100],
                  backgroundImage: profile['avatar_url'] != null
                      ? NetworkImage(profile['avatar_url'])
                      : null,
                  child: profile['avatar_url'] == null
                      ? Text(
                          profile['username'][0].toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        )
                      : null,
                ),
                title: Text(
                  profile['username'],
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(
                  'Quiere ser tu amigo',
                  style: TextStyle(color: Colors.orange[600], fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _acceptFriendRequest(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(12),
                      ),
                      child: Icon(Icons.check, size: 20),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _rejectFriendRequest(request.id!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(12),
                      ),
                      child: Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          'Amigos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda mejorada
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar usuarios...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: _searchUsers,
            ),
          ),
          
          // Resultados de búsqueda o tabs
          if (_searchResults.isNotEmpty || (_searchController.text.isNotEmpty && !_isSearching))
            _buildSearchResults()
          else
            Expanded(
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: Colors.blue,
                      indicatorWeight: 3,
                      labelStyle: TextStyle(fontWeight: FontWeight.w600),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people, size: 20),
                              SizedBox(width: 8),
                              Text('Mis Amigos'),
                              if (_friends.isNotEmpty) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_friends.length}',
                                    style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications, size: 20),
                              SizedBox(width: 8),
                              Text('Solicitudes'),
                              if (_pendingRequests.isNotEmpty) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_pendingRequests.length}',
                                    style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFriendsList(),
                        _buildPendingRequests(),
                      ],
                    ),
                  ),
                ],
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
    _tabController.dispose();
    super.dispose();
  }
}