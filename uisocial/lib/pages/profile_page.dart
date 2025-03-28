import 'package:flutter/material.dart';
import 'package:uisocial/auth/auth_gate.dart';
import 'package:uisocial/auth/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final authservice = AuthService();
  void logout() async{
    await authservice.signOut();
  }
  
  @override
  Widget build(BuildContext context) {
    
    final currentEmail = authservice.getCurrentUserEmaiil();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout))
        ],
        ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/stickman.png',
              width: 550, // Ajusta el tamaño según necesites
              height: 550,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              currentEmail.toString(),
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    ) ;
  }
}