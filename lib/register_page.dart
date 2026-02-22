import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _fechaInicio;
  final _edadController = TextEditingController();
  String? _sexo;

  String _message = '';
  bool _loading = false;

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (date != null) {
      setState(() {
        _fechaInicio = date;
      });
    }
  }

  Future<void> _register() async {
    setState(() {
      _message = '';
      _loading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final edad = _edadController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        _fechaInicio == null ||
        edad.isEmpty ||
        _sexo == null) {
      setState(() {
        _message = 'Por favor, complete todos los campos';
        _loading = false;
      });
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Guardar datos adicionales en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': email,
            'fecha_inicio': _fechaInicio,
            'edad': int.tryParse(edad),
            'sexo': _sexo,
          });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = 'Error: ${e.message}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  final List<String> _sexos = [
    'Masculino',
    'Femenino',
    'No binario',
    'Prefiero no decirlo',
    'Otro',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrarse')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _fechaInicio == null
                          ? 'Fecha de inicio'
                          : 'Fecha: ${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}',
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Seleccionar'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _edadController,
                decoration: const InputDecoration(labelText: 'Edad'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _sexo,
                items: _sexos
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _sexo = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Sexo'),
              ),
              const SizedBox(height: 20),
              if (_message.isNotEmpty)
                Text(_message, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      child: const Text('Registrarse'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
