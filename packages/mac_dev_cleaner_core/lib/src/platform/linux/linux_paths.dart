import 'dart:io';

import 'package:path/path.dart' as p;

import '../host_paths.dart';
import '../host_platform.dart';

/// Linux-specific paths (XDG layout, Android SDK env, …).
abstract class LinuxPaths extends HostPaths {
  String get configHome;

  String get dataHome;

  String get cacheHome;

  String get stateHome;
}

class LinuxHostPaths extends LinuxPaths {
  LinuxHostPaths({String? home, Map<String, String>? environment})
    : _environment = environment ?? Platform.environment,
      home = home ?? (environment ?? Platform.environment)['HOME'] ?? '';

  final Map<String, String> _environment;

  @override
  final HostPlatform platform = HostPlatform.linux;

  @override
  final String home;

  @override
  String get configHome =>
      _environment['XDG_CONFIG_HOME'] ?? p.join(home, '.config');

  @override
  String get dataHome =>
      _environment['XDG_DATA_HOME'] ?? p.join(home, '.local', 'share');

  @override
  String get cacheHome =>
      _environment['XDG_CACHE_HOME'] ?? p.join(home, '.cache');

  @override
  String get stateHome =>
      _environment['XDG_STATE_HOME'] ?? p.join(home, '.local', 'state');

  @override
  String get androidSdk {
    for (final key in ['ANDROID_SDK_ROOT', 'ANDROID_HOME']) {
      final fromEnv = _environment[key];
      if (fromEnv != null && fromEnv.trim().isNotEmpty) {
        return fromEnv.trim();
      }
    }
    return p.join(home, 'Android', 'Sdk');
  }

  @override
  String? get sdkmanagerBin {
    final sdk = androidSdk;
    final candidates = [
      p.join(sdk, 'cmdline-tools', 'latest', 'bin', 'sdkmanager'),
      p.join(sdk, 'cmdline-tools', 'bin', 'sdkmanager'),
      p.join(sdk, 'tools', 'bin', 'sdkmanager'),
    ];
    for (final path in candidates) {
      if (File(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  @override
  String get androidHome => p.join(home, '.android');

  @override
  String get gradleHome => p.join(home, '.gradle');

  @override
  String get pubCache => p.join(home, '.pub-cache');

  @override
  String get npmCache => p.join(home, '.npm');

  @override
  String get mdcDir => p.join(home, '.mdc');

  @override
  String get historyFile => p.join(mdcDir, 'history.jsonl');

  @override
  String get trash => p.join(dataHome, 'Trash', 'files');

  @override
  List<String> projectRoots() {
    final fromEnv = _environment['MDC_PROJECT_ROOTS'];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) {
      return fromEnv
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [
      p.join(home, 'Projects'),
      p.join(home, 'AndroidStudioProjects'),
      p.join(home, 'Developer'),
      p.join(home, 'studio-projects'),
    ];
  }

  @override
  String expandUser(String path) {
    if (path.startsWith('~/')) {
      return p.join(home, path.substring(2));
    }
    if (path == '~') {
      return home;
    }
    return path;
  }
}
