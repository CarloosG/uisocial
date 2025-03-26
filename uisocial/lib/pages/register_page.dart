import 'package:flutter/material.dart';
import 'package:uisocial/auth/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}
class _RegisterPageState extends State<RegisterPage> {
  final authService = AuthService();


  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  void signUp() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Las contraseñas no coinciden")));
      return;
    }
    try{
      await authService.signUpWithEmailPassword(email, password);
      Navigator.pop(context);

    } catch(e){
      if (mounted){
         ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text("error: $e")));
         return;   
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrarse"),),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 50),
        children: [
          TextField(
            controller: _emailController,
            decoration:  const InputDecoration(labelText: "Email") ,
          ),
          TextField(
            controller: _passwordController,
            decoration:  const InputDecoration(labelText: "Contraseña") ,

          ),
          TextField(
            controller: _confirmPasswordController,
            decoration:  const InputDecoration(labelText: "Confirma la contraseña") ,

          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: signUp, child: const Text("Registrarse")),
        

        ],

      ),
    );
  }
}