import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 150, height: 150),
            const SizedBox(height: 40),
            ElevatedButton(
              child: const Text('Iniciar sesión'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Registrarse'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
