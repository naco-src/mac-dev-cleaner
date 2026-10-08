import 'package:file/file.dart';
import 'package:path/path.dart' as p;

class AndroidAvdAnalyzer {
  AndroidAvdAnalyzer(this.fileSystem, {required this.androidHome});

  final FileSystem fileSystem;
  final String androidHome;

  /// sysdir paths referenced by AVDs (e.g. system-images/android-34/google_apis/arm64-v8a).
  Set<String> usedSystemImageSysdirs() {
    final avdRoot = fileSystem.directory(p.join(androidHome, 'avd'));
    if (!avdRoot.existsSync()) {
      return {};
    }
    final used = <String>{};
    for (final entity in avdRoot.listSync()) {
      if (entity is! Directory) {
        continue;
      }
      if (!entity.path.endsWith('.avd')) {
        continue;
      }
      final config = fileSystem.file(p.join(entity.path, 'config.ini'));
      if (!config.existsSync()) {
        continue;
      }
      for (final line in config.readAsLinesSync()) {
        final trimmed = line.trim();
        if (trimmed.startsWith('image.sysdir.1=')) {
          used.add(trimmed.split('=').last.trim());
        }
      }
    }
    return used;
  }
}
