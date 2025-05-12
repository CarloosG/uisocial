import 'package:flutter/material.dart';
import 'package:uisocial/auth/auth_gate.dart';
import 'package:uisocial/auth/auth_service.dart';
import 'package:uisocial/widgets/custom_bottom_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; // 0 corresponde a la pestaña de Inicio
  
  void _navigateToPage(int index) {
    if (index == _currentIndex) return;
    
    switch (index) {
      case 0:
        // Ya estamos en la página de inicio
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
        child: Text("Contenido de la página de inicio"),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _navigateToPage,
      ),
    );
  }
}