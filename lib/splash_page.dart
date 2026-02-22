import 'package:flutter/material.dart';
import 'update_checker.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _updateProcessed = false; // Cambiado de _updateChecked
  bool _canNavigate = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Primero verificar actualizaciones (ESPERAR a que termine)
    await _checkForUpdates();

    // Después de verificar, permitir navegación
    setState(() {
      _updateProcessed = true;
      _canNavigate = true;
    });

    // Navegar al login
    _navigateToLogin();
  }

  Future<void> _checkForUpdates() async {
    // Llamar al checker y ESPERAR a que termine completamente
    await UpdateChecker.checkForUpdates(context);
    print("✅ Proceso de actualización completado");
  }

  _navigateToLogin() async {
    // Pequeña pausa para asegurar que todo está listo
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted && _canNavigate && _updateProcessed) {
      print("🚀 Navegando a login...");
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      print(
        "⏳ Esperando condiciones: canNavigate=$_canNavigate, updateProcessed=$_updateProcessed",
      );
      // Si no se cumplen, esperar un poco más y reintentar
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _navigateToLogin();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade400, Colors.green.shade700],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', width: 100, height: 100),
              const SizedBox(height: 20),
              const Text(
                'Un día sin beber',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
