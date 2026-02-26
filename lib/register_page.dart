import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'l10n/app_localizations.dart';
import 'locale_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaNacimiento;
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
      locale: const Locale('es', 'ES'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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
      locale: const Locale('es', 'ES'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _fechaNacimiento = date;
      });
    }
  }

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
        _message = context.l10n.fillCredentials;
        _loading = false;
      });
      return;
    }

    final pesoDouble = double.tryParse(peso);
    if (pesoDouble == null) {
      setState(() {
        _message =
            '${context.l10n.invalidEmail}'; // Usamos invalidEmail como "peso inválido"
        _loading = false;
      });
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final hoy = DateTime.now();
      List<Map<String, dynamic>> historial = [];

      historial.add({'fecha': hoy, 'peso': pesoDouble});

      if (_fechaInicio!.year != hoy.year ||
          _fechaInicio!.month != hoy.month ||
          _fechaInicio!.day != hoy.day) {
        historial.add({'fecha': _fechaInicio, 'peso': pesoDouble});
      }

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
            'peso_inicial': pesoDouble,
            'historial_peso': historial,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _fechaInicio!.isBefore(hoy)
                  ? context
                        .l10n
                        .firstMonthAvailable // Usamos esto como mensaje
                  : context.l10n.save,
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = '${context.l10n.error}: ${e.message}';
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
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.register),
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.health_and_safety,
                    size: 80,
                    color: Colors.teal.shade700,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.createAccount,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.startYourJourney,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: context.l10n.email,
                      prefixIcon: const Icon(Icons.email, color: Colors.teal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: context.l10n.password,
                      prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 15),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.teal,
                      ),
                      title: Text(
                        _fechaInicio == null
                            ? context.l10n.startDate
                            : '${context.l10n.startDate}: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)}',
                      ),
                      trailing: TextButton(
                        onPressed: _pickDateInicio,
                        child: Text(context.l10n.selectDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.cake, color: Colors.orange),
                      title: Text(
                        _fechaNacimiento == null
                            ? context.l10n.birthDate
                            : '${context.l10n.birthDate}: ${DateFormat('dd/MM/yyyy').format(_fechaNacimiento!)} (${_calcularEdad()} ${context.l10n.years})',
                      ),
                      trailing: TextButton(
                        onPressed: _pickFechaNacimiento,
                        child: Text(context.l10n.selectDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _pesoController,
                    decoration: InputDecoration(
                      labelText: context.l10n.weight,
                      hintText: context.l10n.weightHint,
                      prefixIcon: const Icon(
                        Icons.monitor_weight,
                        color: Colors.teal,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 15),

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
                      labelText: context.l10n.gender,
                      prefixIcon: const Icon(Icons.wc, color: Colors.teal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

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

                  _loading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              context.l10n.registerButton,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.alreadyHaveAccount,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          context.l10n.loginLink,
                          style: TextStyle(
                            color: Colors.teal.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
