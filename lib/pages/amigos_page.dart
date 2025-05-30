import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  // Método para cargar la lista de amigos
  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Obtener amigos (ajusta esta consulta según tu estructura de datos)
      final response = await _supabase
          .from('friends')
          .select('friend_id, profiles!inner(id, username, avatar_url)')
          .eq('user_id', userId);
      
      setState(() {
        _friends = response;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar amigos: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para visitar el perfil de un amigo
  void _viewFriendProfile(String friendId) {
    // Implementa la navegación al perfil del amigo
    // Por ejemplo:
    // Navigator.pushNamed(context, '/userProfile', arguments: friendId);
  }

  // Método para eliminar un amigo
  Future<void> _removeFriend(String friendId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Eliminar la relación de amistad (ajusta según tu estructura de datos)
      await _supabase
          .from('friends')
          .delete()
          .match({'user_id': userId, 'friend_id': friendId});
      
      // También puedes eliminar la relación en el otro sentido si es bidireccional
      await _supabase
          .from('friends')
          .delete()
          .match({'user_id': friendId, 'friend_id': userId});
      
      // Actualizar la lista
      _loadFriends();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amigo eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar amigo: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Amigos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implementa la búsqueda de amigos
              // Navigator.pushNamed(context, '/searchFriends');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friends.isEmpty
              ? const Center(
                  child: Text(
                    'No tienes amigos todavía',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index]['profiles'];
                    final friendId = friend['id'];
                    final username = friend['username'] ?? 'Usuario';
                    final avatarUrl = friend['avatar_url'];
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        backgroundImage: avatarUrl != null
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(username),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.person),
                                      title: const Text('Ver perfil'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _viewFriendProfile(friendId);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.message),
                                      title: const Text('Enviar mensaje'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        // Implementa la navegación a la página de mensajes
                                        // Navigator.pushNamed(context, '/messages', arguments: friendId);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.delete, color: Colors.red),
                                      title: const Text('Eliminar amigo', style: TextStyle(color: Colors.red)),
                                      onTap: () {
                                        Navigator.pop(context);
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Confirmar'),
                                            content: Text('¿Estás seguro de que quieres eliminar a $username de tus amigos?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _removeFriend(friendId);
                                                },
                                                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      onTap: () => _viewFriendProfile(friendId),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implementa la navegación a la página de búsqueda de amigos
          // Navigator.pushNamed(context, '/searchFriends');
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}