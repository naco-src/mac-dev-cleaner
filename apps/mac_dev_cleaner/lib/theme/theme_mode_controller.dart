import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'theme_mode';

/// Persists user theme preference (system / light / dark).
class ThemeModeController extends ChangeNotifier {
  ThemeModeController({ThemeMode initial = ThemeMode.system}) : _mode = initial;

  ThemeMode _mode;

  ThemeMode get mode => _mode;

  static Future<ThemeModeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    final mode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return ThemeModeController(initial: mode);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final stored = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_prefKey, stored);
  }

  Future<void> cycleMode() async {
    final next = switch (_mode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setMode(next);
  }

  IconData iconForMode() {
    return switch (_mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
  }

  String tooltipForMode() {
    return switch (_mode) {
      ThemeMode.light => 'Theme: light (click for dark)',
      ThemeMode.dark => 'Theme: dark (click for system)',
      ThemeMode.system => 'Theme: system (click for light)',
    };
  }
}
