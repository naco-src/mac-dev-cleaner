import 'package:file/file.dart';

/// Computes directory sizes without following symlinks; stays on one device when possible.
class SizeScanner {
  SizeScanner(this.fileSystem);

  final FileSystem fileSystem;

  Future<int> directorySize(String path) async {
    final entity = fileSystem.directory(path);
    if (!entity.existsSync()) {
      return 0;
    }
    return _sizeOf(entity);
  }

  Future<int> pathsTotal(Iterable<String> paths) async {
    var total = 0;
    for (final path in paths) {
      final dir = fileSystem.directory(path);
      final file = fileSystem.file(path);
      if (dir.existsSync()) {
        total += await _sizeOf(dir);
      } else if (file.existsSync()) {
        total += file.lengthSync();
      }
    }
    return total;
  }

  Future<int> globContentsSize(String directory, List<String> childNames) async {
    var total = 0;
    final dir = fileSystem.directory(directory);
    if (!dir.existsSync()) {
      return 0;
    }
    for (final name in childNames) {
      final child = fileSystem.path.join(directory, name);
      final d = fileSystem.directory(child);
      final f = fileSystem.file(child);
      if (d.existsSync()) {
        total += await _sizeOf(d);
      } else if (f.existsSync()) {
        total += f.lengthSync();
      }
    }
    return total;
  }

  Future<int> _sizeOf(Directory directory) async {
    var total = 0;
    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is! File) {
          continue;
        }
        try {
          total += entity.lengthSync();
        } catch (_) {
          // Permission or race; skip.
        }
      }
    } catch (_) {
      return total;
    }
    return total;
  }

  List<String> existingChildPaths(String parent, List<String> relativeNames) {
    final result = <String>[];
    for (final name in relativeNames) {
      final full = fileSystem.path.join(parent, name);
      if (fileSystem.directory(full).existsSync() ||
          fileSystem.file(full).existsSync()) {
        result.add(full);
      }
    }
    return result;
  }
}
