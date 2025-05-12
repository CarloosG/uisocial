import 'package:flutter/material.dart';
import 'package:uisocial/auth/auth_gate.dart';
import 'package:uisocial/auth/auth_service.dart';
import 'package:uisocial/widgets/custom_bottom_navigation.dart';

class EventosPage extends StatefulWidget {
  const EventosPage({super.key});

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  int _currentIndex = 2; // 0 corresponde a la pestaña de Inicio
  
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
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/notifications');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
      ),
      body: const Center(
        child: Text("Contenido de la página de eventos"),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _navigateToPage,
      ),
    );
  }
}