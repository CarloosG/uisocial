import 'package:flutter/material.dart';
import 'package:uisocial/auth/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _interestsController = TextEditingController();
  final _ageController = TextEditingController();

  String? _selectedCareer;
  final List<String> _careers = [
    "Ingeniería de Sistemas", "Ingeniería Civil", "Ingeniería de Petróleos",
    "Ingeniería Industrial", "Ingeniería Química", "Ingeniería Mecánica",
    "Ingeniería Metalúrgica", "Ingeniería Eléctrica", "Ingeniería Electrónica",
    "Música", "Derecho", "Trabajo Social", "Historia", "Filosofía",
    "Economía", "Química", "Física", "Matemáticas", "Biología"
  ];

  void signUp() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final phone = _phoneController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final interests = _interestsController.text;
    final age = _ageController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }
    
    try {
      await authService.signUpWithEmailPassword(email, password);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrarse")),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 50),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Nombre"),
          ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Correo Electrónico"),
          ),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: "Número de Celular"),
            keyboardType: TextInputType.phone,
          ),
          TextField(
            controller: _ageController,
            decoration: const InputDecoration(labelText: "Edad"),
            keyboardType: TextInputType.number,
          ),
          DropdownButtonFormField<String>(
            value: _selectedCareer,
            decoration: const InputDecoration(labelText: "Carrera"),
            items: _careers.map((career) {
              return DropdownMenuItem(
                value: career,
                child: Text(career),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCareer = value;
              });
            },
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: "Contraseña"),
            obscureText: true,
          ),
          TextField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(labelText: "Confirmar Contraseña"),
            obscureText: true,
          ),
          TextField(
            controller: _interestsController,
            decoration: const InputDecoration(labelText: "Intereses"),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: signUp, child: const Text("Registrarse")),
        ],
      ),
    );
  }
}
