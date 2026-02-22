import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class PesoPage extends StatefulWidget {
  const PesoPage({super.key});

  @override
  State<PesoPage> createState() => _PesoPageState();
}

class _PesoPageState extends State<PesoPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? _fechaInicio;
  List<Map<String, dynamic>> _historialPeso = [];
  Map<String, double> _pesosPorFecha = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _fechaInicio = (data['fecha_inicio'] as Timestamp).toDate();
          _historialPeso = List<Map<String, dynamic>>.from(
            data['historial_peso'] ?? [],
          );

          // Ordenar por fecha
          _historialPeso.sort((a, b) {
            final fechaA = (a['fecha'] as Timestamp).toDate();
            final fechaB = (b['fecha'] as Timestamp).toDate();
            return fechaA.compareTo(fechaB);
          });

          // Crear un mapa de fecha a peso para fácil acceso
          _pesosPorFecha = {};
          for (var registro in _historialPeso) {
            final fecha = (registro['fecha'] as Timestamp).toDate();
            final fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
            _pesosPorFecha[fechaStr] = registro['peso'].toDouble();
          }
        });
      }
    } catch (e) {
      print('Error cargando datos: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Detectar si es la fecha de inicio y el peso es placeholder
  bool _esFechaInicioSinEditar(DateTime fecha) {
    if (_fechaInicio == null) return false;

    final fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
    final fechaInicioStr = DateFormat('yyyy-MM-dd').format(_fechaInicio!);

    // Si es la fecha de inicio y solo hay un registro (el de hoy) o el peso es el mismo que el de hoy
    if (fechaStr == fechaInicioStr) {
      // Buscar si hay un registro específico para esta fecha
      final pesoEnFecha = _pesosPorFecha[fechaStr];

      // Si hay un registro y es diferente al peso de hoy (suponiendo que el de hoy es el último)
      if (_historialPeso.isNotEmpty && pesoEnFecha != null) {
        final pesoHoy = _historialPeso.last['peso'].toDouble();
        // Si el peso de la fecha de inicio es igual al de hoy, podría ser placeholder
        return (pesoEnFecha == pesoHoy && _historialPeso.length > 1);
      }
    }

    return false;
  }

  Future<void> _editarPeso(DateTime fecha, double pesoActual) async {
    final TextEditingController controller = TextEditingController(
      text: pesoActual > 0 ? pesoActual.toStringAsFixed(1) : '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar peso - ${DateFormat('dd/MM/yyyy').format(fecha)}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Peso (kg)',
            hintText: 'Ej: 70.5',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final nuevoPeso = double.tryParse(controller.text);
              if (nuevoPeso != null && nuevoPeso > 0) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final nuevoPeso = double.parse(controller.text);
      await _guardarPeso(fecha, nuevoPeso);
    }
  }

  Future<void> _guardarPeso(DateTime fecha, double nuevoPeso) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final fechaStr = DateFormat('yyyy-MM-dd').format(fecha);

      // Buscar si ya existe un registro para esta fecha
      final indexExistente = _historialPeso.indexWhere((registro) {
        final regFecha = (registro['fecha'] as Timestamp).toDate();
        return DateFormat('yyyy-MM-dd').format(regFecha) == fechaStr;
      });

      if (indexExistente >= 0) {
        // Actualizar registro existente
        _historialPeso[indexExistente]['peso'] = nuevoPeso;
      } else {
        // Agregar nuevo registro
        _historialPeso.add({
          'fecha': Timestamp.fromDate(fecha),
          'peso': nuevoPeso,
        });
      }

      // Ordenar por fecha
      _historialPeso.sort((a, b) {
        final fechaA = (a['fecha'] as Timestamp).toDate();
        final fechaB = (b['fecha'] as Timestamp).toDate();
        return fechaA.compareTo(fechaB);
      });

      // Actualizar en Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'historial_peso': _historialPeso,
      });

      // Actualizar estado local
      setState(() {
        _pesosPorFecha[fechaStr] = nuevoPeso;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Peso actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<DateTime> _generarDias() {
    if (_fechaInicio == null) return [];

    final hoy = DateTime.now();
    final dias = <DateTime>[];

    for (var i = 0; i <= hoy.difference(_fechaInicio!).inDays; i++) {
      dias.add(_fechaInicio!.add(Duration(days: i)));
    }

    return dias;
  }

  Color _getColorForChange(double pesoAnterior, double pesoActual) {
    if (pesoAnterior == 0) return Colors.grey;
    final diferencia = pesoActual - pesoAnterior;
    if (diferencia < 0) return Colors.green; // Bajó de peso (mejor)
    if (diferencia > 0) return Colors.red; // Subió de peso
    return Colors.blue; // Se mantuvo
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolución del Peso'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _fechaInicio == null
          ? const Center(child: Text('No hay datos disponibles'))
          : Column(
              children: [
                // Resumen con diseño mejorado
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResumenCard(
                            'Inicio',
                            _historialPeso.isNotEmpty
                                ? '${_historialPeso.first['peso'].toStringAsFixed(1)} kg'
                                : 'N/A',
                            Icons.flag,
                            Colors.orange,
                          ),
                          _buildResumenCard(
                            'Actual',
                            _historialPeso.isNotEmpty
                                ? '${_historialPeso.last['peso'].toStringAsFixed(1)} kg'
                                : 'N/A',
                            Icons.trending_up,
                            Colors.teal,
                          ),
                        ],
                      ),
                      if (_historialPeso.length >= 2) ...[
                        const SizedBox(height: 10),
                        _buildCambioCard(),
                      ],
                    ],
                  ),
                ),

                // Gráfico de evolución
                if (_historialPeso.length >= 2)
                  Container(
                    height: 220,
                    padding: const EdgeInsets.only(
                      left: 30,
                      right: 30,
                      top: 20,
                      bottom: 10,
                    ),
                    child: CustomPaint(
                      painter: PesoGraphPainter(historial: _historialPeso),
                      size: const Size(double.infinity, 220),
                    ),
                  ),

                // Leyenda del gráfico
                if (_historialPeso.length >= 2)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLeyendaItem('Mejoró', Colors.green),
                        const SizedBox(width: 20),
                        _buildLeyendaItem('Empeoró', Colors.red),
                        const SizedBox(width: 20),
                        _buildLeyendaItem('Estable', Colors.blue),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                // AQUÍ ESTÁ EL ListView.builder
                Expanded(
                  child: ListView.builder(
                    itemCount: _generarDias().length,
                    itemBuilder: (context, index) {
                      final fecha = _generarDias()[index];
                      final fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
                      final peso = _pesosPorFecha[fechaStr];

                      // Encontrar el peso anterior para determinar el color
                      double pesoAnterior = 0;
                      if (index > 0) {
                        final fechaAnterior = _generarDias()[index - 1];
                        final fechaAnteriorStr = DateFormat(
                          'yyyy-MM-dd',
                        ).format(fechaAnterior);
                        pesoAnterior = _pesosPorFecha[fechaAnteriorStr] ?? 0;
                      }

                      final colorCambio = peso != null && pesoAnterior > 0
                          ? _getColorForChange(pesoAnterior, peso)
                          : Colors.grey;

                      final esFechaInicioSinEditar = _esFechaInicioSinEditar(
                        fecha,
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: esFechaInicioSinEditar
                                ? Colors.orange.withOpacity(0.2)
                                : colorCambio.withOpacity(0.2),
                            child: Icon(
                              esFechaInicioSinEditar
                                  ? Icons.warning_amber_rounded
                                  : (peso != null
                                        ? Icons.monitor_weight
                                        : Icons.pending),
                              color: esFechaInicioSinEditar
                                  ? Colors.orange
                                  : colorCambio,
                            ),
                          ),
                          title: Text(
                            DateFormat('EEEE, d MMMM yyyy').format(fecha),
                            style: TextStyle(
                              fontWeight: esFechaInicioSinEditar
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: esFechaInicioSinEditar
                                  ? Colors.orange.shade800
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            peso != null
                                ? '${peso.toStringAsFixed(1)} kg'
                                : 'Pendiente de registrar',
                            style: TextStyle(
                              color: esFechaInicioSinEditar
                                  ? Colors.orange.shade600
                                  : (peso != null ? Colors.black : Colors.grey),
                              fontWeight: esFechaInicioSinEditar
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.teal),
                            onPressed: () => _editarPeso(fecha, peso ?? 0),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildResumenCard(
    String label,
    String valor,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCambioCard() {
    final inicial = _historialPeso.first['peso'].toDouble();
    final actual = _historialPeso.last['peso'].toDouble();
    final diferencia = actual - inicial;
    final esMejora = diferencia < 0;
    final color = esMejora
        ? Colors.green
        : (diferencia > 0 ? Colors.red : Colors.blue);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esMejora
                ? Icons.arrow_downward
                : (diferencia > 0 ? Icons.arrow_upward : Icons.remove),
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            '${diferencia.abs().toStringAsFixed(1)} kg ${esMejora ? 'bajados' : (diferencia > 0 ? 'subidos' : 'sin cambios')}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeyendaItem(String texto, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

// Custom painter para el gráfico de evolución
class PesoGraphPainter extends CustomPainter {
  final List<Map<String, dynamic>> historial;

  PesoGraphPainter({required this.historial});

  @override
  void paint(Canvas canvas, Size size) {
    if (historial.length < 2) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final pointPaint = Paint()..style = PaintingStyle.fill;

    final puntos = <Offset>[];
    double minPeso = double.infinity;
    double maxPeso = 0;

    // Encontrar min y max para escalar
    for (var registro in historial) {
      final peso = registro['peso'].toDouble();
      if (peso < minPeso) minPeso = peso;
      if (peso > maxPeso) maxPeso = peso;
    }

    // Añadir margen
    minPeso -= 2;
    maxPeso += 2;

    // El tamaño disponible para dibujar (restando el padding)
    final anchoDisponible = size.width;
    final altoDisponible = size.height - 20;

    final pasoX = anchoDisponible / (historial.length - 1);

    // Dibujar líneas de fondo
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = 10 + (altoDisponible * (i / 4));
      canvas.drawLine(
        Offset(0, y),
        Offset(anchoDisponible, y),
        backgroundPaint,
      );
    }

    // Calcular puntos
    for (int i = 0; i < historial.length; i++) {
      final peso = historial[i]['peso'].toDouble();
      final x = i * pasoX;
      final y =
          10 +
          (altoDisponible -
              ((peso - minPeso) / (maxPeso - minPeso) * altoDisponible));
      puntos.add(Offset(x, y.clamp(10, 10 + altoDisponible)));
    }

    // Dibujar líneas entre puntos con colores según la tendencia
    for (int i = 0; i < puntos.length - 1; i++) {
      final pesoActual = historial[i]['peso'].toDouble();
      final pesoSiguiente = historial[i + 1]['peso'].toDouble();

      if (pesoSiguiente < pesoActual) {
        paint.color = Colors.green;
      } else if (pesoSiguiente > pesoActual) {
        paint.color = Colors.red;
      } else {
        paint.color = Colors.blue;
      }

      canvas.drawLine(puntos[i], puntos[i + 1], paint);
    }

    // Dibujar puntos
    for (int i = 0; i < puntos.length; i++) {
      final peso = historial[i]['peso'].toDouble();

      if (i > 0) {
        final pesoAnterior = historial[i - 1]['peso'].toDouble();
        if (peso < pesoAnterior) {
          pointPaint.color = Colors.green;
        } else if (peso > pesoAnterior) {
          pointPaint.color = Colors.red;
        } else {
          pointPaint.color = Colors.blue;
        }
      } else {
        pointPaint.color = Colors.grey;
      }

      canvas.drawCircle(puntos[i], 6, pointPaint);

      pointPaint.color = Colors.white;
      pointPaint.style = PaintingStyle.stroke;
      canvas.drawCircle(puntos[i], 6, pointPaint);
      pointPaint.style = PaintingStyle.fill;

      // Mostrar valores
      final textSpan = TextSpan(
        text: '${peso.toStringAsFixed(1)}',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white70,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();

      double dx = puntos[i].dx - textPainter.width / 2;
      if (dx < 2) dx = 2;
      if (dx + textPainter.width > anchoDisponible - 2) {
        dx = anchoDisponible - textPainter.width - 2;
      }

      final offset = Offset(dx, puntos[i].dy - 20);

      final backgroundRect = Rect.fromLTWH(
        offset.dx - 2,
        offset.dy - 2,
        textPainter.width + 4,
        textPainter.height + 4,
      );
      canvas.drawRect(
        backgroundRect,
        Paint()..color = Colors.white.withOpacity(0.7),
      );

      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
