import 'package:flutter/material.dart';
import 'package:uisocial/widgets/custom_bottom_navigation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
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
  
  // Animación para el modo edición
  late AnimationController _editAnimationController;
  late Animation<double> _editAnimation;

  // Colores de la paleta
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _lightGreen = Color(0xFF4CAF50);
  static const Color _softGreen = Color(0xFF81C784);
  static const Color _backgroundWhite = Color(0xFFFAFAFA);
  
  @override
  void initState() {
    super.initState();
    _editAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _editAnimation = CurvedAnimation(
      parent: _editAnimationController,
      curve: Curves.easeInOut,
    );
    _loadUserProfile();
    _loadFriends();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _editAnimationController.dispose();
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
      SnackBar(
        content: Text('Error al cargar perfil: $error'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
        .select('''
          friend_id,
          friend_profile:profiles!friends_friend_id_fkey(username, avatar_url)
        ''')
        .eq('user_id', userId);
      
      setState(() {
        _friends = response;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar amigos: $error'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    _editAnimationController.reverse();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Perfil actualizado correctamente'),
          ],
        ),
        backgroundColor: _lightGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  } catch (error) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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

  Widget _buildProfileImage() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _changeProfileImage,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Hero(
              tag: 'profile_image',
              child: CircleAvatar(
                radius: 70,
                backgroundColor: _softGreen.withOpacity(0.3),
                backgroundImage: _profileImageUrl != null
                    ? CachedNetworkImageProvider(_profileImageUrl!)
                    : null,
                child: _profileImageUrl == null
                    ? Icon(Icons.person, size: 70, color: _primaryGreen)
                    : null,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _lightGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
    );
  }

  Widget _buildInfoCard({
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required String displayValue,
    int maxLines = 1,
    bool isEditing = false,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isEditing
          ? TextFormField(
              key: ValueKey('editing_$label'),
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: _primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _softGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _lightGreen, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _softGreen.withOpacity(0.5)),
                ),
                filled: true,
                fillColor: _backgroundWhite,
              ),
              style: const TextStyle(fontSize: 16),
            )
          : Container(
              key: ValueKey('display_$label'),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: _primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayValue.isEmpty ? "No especificado" : displayValue,
                    style: TextStyle(
                      fontSize: 16,
                      color: displayValue.isEmpty ? Colors.grey[500] : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _primaryGreen,
        title: Text(
          _isEditing ? "Editar Perfil" : "Mi Perfil",
          style: TextStyle(
            color: _primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (!_isEditing)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _lightGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.edit, color: _lightGreen),
                ),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                  _editAnimationController.forward();
                },
              ),
            ),
          if (_isEditing) ...[
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.save, color: Colors.white, size: 20),
              ),
              onPressed: _updateProfile,
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () {
                setState(() {
                  _usernameController.text = _username;
                  _bioController.text = _bio;
                  _isEditing = false;
                });
                _editAnimationController.reverse();
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_lightGreen),
              ),
            )
          : RefreshIndicator(
              color: _lightGreen,
              onRefresh: () async {
                await _loadUserProfile();
                await _loadFriends();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Foto de perfil con animación hero
                    _buildProfileImage(),
                    const SizedBox(height: 24),
                    
                    // Información básica
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildEditableField(
                            label: 'Nombre de usuario',
                            controller: _usernameController,
                            displayValue: _username,
                            isEditing: _isEditing,
                          ),
                          const SizedBox(height: 20),
                          
                          // Email (solo lectura con mejor diseño)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.email_outlined, 
                                       color: _softGreen, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _email,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Biografía
                    _buildInfoCard(
                      child: _buildEditableField(
                        label: 'Biografía',
                        controller: _bioController,
                        displayValue: _bio,
                        maxLines: 3,
                        isEditing: _isEditing,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Botón para ir a la página de amigos con mejor diseño
                    Container(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _navigateToFriendsPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _lightGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.people, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mis Amigos',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_friends.length} ${_friends.length == 1 ? 'amigo' : 'amigos'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _navigateToPage,
      ),
    );
  }
}