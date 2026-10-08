import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:path/path.dart' as p;

import '../history/history_log.dart';
import '../io/process_runner.dart';
import '../models/clean_action.dart';
import '../models/enums.dart';
import '../models/plan.dart';
import '../models/scan_item.dart';
import '../util/paths.dart';

typedef ConfirmCallback = Future<bool> Function(ScanItem item);

class Executor {
  Executor({
    required this.fileSystem,
    required this.commandRunner,
    required this.paths,
    required this.historyLog,
    this.useTrash = true,
    this.permanentDelete = false,
  });

  final FileSystem fileSystem;
  final ProcessRunner commandRunner;
  final MdcPaths paths;
  final HistoryLog historyLog;
  final bool useTrash;
  final bool permanentDelete;

  Future<CleanResult> execute(
    CleanPlan plan, {
    ConfirmCallback? confirm,
    bool skipConfirm = false,
  }) async {
    final succeeded = <CleanResultEntry>[];
    final failed = <CleanResultEntry>[];
    var reclaimed = 0;

    for (final item in plan.items) {
      if (!skipConfirm && confirm != null) {
        final ok = await confirm(item);
        if (!ok) {
          continue;
        }
      }
      final action = item.cleanAction!;
      try {
        final bytes = await _executeAction(item, action);
        reclaimed += bytes;
        succeeded.add(
          CleanResultEntry(itemId: item.id, message: 'OK', bytes: bytes),
        );
      } catch (e) {
        failed.add(CleanResultEntry(itemId: item.id, message: e.toString()));
      }
    }

    final result = CleanResult(
      succeeded: succeeded,
      failed: failed,
      bytesReclaimedEstimate: reclaimed,
    );
    await historyLog.append(result);
    return result;
  }

  Future<int> _executeAction(ScanItem item, CleanAction action) async {
    switch (action.method) {
      case CleanMethod.runCommand:
        final cmd = action.command!;
        final result = await commandRunner.run(cmd.first, cmd.sublist(1));
        if (!result.success) {
          throw Exception(
            '${cmd.join(' ')} failed (${result.exitCode}): ${result.stderr.trim()}',
          );
        }
        return item.sizeBytes;
      case CleanMethod.moveToTrash:
        if (permanentDelete) {
          return _deletePaths(action.paths);
        }
        return _trashPaths(action.paths);
      case CleanMethod.deleteContents:
        if (permanentDelete && !useTrash) {
          return _deletePaths(action.paths);
        }
        if (useTrash && !permanentDelete) {
          return _trashPaths(action.paths);
        }
        return _deleteContents(action.paths);
    }
  }

  Future<int> _trashPaths(List<String> targetPaths) async {
    var total = 0;
    final trash = paths.trash;
    if (!fileSystem.directory(trash).existsSync()) {
      fileSystem.directory(trash).createSync(recursive: true);
    }
    for (final path in targetPaths) {
      if (!fileSystem.directory(path).existsSync() &&
          !fileSystem.file(path).existsSync()) {
        continue;
      }
      total += await _sizeOfPath(path);
      final base = p.basename(path);
      var dest = p.join(trash, base);
      var n = 1;
      while (fileSystem.directory(dest).existsSync() ||
          fileSystem.file(dest).existsSync()) {
        dest = p.join(trash, '$base.$n');
        n++;
      }
      await _movePath(path, dest);
    }
    return total;
  }

  Future<int> _deletePaths(List<String> paths) async {
    var total = 0;
    for (final path in paths) {
      total += await _sizeOfPath(path);
      final dir = fileSystem.directory(path);
      final file = fileSystem.file(path);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      } else if (file.existsSync()) {
        file.deleteSync();
      }
    }
    return total;
  }

  Future<int> _deleteContents(List<String> paths) async {
    var total = 0;
    for (final path in paths) {
      final dir = fileSystem.directory(path);
      if (!dir.existsSync()) {
        continue;
      }
      for (final child in dir.listSync()) {
        total += await _sizeOfPath(child.path);
        if (fileSystem.directory(child.path).existsSync()) {
          fileSystem.directory(child.path).deleteSync(recursive: true);
        } else {
          fileSystem.file(child.path).deleteSync();
        }
      }
    }
    return total;
  }

  Future<void> _movePath(String from, String to) async {
    try {
      io.Directory(from).renameSync(to);
    } on io.FileSystemException {
      await io.Process.run('mv', [from, to]);
    }
  }

  Future<int> _sizeOfPath(String path) async {
    final dir = fileSystem.directory(path);
    final file = fileSystem.file(path);
    if (file.existsSync()) {
      return file.lengthSync();
    }
    if (!dir.existsSync()) {
      return 0;
    }
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      try {
        total += entity.lengthSync();
      } catch (_) {
        // skip
      }
    }
    return total;
  }
}
