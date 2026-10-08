import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isMacOS) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Mac Dev Cleaner runs on macOS only.')),
        ),
      ),
    );
    return;
  }
  runApp(const MacDevCleanerApp());
}
