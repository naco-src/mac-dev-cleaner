import 'package:file/file.dart';

import '../util/parallel.dart';

/// Computes directory sizes without following symlinks; stays on one device when possible.
class SizeScanner {
  SizeScanner(this.fileSystem, {int? concurrency})
    : concurrency = concurrency ?? defaultScanConcurrency();

  final FileSystem fileSystem;
  final int concurrency;

  Future<int> directorySize(String path) async {
    final entity = fileSystem.directory(path);
    if (!entity.existsSync()) {
      return 0;
    }
    return _sizeOf(entity);
  }

  Future<int> pathsTotal(Iterable<String> paths) async {
    final list = paths.toList();
    if (list.isEmpty) {
      return 0;
    }
    final sizes = await mapConcurrent(
      list,
      _pathSize,
      concurrency: concurrency,
    );
    return sizes.fold<int>(0, (sum, n) => sum + n);
  }

  Future<int> _pathSize(String path) async {
    final dir = fileSystem.directory(path);
    final file = fileSystem.file(path);
    if (dir.existsSync()) {
      return _sizeOf(dir);
    }
    if (file.existsSync()) {
      return file.lengthSync();
    }
    return 0;
  }

  Future<int> globContentsSize(
    String directory,
    List<String> childNames,
  ) async {
    final dir = fileSystem.directory(directory);
    if (!dir.existsSync()) {
      return 0;
    }
    final sizes = await mapConcurrent(childNames, (name) async {
      final child = fileSystem.path.join(directory, name);
      final d = fileSystem.directory(child);
      final f = fileSystem.file(child);
      if (d.existsSync()) {
        return _sizeOf(d);
      }
      if (f.existsSync()) {
        return f.lengthSync();
      }
      return 0;
    }, concurrency: concurrency);
    return sizes.fold<int>(0, (sum, n) => sum + n);
  }

  Future<int> _sizeOf(Directory directory) async {
    var total = 0;
    try {
      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
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
