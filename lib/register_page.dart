import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener esto importado
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
  DateTime? _fechaNacimiento; // Cambiado de edad a fecha de nacimiento
  final _pesoController = TextEditingController();
  String? _sexo;

  String _message = '';
  bool _loading = false;

  Future<void> _pickDateInicio() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(1900),
      lastDate: today,
      locale: const Locale('es', 'ES'), // AÑADE ESTA LÍNEA
    );
    if (date != null) {
      setState(() {
        _fechaInicio = date;
      });
    }
  }

  Future<void> _pickFechaNacimiento() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(today.year - 30, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
      locale: const Locale('es', 'ES'), // AÑADE ESTA LÍNEA
    );
    if (date != null) {
      setState(() {
        _fechaNacimiento = date;
      });
    }
  }

  // Calcular edad a partir de fecha de nacimiento
  int _calcularEdad() {
    if (_fechaNacimiento == null) return 0;
    final today = DateTime.now();
    int edad = today.year - _fechaNacimiento!.year;
    if (today.month < _fechaNacimiento!.month ||
        (today.month == _fechaNacimiento!.month &&
            today.day < _fechaNacimiento!.day)) {
      edad--;
    }
    return edad;
  }

  Future<void> _register() async {
    setState(() {
      _message = '';
      _loading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final peso = _pesoController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        _fechaInicio == null ||
        _fechaNacimiento == null ||
        peso.isEmpty ||
        _sexo == null) {
      setState(() {
        _message = 'Por favor, complete todos los campos';
        _loading = false;
      });
      return;
    }

    final pesoDouble = double.tryParse(peso);
    if (pesoDouble == null) {
      setState(() {
        _message = 'Por favor, ingrese un peso válido';
        _loading = false;
      });
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final hoy = DateTime.now();

      // Crear historial de peso
      List<Map<String, dynamic>> historial = [];

      // 1. Registrar el peso de HOY (fecha de registro)
      historial.add({'fecha': hoy, 'peso': pesoDouble});

      // 2. Si la fecha de inicio es diferente a hoy,
      //    crear un registro para esa fecha con el mismo peso (EDITABLE después)
      if (_fechaInicio!.year != hoy.year ||
          _fechaInicio!.month != hoy.month ||
          _fechaInicio!.day != hoy.day) {
        historial.add({
          'fecha': _fechaInicio,
          'peso':
              pesoDouble, // Mismo peso como placeholder, el usuario lo editará después
        });
      }

      // Ordenar historial por fecha (más antiguo primero)
      historial.sort((a, b) {
        final fechaA = a['fecha'] as DateTime;
        final fechaB = b['fecha'] as DateTime;
        return fechaA.compareTo(fechaB);
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': email,
            'fecha_inicio': _fechaInicio,
            'fecha_nacimiento': _fechaNacimiento,
            'edad': _calcularEdad(),
            'sexo': _sexo,
            'peso_inicial': pesoDouble, // Peso actual como referencia
            'historial_peso': historial,
          });

      // Mostrar mensaje informativo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _fechaInicio!.isBefore(hoy)
                  ? 'Registro completado. Recuerda editar el peso del ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} en la sección de evolución.'
                  : 'Registro completado correctamente.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

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
      appBar: AppBar(
        title: const Text('Registrarse'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo o título
              Image.asset('assets/logo.png', width: 200, height: 200),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              const Text(
                'Comienza tu viaje',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Campo de email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Campo de contraseña
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 15),

              // Selector de fecha de inicio
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.calendar_today,
                    color: Colors.green,
                  ),
                  title: Text(
                    _fechaInicio == null
                        ? '¿Cuándo dejaste de beber?'
                        : 'Dejaste de beber: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)}',
                  ),
                  trailing: TextButton(
                    onPressed: _pickDateInicio,
                    child: const Text('Seleccionar'),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // NUEVO: Selector de fecha de nacimiento (reemplaza a la edad)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.cake, color: Colors.orange),
                  title: Text(
                    _fechaNacimiento == null
                        ? 'Fecha de nacimiento'
                        : 'Naciste: ${DateFormat('dd/MM/yyyy').format(_fechaNacimiento!)} (${_calcularEdad()} años)',
                  ),
                  trailing: TextButton(
                    onPressed: _pickFechaNacimiento,
                    child: const Text('Seleccionar'),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Campo de peso
              TextField(
                controller: _pesoController,
                decoration: InputDecoration(
                  labelText: 'Peso actual (kg)',
                  hintText: 'Ej: 70.5',
                  prefixIcon: const Icon(Icons.monitor_weight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 15),

              // Selector de sexo
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
                decoration: InputDecoration(
                  labelText: 'Sexo',
                  prefixIcon: const Icon(Icons.wc),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Mensaje de error
              if (_message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _message,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 15),

              // Botón de registro
              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),

              // Al final del build method, después del botón de registro
              const SizedBox(height: 15),

              // Enlace a login
              TextButton(
                onPressed: () {
                  // Usar pushReplacementNamed con la ruta definida
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('¿Ya tienes cuenta? Inicia sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
