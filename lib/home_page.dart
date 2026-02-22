import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _diasSinBeber;
  bool _loading = true;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _email = user.email ?? '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final Timestamp? fechaInicioTs = data['fecha_inicio'];
        if (fechaInicioTs != null) {
          final fechaInicio = fechaInicioTs.toDate();
          final now = DateTime.now();
          final dias = now.difference(fechaInicio).inDays;
          setState(() {
            _diasSinBeber = dias;
          });
        }
      }
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Un día sin beber'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _diasSinBeber != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Días sin beber', style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 20),
                  Text(
                    '$_diasSinBeber',
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Correo: $_email', style: const TextStyle(fontSize: 16)),
                ],
              )
            : const Text('No hay fecha de inicio registrada'),
      ),
    );
  }
}
