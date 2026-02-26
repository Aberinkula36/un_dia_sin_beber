import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'peso_page.dart';
import 'l10n/app_localizations.dart';
import 'locale_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _getSexoIcon(String? sexo) {
    switch (sexo) {
      case 'Masculino':
        return '♂️';
      case 'Femenino':
        return '♀️';
      case 'No binario':
        return '⚧';
      default:
        return '❓';
    }
  }

  Color _getSexoColor(String? sexo) {
    switch (sexo) {
      case 'Masculino':
        return Colors.blue;
      case 'Femenino':
        return Colors.pink;
      case 'No binario':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  int _calcularEdad(DateTime fechaNacimiento) {
    final today = DateTime.now();
    int edad = today.year - fechaNacimiento.year;
    if (today.month < fechaNacimiento.month ||
        (today.month == fechaNacimiento.month &&
            today.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }

  Future<String> _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.myProgress),
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              // Selector de idioma
              PopupMenuButton<Locale>(
                icon: const Icon(Icons.language),
                onSelected: (locale) {
                  localeProvider.setLocale(locale);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: const Locale('es'),
                    child: Row(
                      children: [const Text('🇪🇸 '), const Text('Español')],
                    ),
                  ),
                  PopupMenuItem(
                    value: const Locale('en'),
                    child: Row(
                      children: [const Text('🇬🇧 '), const Text('English')],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('${context.l10n.error}: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data?.data() as Map<String, dynamic>?;

              if (data == null) {
                return Center(child: Text(context.l10n.noData));
              }

              final fechaInicio = (data['fecha_inicio'] as Timestamp).toDate();
              final diasSobrio = DateTime.now().difference(fechaInicio).inDays;

              final fechaNacimiento = (data['fecha_nacimiento'] as Timestamp?)
                  ?.toDate();
              final edadActual = fechaNacimiento != null
                  ? _calcularEdad(fechaNacimiento)
                  : (data['edad'] ?? 0);

              final sexo = data['sexo'];

              double pesoActual = data['peso_inicial']?.toDouble() ?? 0;
              double pesoInicial = data['peso_inicial']?.toDouble() ?? 0;

              final historial = List<Map<String, dynamic>>.from(
                data['historial_peso'] ?? [],
              );
              if (historial.isNotEmpty) {
                historial.sort((a, b) {
                  final fechaA = (a['fecha'] as Timestamp).toDate();
                  final fechaB = (b['fecha'] as Timestamp).toDate();
                  return fechaA.compareTo(fechaB);
                });
                pesoActual = historial.last['peso'].toDouble();
                pesoInicial = historial.first['peso'].toDouble();
              }

              final diferenciaPeso = pesoActual - pesoInicial;
              final colorDiferencia = diferenciaPeso > 0
                  ? Colors.red
                  : Colors.green;

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.teal.shade50, Colors.white],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Tarjeta de días sin beber
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.shade400,
                                Colors.teal.shade600,
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.celebration,
                                color: Colors.white,
                                size: 50,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '$diasSobrio',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                diasSobrio == 1
                                    ? context.l10n.dayWithoutDrinking
                                    : context.l10n.daysWithoutDrinking,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tarjeta de información personal
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoTile(
                                      icon: Icons.cake,
                                      label: context.l10n.age,
                                      value:
                                          '$edadActual ${context.l10n.years}',
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoTile(
                                      icon: Icons.wc,
                                      label: context.l10n.gender,
                                      value: '${_getSexoIcon(sexo)} $sexo',
                                      color: _getSexoColor(sexo),
                                    ),
                                  ),
                                ],
                              ),
                              if (fechaNacimiento != null) ...[
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cake_outlined,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${context.l10n.born}: ${DateFormat('dd/MM/yyyy').format(fechaNacimiento)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tarjeta de peso
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoTile(
                                      icon: Icons.monitor_weight,
                                      label: context.l10n.initialWeight,
                                      value:
                                          '${pesoInicial.toStringAsFixed(1)} kg',
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoTile(
                                      icon: Icons.trending_up,
                                      label: context.l10n.currentWeight,
                                      value:
                                          '${pesoActual.toStringAsFixed(1)} kg',
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    diferenciaPeso > 0
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: colorDiferencia,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${diferenciaPeso.abs().toStringAsFixed(1)} kg ${diferenciaPeso > 0 ? context.l10n.gained : context.l10n.lost}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorDiferencia,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botón para ver evolución
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PesoPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.show_chart),
                        label: Text(context.l10n.viewDetailedEvolution),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Fecha de inicio
                      Text(
                        '${context.l10n.since} ${DateFormat('dd/MM/yyyy').format(fechaInicio)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Número de versión
                      FutureBuilder<String>(
                        future: _getVersion(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              '${context.l10n.records} ${snapshot.data}', // Usamos "records" como "versión"
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
