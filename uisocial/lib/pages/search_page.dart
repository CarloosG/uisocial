import 'package:flutter/material.dart';
import 'package:uisocial/auth/auth_gate.dart';
import 'package:uisocial/auth/auth_service.dart';
import 'package:uisocial/widgets/custom_bottom_navigation.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  int _currentIndex = 1; // 
  
  void _navigateToPage(int index) {
    if (index == _currentIndex) return;
    
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
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
        child: Text("Contenido de la página de SearchPage"),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _navigateToPage,
      ),
    );
  }
}