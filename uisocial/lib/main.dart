import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uisocial/pages/eventos_page.dart';
import 'package:uisocial/pages/home_page.dart';
import 'package:uisocial/pages/login_page.dart';
import 'package:uisocial/pages/notificacions_page.dart';
import 'package:uisocial/pages/profile_page.dart';
import 'package:uisocial/pages/search_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFtYmZvb3RsbWZ6aHJpam5ueHZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5NDQ3MzgsImV4cCI6MjA1ODUyMDczOH0.DjZku-vrpdqqcU_YMacAAvLwJTGqy4060KBIyV0K77U',
    url: 'https://qmbfootlmfzhrijnnxvz.supabase.co',
  );
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
      },
    );
  }
}
