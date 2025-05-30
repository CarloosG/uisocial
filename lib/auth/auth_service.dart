import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Inicio de sesión con email y contraseña
  Future<AuthResponse> signInWithEmailPassword(
    String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email, 
      password: password
    );
  }

  // Registro con email y contraseña
  Future<AuthResponse> signUpWithEmailPassword(
    String email, String password) async {
    return await _supabase.auth.signUp(
      email: email, 
      password: password
    );
  }

  // Nuevo método: Inicio de sesión con Figma OAuth
  Future<bool> signInWithFigma() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.figma,
        redirectTo: 'your-app-scheme://login-callback', // Cambia esto por tu esquema de app
      );
      return response;
    } catch (e) {
      print('Error al iniciar sesión con Figma: $e');
      return false;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Obtener email del usuario actual
  String? getCurrentUserEmaiil() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  // Obtener ID del usuario actual
  String? getCurrentUserId() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id;
  }

  // Verificar si el usuario está autenticado
  bool get isAuthenticated {
    return _supabase.auth.currentSession != null;
  }

  // Stream para escuchar cambios de autenticación
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }
}