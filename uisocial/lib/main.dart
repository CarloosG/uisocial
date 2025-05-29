import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uisocial/auth/auth_service.dart';
import 'package:uisocial/pages/eventos_page.dart';
import 'package:uisocial/pages/home_page.dart';
import 'package:uisocial/pages/login_page.dart';
import 'package:uisocial/pages/notifications_page.dart';
import 'package:uisocial/pages/profile_page.dart';
import 'package:uisocial/pages/search_page.dart'; 
import 'package:uisocial/pages/chats_page.dart';
import 'package:uisocial/pages/chat_detail_page.dart';
import 'package:uisocial/pages/map_page.dart';
import 'package:uisocial/pages/friends_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFtYmZvb3RsbWZ6aHJpam5ueHZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5NDQ3MzgsImV4cCI6MjA1ODUyMDczOH0.DjZku-vrpdqqcU_YMacAAvLwJTGqy4060KBIyV0K77U',
    url: 'https://qmbfootlmfzhrijnnxvz.supabase.co',
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
      eventsPerSecond: 10,
    ),
  );
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    final Session? session = data.session;
    
    if (event == AuthChangeEvent.signedIn && session != null) {
      // Usuario autenticado exitosamente
      // Navegar a HomePage si es necesario
    }
  });
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      home: const LoginPage(), 
            routes: {
        '/home': (context) => const HomePage(),
        '/search': (context) => const SearchPage(),
        '/eventos': (context) => const EventosPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/profile': (context) => const ProfilePage(),
        '/chats': (context) => const ChatsPage(),
        '/chat_detail': (context) => const ChatDetailPage(),
        '/map': (context) => const MapPage(eventName: '', location: ''),
         '/friends': (context) => const FriendsPage(),

      },
      localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('es', ''),
      Locale('en', ''),
    ],
    locale: const Locale('es', ''),
    );
  }
}
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  // Escucha cambios en la autenticación (incluyendo OAuth)
  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        // Usuario autenticado, navegar al home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else if (event == AuthChangeEvent.signedOut) {
        // Usuario desconectado, navegar al login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Verificar si ya hay una sesión activa
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }
}