import 'dart:io';

import 'package:path/path.dart' as p;

class MdcPaths {
  MdcPaths({String? home}) : home = home ?? Platform.environment['HOME'] ?? '';

  final String home;

  String get library => p.join(home, 'Library');
  String get applicationSupport => p.join(library, 'Application Support');
  String get caches => p.join(library, 'Caches');
  String get logs => p.join(library, 'Logs');
  String get developer => p.join(library, 'Developer');
  String get xcodeDerivedData => p.join(developer, 'Xcode', 'DerivedData');
  String get xcodeArchives => p.join(developer, 'Xcode', 'Archives');
  String get deviceSupport => p.join(developer, 'Xcode', 'iOS DeviceSupport');
  String get androidSdk => p.join(home, 'Library', 'Android', 'sdk');

  /// Best-effort sdkmanager path under the default SDK install.
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

  String get androidHome => p.join(home, '.android');
  String get gradleHome => p.join(home, '.gradle');
  String get pubCache => p.join(home, '.pub-cache');
  String get npmCache => p.join(home, '.npm');
  String get mdcDir => p.join(home, '.mdc');
  String get historyFile => p.join(mdcDir, 'history.jsonl');
  String get trash => p.join(home, '.Trash');

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
