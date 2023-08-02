import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';

class Background {
  Future<void> initialize(BuildContext context) async {
    final config = FlutterBackgroundAndroidConfig(
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
                title: Text('Permissions needed'),
                content: Text(
                    'Shortly the OS will ask you for permission to execute this app in the background. This is required in order to receive chat messages when the app is not in the foreground.'),
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

  Future<void> finish() async {
    await FlutterBackground.disableBackgroundExecution();
  }
}
