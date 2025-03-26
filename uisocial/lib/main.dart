import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uisocial/pages/login_page.dart'; // Importa tu página de login

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
    );
  }
}
