import 'package:flutter/material.dart';
import 'package:updatermaster/updatermaster.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // Obtener versión actual de la app
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // Verificar actualizaciones desde GitHub
      bool hasUpdate = await UpdaterMaster.withGithub(
        repo: "https://github.com/TU_USUARIO/TU_REPO", // Cambia por tu repo
        version: "v$currentVersion",
      );

      if (hasUpdate && context.mounted) {
        _showUpdateDialog(context);
      }
    } catch (e) {
      print("Error checking updates: $e");
    }
  }

  static void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¡Nueva versión disponible!'),
          content: const Text(
            'Hay una actualización disponible para mejorar tu experiencia. '
            '¿Quieres descargarla ahora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ahora no'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Abrir la página de releases de GitHub
                final url = Uri.parse(
                  'https://github.com/TU_USUARIO/TU_REPO/releases/latest',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }
}
