import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signInWithEmailPassword(
      String email, String password) async {
    return await _supabase.auth.signInWithPassword(
        email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmailPassword(
      String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // Nuevo método para iniciar sesión con Discord
  Future<bool> signInWithDiscord() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.discord,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      return true;
    } catch (e) {
      print('Error signing in with Discord: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  String? getCurrentUserEmaiil() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  String? getCurrentUserId() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id;
  }

  // Método para obtener información del usuario actual
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Método para verificar si el usuario está autenticado
  bool isUserSignedIn() {
    return _supabase.auth.currentUser != null;
  }
}