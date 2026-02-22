import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static const String versionUrl =
      'https://raw.githubusercontent.com/Aberinkula36/un_dia_sin_beber/master/version.json';

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      print("🔍 Verificando actualizaciones...");

      // Obtener versión actual
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      print("📱 Versión actual: $currentVersion");

      // Obtener información de versión desde GitHub
      print("🌐 Consultando: $versionUrl");
      final response = await http.get(Uri.parse(versionUrl));

      if (response.statusCode == 200) {
        print("✅ Respuesta de GitHub: ${response.body}");
        final data = json.decode(response.body);
        String latestVersion = data['version'];
        String apkUrl = data['apk_url'];
        String notes = data['release_notes'] ?? 'Mejoras y correcciones';
        bool mandatory = data['mandatory'] ?? false;

        print("📊 Última versión en GitHub: $latestVersion");
        print("📱 Versión actual: $currentVersion");

        if (_isNewerVersion(latestVersion, currentVersion)) {
          print("🔄 ¡Hay actualización disponible!");
          _showUpdateDialog(context, latestVersion, apkUrl, notes, mandatory);
        } else {
          print("✅ No hay actualizaciones disponibles");
        }
      } else {
        print("❌ Error al consultar GitHub: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error en checkForUpdates: $e");
    }
  }

  static bool _isNewerVersion(String latest, String current) {
    try {
      List<int> latestParts = latest.split('.').map(int.parse).toList();
      List<int> currentParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
    } catch (e) {
      print("Error comparando versiones: $e");
    }
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context,
    String version,
    String apkUrl,
    String notes,
    bool mandatory,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !mandatory,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            mandatory
                ? 'Actualización requerida'
                : '¡Nueva versión disponible!',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Versión $version disponible'),
              const SizedBox(height: 10),
              const Text(
                'Novedades:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(notes),
            ],
          ),
          actions: [
            if (!mandatory)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Más tarde'),
              ),
            ElevatedButton(
              onPressed: () async {
                final url = Uri.parse(apkUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Descargar'),
            ),
          ],
        );
      },
    );
  }
}
