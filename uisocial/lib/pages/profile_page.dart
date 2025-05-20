import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:uisocial/widgets/custom_bottom_navigation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart'; // Necesitas agregar esta dependencia
import 'package:cached_network_image/cached_network_image.dart'; // Necesitas agregar esta dependencia

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final int _currentIndex = 4;
  final _supabase = Supabase.instance.client;
  
  // Variables para almacenar la información del usuario
  String _username = '';
  String _email = '';
  String _bio = '';
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isEditing = false;
  List<dynamic> _friends = [];
  
  // Controladores para los campos de texto en modo edición
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadFriends();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  // Método para cargar la información del perfil del usuario
 Future<void> _loadUserProfile() async {
  setState(() => _isLoading = true);
  
  try {
    final userId = _supabase.auth.currentUser!.id;
    final email = _supabase.auth.currentUser!.email ?? '';
    
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    // Si no existe perfil, crea uno
    if (response == null) {
      await _supabase.from('profiles').insert({
        'id': userId,
        'username': email.split('@').first,
      });
      return _loadUserProfile(); // Recarga después de crear
    }

    setState(() {
      _username = response['username'] ?? '';
      _email = email;
      _bio = response['bio'] ?? '';
      _profileImageUrl = response['avatar_url'];
      _usernameController.text = _username;
      _bioController.text = _bio;
      _isLoading = false;
    });
  } catch (error) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al cargar perfil: $error')),
    );
  }
}
  
  // Método para cargar la lista de amigos
  Future<void> _loadFriends() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Obtener amigos (ajusta esta consulta según tu estructura de datos)
      final response = await _supabase
          .from('friends')
          .select('friend_id, profiles!inner(username, avatar_url)')
          .eq('user_id', userId);
      
      setState(() {
        _friends = response;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar amigos: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Método para actualizar el perfil
 Future<void> _updateProfile() async {
  setState(() => _isLoading = true);
  
  try {
    final userId = _supabase.auth.currentUser!.id;
    
    await _supabase.from('profiles').upsert({  // Cambiado a upsert
      'id': userId,
      'username': _usernameController.text,
      'bio': _bioController.text,

    });

    // Recargar TODOS los datos del perfil
    await _loadUserProfile();
    
    setState(() => _isEditing = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado')),
    );
  } catch (error) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  }
}
  
  // Método para cambiar la foto de perfil
Future<void> _changeProfileImage() async {
  final image = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (image == null) return;

  setState(() => _isLoading = true);
  
  try {
    final userId = _supabase.auth.currentUser!.id;
    final fileName = 'profile_$userId.jpg';
    final fileBytes = await image.readAsBytes();

    await _supabase.storage
      .from('avatars')
      .upload(fileName, fileBytes as File, fileOptions: FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ));

    final imageUrl = _supabase.storage
      .from('avatars')
      .getPublicUrl(fileName);

    await _supabase.from('profiles')
      .update({'avatar_url': imageUrl})
      .eq('id', userId);

    await _loadUserProfile(); // Recargar perfil completo
    
  } catch (error) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  }
}
  
  // Método para navegar a otras páginas
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
  
  // Método para navegar a la página de amigos
  void _navigateToFriendsPage() {
    Navigator.pushNamed(context, '/friends');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Editar Perfil" : "Mi Perfil"),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateProfile,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  _usernameController.text = _username;
                  _bioController.text = _bio;
                  _isEditing = false;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Foto de perfil
                  GestureDetector(
                    onTap: _changeProfileImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _profileImageUrl != null
                              ? CachedNetworkImageProvider(_profileImageUrl!)
                              : null,
                          child: _profileImageUrl == null
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nombre de usuario
                  _isEditing
                      ? TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de usuario',
                            border: OutlineInputBorder(),
                          ),
                        )
                      : Text(
                          _username,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const SizedBox(height: 8),
                  
                  // Email (solo lectura)
                  Text(
                    _email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Biografía
                  _isEditing
                      ? TextField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: 'Biografía',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _bio.isEmpty ? "No hay biografía" : _bio,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                  const SizedBox(height: 24),
                  
                  // Botón para ir a la página de amigos
                  ElevatedButton.icon(
                    onPressed: _navigateToFriendsPage,
                    icon: const Icon(Icons.people),
                    label: Text('Amigos (${_friends.length})'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  
                  // Aquí puedes añadir más secciones del perfil si lo necesitas
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _navigateToPage,
      ),
    );
  }
}