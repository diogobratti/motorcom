import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';

class Background {
  static Future<void> initialize(BuildContext context) async {
    const config = FlutterBackgroundAndroidConfig(
      notificationTitle: 'flutter_background example app',
      notificationText:
          'Background notification for keeping the example app running in the background',
      notificationIcon: AndroidResource(name: 'background_icon'),
      notificationImportance: AndroidNotificationImportance.Default,
      enableWifiLock: true,
      showBadge: true,
    );

    var hasPermissions = await FlutterBackground.hasPermissions;
    if (!hasPermissions) {
      await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
                title: const Text('Permissão necessária'),
                content: const Text(
                    'Atenção: para que o aplicativo funcione com a tela bloqueada é necessário aceitar a permissão que será apresentada após o ok.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'OK'),
                    child: const Text('OK'),
                  ),
                ]);
          });
    }

    hasPermissions = await FlutterBackground.initialize(androidConfig: config);

    if (hasPermissions) {
      if (hasPermissions) {
        final backgroundExecution =
            await FlutterBackground.enableBackgroundExecution();
        if (backgroundExecution) {}
      }
    }
  }

  static Future<void> finish() async {
    await FlutterBackground.disableBackgroundExecution();
  }
}
