import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'locale_provider.dart';

class UpdateChecker {
  static const String versionUrl =
      'https://github.com/Aberinkula36/un_dia_sin_beber/raw/refs/heads/main/version.json';

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      print("🔍 Verificando actualizaciones...");

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      print("📱 Versión actual: $currentVersion");

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
        print("🔗 URL del APK: $apkUrl");

        if (_isNewerVersion(latestVersion, currentVersion)) {
          print("🔄 ¡Hay actualización disponible!");

          // Obtener el LocaleProvider para pasar el idioma actual
          final localeProvider = Provider.of<LocaleProvider>(
            context,
            listen: false,
          );

          await _showUpdateDialog(
            context,
            latestVersion,
            apkUrl,
            notes,
            mandatory,
            localeProvider.locale.languageCode,
          );
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

  static void _showErrorDialog(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).error),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).ok),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showUpdateDialog(
    BuildContext context,
    String version,
    String apkUrl,
    String notes,
    bool mandatory,
    String languageCode,
  ) async {
    final l10n = AppLocalizations.of(context);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            mandatory ? l10n.mandatoryUpdate : l10n.updateAvailable,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.records} $version', // Usamos "records" como "versión"
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  l10n.releaseNotes,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(notes, style: const TextStyle(height: 1.5)),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.downloadInfo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (!mandatory)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  l10n.later,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ElevatedButton(
              onPressed: () async {
                print("📲 Botón Descargar pulsado");
                print("🔗 URL: $apkUrl");

                try {
                  final url = Uri.parse(apkUrl);
                  print("🌐 URI parseada: $url");

                  bool launched = await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                  print("✅ ¿Lanzado? $launched");

                  if (launched) {
                    print("✅ URL lanzada correctamente en navegador externo");
                    Navigator.of(context).pop();
                  } else {
                    print("❌ No se pudo lanzar");
                    Navigator.of(context).pop();
                    _showErrorDialog(context, "No se pudo abrir el enlace");
                  }
                } catch (e) {
                  print("❌ Error al lanzar URL: $e");
                  Navigator.of(context).pop();
                  _showErrorDialog(context, "Error al abrir: $e");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 40),
              ),
              child: Text(l10n.download),
            ),
          ],
        );
      },
    );
  }
}
