import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

bool _vistaTotal = false; // false = vista mensual, true = vista total

class PesoPage extends StatefulWidget {
  const PesoPage({super.key});

  @override
  State<PesoPage> createState() => _PesoPageState();
}

class _PesoPageState extends State<PesoPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? _fechaInicio;
  DateTime _mesSeleccionado = DateTime.now();
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
          _mesSeleccionado = DateTime.now();

          _historialPeso = List<Map<String, dynamic>>.from(
            data['historial_peso'] ?? [],
          );

          _historialPeso.sort((a, b) {
            final fechaA = (a['fecha'] as Timestamp).toDate();
            final fechaB = (b['fecha'] as Timestamp).toDate();
            return fechaA.compareTo(fechaB);
          });

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

  void _mesAnterior() {
    setState(() {
      _mesSeleccionado = DateTime(
        _mesSeleccionado.year,
        _mesSeleccionado.month - 1,
        1,
      );
    });
  }

  void _mesSiguiente() {
    final hoy = DateTime.now();
    final nuevoMes = DateTime(
      _mesSeleccionado.year,
      _mesSeleccionado.month + 1,
      1,
    );

    if (nuevoMes.isBefore(DateTime(hoy.year, hoy.month + 1, 1))) {
      setState(() {
        _mesSeleccionado = nuevoMes;
      });
    }
  }

  List<DateTime> _generarDiasDelMes() {
    if (_fechaInicio == null) return [];

    final primerDiaMes = DateTime(
      _mesSeleccionado.year,
      _mesSeleccionado.month,
      1,
    );
    final ultimoDiaMes = DateTime(
      _mesSeleccionado.year,
      _mesSeleccionado.month + 1,
      0,
    );

    final hoy = DateTime.now();
    final dias = <DateTime>[];

    for (var i = 0; i < ultimoDiaMes.day; i++) {
      final fecha = DateTime(
        _mesSeleccionado.year,
        _mesSeleccionado.month,
        i + 1,
      );

      if (fecha.isAfter(_fechaInicio!.subtract(const Duration(days: 1))) &&
          fecha.isBefore(hoy.add(const Duration(days: 1)))) {
        dias.add(fecha);
      }
    }

    return dias;
  }

  bool _mesTieneDias() {
    return _generarDiasDelMes().isNotEmpty;
  }

  List<Map<String, dynamic>> _getHistorialDelMes() {
    final diasDelMes = _generarDiasDelMes();
    final historialMes = <Map<String, dynamic>>[];

    for (var fecha in diasDelMes) {
      final fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
      final peso = _pesosPorFecha[fechaStr];
      if (peso != null) {
        historialMes.add({'fecha': Timestamp.fromDate(fecha), 'peso': peso});
      }
    }

    return historialMes;
  }

  bool _esFechaInicioSinEditar(DateTime fecha) {
    if (_fechaInicio == null) return false;

    final fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
    final fechaInicioStr = DateFormat('yyyy-MM-dd').format(_fechaInicio!);

    if (fechaStr == fechaInicioStr) {
      final pesoEnFecha = _pesosPorFecha[fechaStr];

      if (_historialPeso.isNotEmpty && pesoEnFecha != null) {
        final pesoHoy = _historialPeso.last['peso'].toDouble();
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
                // Solo > 0, no permite 0
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

      final indexExistente = _historialPeso.indexWhere((registro) {
        final regFecha = (registro['fecha'] as Timestamp).toDate();
        return DateFormat('yyyy-MM-dd').format(regFecha) == fechaStr;
      });

      if (indexExistente >= 0) {
        _historialPeso[indexExistente]['peso'] = nuevoPeso;
      } else {
        _historialPeso.add({
          'fecha': Timestamp.fromDate(fecha),
          'peso': nuevoPeso,
        });
      }

      _historialPeso.sort((a, b) {
        final fechaA = (a['fecha'] as Timestamp).toDate();
        final fechaB = (b['fecha'] as Timestamp).toDate();
        return fechaA.compareTo(fechaB);
      });

      await _firestore.collection('users').doc(user.uid).update({
        'historial_peso': _historialPeso,
      });

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

  Future<void> _eliminarPeso(DateTime fecha) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text(
          '¿Eliminar el peso del ${DateFormat('dd/MM/yyyy').format(fecha)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _borrarPeso(fecha);
    }
  }

  Future<void> _borrarPeso(DateTime fecha) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final fechaStr = DateFormat('yyyy-MM-dd').format(fecha);

      _historialPeso.removeWhere((registro) {
        final regFecha = (registro['fecha'] as Timestamp).toDate();
        return DateFormat('yyyy-MM-dd').format(regFecha) == fechaStr;
      });

      await _firestore.collection('users').doc(user.uid).update({
        'historial_peso': _historialPeso,
      });

      setState(() {
        _pesosPorFecha.remove(fechaStr);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro eliminado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error al eliminar: $e');
    }
  }

  Color _getColorForChange(double pesoAnterior, double pesoActual) {
    if (pesoAnterior == 0) return Colors.grey;
    final diferencia = pesoActual - pesoAnterior;
    if (diferencia < 0) return Colors.green;
    if (diferencia > 0) return Colors.red;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolución del Peso'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: _buildMonthNavigator(),
        actions: [
          // Botón para cambiar entre vista mensual y total
          IconButton(
            icon: Icon(_vistaTotal ? Icons.calendar_month : Icons.show_chart),
            onPressed: () {
              setState(() {
                _vistaTotal = !_vistaTotal;
              });
            },
            tooltip: _vistaTotal ? 'Ver por meses' : 'Ver evolución total',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _fechaInicio == null
          ? const Center(child: Text('No hay datos disponibles'))
          : _vistaTotal
          ? _buildVistaTotal() // Nueva función para vista total
          : Column(
              children: [
                _buildResumenMensual(),

                if (_getHistorialDelMes().length >= 2)
                  Container(
                    height: 180,
                    padding: const EdgeInsets.only(
                      left: 30,
                      right: 30,
                      top: 10,
                      bottom: 10,
                    ),
                    child: CustomPaint(
                      painter: PesoGraphPainter(
                        historial: _getHistorialDelMes(),
                      ),
                      size: const Size(double.infinity, 180),
                    ),
                  ),

                if (_getHistorialDelMes().length >= 2)
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

                Expanded(
                  child: _mesTieneDias()
                      ? _buildListaDias()
                      : _buildMensajeSinDias(),
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildMonthNavigator() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        color: Colors.teal.shade800,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: _mesAnterior,
            ),
            Text(
              DateFormat('MMMM yyyy').format(_mesSeleccionado),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: _mesSiguiente,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVistaTotal() {
    // Obtener todo el historial desde el inicio
    final historialCompleto = _historialPeso;

    if (historialCompleto.isEmpty) {
      return const Center(child: Text('No hay datos de peso registrados'));
    }

    final pesoInicial = historialCompleto.first['peso'].toDouble();
    final pesoActual = historialCompleto.last['peso'].toDouble();
    final diferencia = pesoActual - pesoInicial;
    final colorDiferencia = diferencia > 0 ? Colors.red : Colors.green;
    final diasTranscurridos = DateTime.now().difference(_fechaInicio!).inDays;

    return Column(
      children: [
        // Resumen total
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.teal.shade700],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'Evolución Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTotalInfo(
                    'Inicio',
                    '${pesoInicial.toStringAsFixed(1)} kg',
                    Icons.flag,
                  ),
                  _buildTotalInfo(
                    'Actual',
                    '${pesoActual.toStringAsFixed(1)} kg',
                    Icons.trending_up,
                  ),
                  _buildTotalInfo(
                    'Cambio',
                    '${diferencia.toStringAsFixed(1)} kg',
                    diferencia > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: colorDiferencia,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${diasTranscurridos} días de evolución',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        // Gráfico total
        if (historialCompleto.length >= 2)
          Container(
            height: 250,
            padding: const EdgeInsets.only(
              left: 30,
              right: 30,
              top: 20,
              bottom: 10,
            ),
            child: CustomPaint(
              painter: PesoGraphPainter(historial: historialCompleto),
              size: const Size(double.infinity, 250),
            ),
          ),

        // Leyenda
        if (historialCompleto.length >= 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

        // Estadísticas adicionales
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildEstadisticaCard(
                'Promedio de peso',
                _calcularPromedio(),
                Icons.calculate,
              ),
              _buildEstadisticaCard(
                'Peso máximo',
                _calcularMaximo(),
                Icons.trending_up,
                Colors.orange,
              ),
              _buildEstadisticaCard(
                'Peso mínimo',
                _calcularMinimo(),
                Icons.trending_down,
                Colors.green,
              ),
              _buildEstadisticaCard(
                'Registros',
                '${historialCompleto.length} días',
                Icons.calendar_today,
                Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Funciones auxiliares para la vista total
  Widget _buildTotalInfo(
    String label,
    String valor,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticaCard(
    String label,
    String valor,
    IconData icon, [
    Color color = Colors.teal,
  ]) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  String _calcularPromedio() {
    if (_historialPeso.isEmpty) return 'N/A';
    double suma = 0;
    for (var registro in _historialPeso) {
      suma += registro['peso'].toDouble();
    }
    return '${(suma / _historialPeso.length).toStringAsFixed(1)} kg';
  }

  String _calcularMaximo() {
    if (_historialPeso.isEmpty) return 'N/A';
    double maximo = 0;
    for (var registro in _historialPeso) {
      maximo = maximo > registro['peso'] ? maximo : registro['peso'].toDouble();
    }
    return '${maximo.toStringAsFixed(1)} kg';
  }

  String _calcularMinimo() {
    if (_historialPeso.isEmpty) return 'N/A';
    double minimo = double.infinity;
    for (var registro in _historialPeso) {
      minimo = minimo < registro['peso'] ? minimo : registro['peso'].toDouble();
    }
    return '${minimo.toStringAsFixed(1)} kg';
  }

  Widget _buildResumenMensual() {
    final diasDelMes = _generarDiasDelMes();
    if (diasDelMes.isEmpty) return const SizedBox();

    final pesosDelMes = diasDelMes
        .map((f) => _pesosPorFecha[DateFormat('yyyy-MM-dd').format(f)])
        .where((p) => p != null)
        .toList();

    if (pesosDelMes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'No hay registros de peso este mes',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    final primerPeso = pesosDelMes.first!;
    final ultimoPeso = pesosDelMes.last!;
    final diferencia = ultimoPeso - primerPeso;
    final colorDiferencia = diferencia > 0 ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniResumen(
            'Inicio mes',
            '${primerPeso.toStringAsFixed(1)} kg',
          ),
          _buildMiniResumen('Final mes', '${ultimoPeso.toStringAsFixed(1)} kg'),
          _buildMiniResumen(
            'Cambio',
            '${diferencia.toStringAsFixed(1)} kg',
            color: colorDiferencia,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniResumen(String label, String valor, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
      ],
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

  Widget _buildListaDias() {
    final dias = _generarDiasDelMes();

    return ListView.builder(
      itemCount: dias.length,
      itemBuilder: (context, index) {
        final fecha = dias[index];
        final fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
        final peso = _pesosPorFecha[fechaStr];

        double pesoAnterior = 0;
        if (index > 0) {
          final fechaAnterior = dias[index - 1];
          final fechaAnteriorStr = DateFormat(
            'yyyy-MM-dd',
          ).format(fechaAnterior);
          pesoAnterior = _pesosPorFecha[fechaAnteriorStr] ?? 0;
        }

        final colorCambio = peso != null && pesoAnterior > 0
            ? _getColorForChange(pesoAnterior, peso)
            : Colors.grey;

        final esFechaInicioSinEditar = _esFechaInicioSinEditar(fecha);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    : (peso != null ? Icons.monitor_weight : Icons.pending),
                color: esFechaInicioSinEditar ? Colors.orange : colorCambio,
              ),
            ),
            title: Text(
              DateFormat('EEEE, d').format(fecha),
              style: TextStyle(
                fontWeight: esFechaInicioSinEditar
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: esFechaInicioSinEditar ? Colors.orange.shade800 : null,
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
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (peso != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _eliminarPeso(fecha),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.teal),
                  onPressed: () => _editarPeso(fecha, peso ?? 0),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMensajeSinDias() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No hay días para mostrar en este mes',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          if (_fechaInicio != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'El primer mes disponible es ${DateFormat('MMMM yyyy').format(_fechaInicio!)}',
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
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

    for (var registro in historial) {
      final peso = registro['peso'].toDouble();
      if (peso < minPeso) minPeso = peso;
      if (peso > maxPeso) maxPeso = peso;
    }

    minPeso -= 2;
    maxPeso += 2;

    final anchoDisponible = size.width;
    final altoDisponible = size.height - 20;

    final pasoX = anchoDisponible / (historial.length - 1);

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

    for (int i = 0; i < historial.length; i++) {
      final peso = historial[i]['peso'].toDouble();
      final x = i * pasoX;
      final y =
          10 +
          (altoDisponible -
              ((peso - minPeso) / (maxPeso - minPeso) * altoDisponible));
      puntos.add(Offset(x, y.clamp(10, 10 + altoDisponible)));
    }

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
