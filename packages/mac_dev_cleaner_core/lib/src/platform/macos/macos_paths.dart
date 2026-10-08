import 'dart:io';

import 'package:path/path.dart' as p;

import '../host_paths.dart';
import '../host_platform.dart';

/// macOS-specific paths (Library, Xcode, Application Support, …).
abstract class MacOSPaths extends HostPaths {
  String get library;

  String get applicationSupport;

  String get caches;

  String get logs;

  String get developer;

  String get xcodeDerivedData;

  String get xcodeArchives;

  String get deviceSupport;
}

class MacOSHostPaths extends MacOSPaths {
  MacOSHostPaths({String? home})
    : home = home ?? Platform.environment['HOME'] ?? '';

  @override
  final HostPlatform platform = HostPlatform.macos;

  @override
  final String home;

  @override
  String get library => p.join(home, 'Library');

  @override
  String get applicationSupport => p.join(library, 'Application Support');

  @override
  String get caches => p.join(library, 'Caches');

  @override
  String get logs => p.join(library, 'Logs');

  @override
  String get developer => p.join(library, 'Developer');

  @override
  String get xcodeDerivedData => p.join(developer, 'Xcode', 'DerivedData');

  @override
  String get xcodeArchives => p.join(developer, 'Xcode', 'Archives');

  @override
  String get deviceSupport => p.join(developer, 'Xcode', 'iOS DeviceSupport');

  @override
  String get androidSdk => p.join(home, 'Library', 'Android', 'sdk');

  @override
  String? get sdkmanagerBin {
    final candidates = [
      p.join(androidSdk, 'cmdline-tools', 'latest', 'bin', 'sdkmanager'),
      p.join(androidSdk, 'cmdline-tools', 'bin', 'sdkmanager'),
      p.join(androidSdk, 'tools', 'bin', 'sdkmanager'),
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
  String get trash => p.join(home, '.Trash');

  @override
  List<String> projectRoots() {
    final fromEnv = Platform.environment['MDC_PROJECT_ROOTS'];
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
      p.join(home, 'StudioProjects'),
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
