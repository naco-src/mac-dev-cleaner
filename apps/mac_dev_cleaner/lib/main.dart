import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';
import 'theme/theme_mode_controller.dart';
import 'updater/desktop_updater_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isMacOS && !Platform.isLinux) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Mac Dev Cleaner runs on macOS and Linux only.'),
          ),
        ),
      ),
    );
    return;
  }
  final updaterController = Platform.isMacOS
      ? await createDesktopUpdaterController()
      : null;
  final themeModeController = await ThemeModeController.load();
  runApp(
    MacDevCleanerApp(
      updaterController: updaterController,
      themeModeController: themeModeController,
    ),
  );
}
