import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_home.dart';
import 'user_home.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isAdmin = false; // Toggle admin flag

  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      final supabase = Supabase.instance.client;

      // Sign up user
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        // Set admin flag in metadata
        await supabase.auth.updateUser(UserAttributes(
          data: {'is_admin': isAdmin},
        ));

        // Navigate to appropriate home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => isAdmin ? AdminHomePage() : UserHomePage(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Register")),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(
          controller: emailController,
          decoration: InputDecoration(labelText: "Email"),
        ),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(labelText: "Password"),
        ),
        Row(
          children: [
            Checkbox(
              value: isAdmin,
              onChanged: (value) => setState(() => isAdmin = value!),
            ),
            Text("Register as admin"),
          ],
        ),
        ElevatedButton(onPressed: register, child: Text("Register")),
      ]),
    ),
  );
}
