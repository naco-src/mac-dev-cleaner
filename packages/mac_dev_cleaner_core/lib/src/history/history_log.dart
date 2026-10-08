import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';

import '../models/plan.dart';
import '../util/paths.dart';

class HistoryLog {
  HistoryLog(this.fileSystem, MdcPaths paths)
      : _historyFile = paths.historyFile;

  final FileSystem fileSystem;
  final String _historyFile;

  Future<void> append(CleanResult result) async {
    final dir = fileSystem.directory(fileSystem.path.dirname(_historyFile));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = fileSystem.file(_historyFile);
    final entry = {
      'time': DateTime.now().toUtc().toIso8601String(),
      'succeeded': result.succeeded
          .map((e) => {'id': e.itemId, 'bytes': e.bytes, 'message': e.message})
          .toList(),
      'failed': result.failed
          .map((e) => {'id': e.itemId, 'message': e.message})
          .toList(),
      'bytesReclaimedEstimate': result.bytesReclaimedEstimate,
    };
    file.writeAsStringSync('${jsonEncode(entry)}\n', mode: FileMode.append);
  }

  Future<List<Map<String, dynamic>>> readAll({int limit = 50}) async {
    final file = fileSystem.file(_historyFile);
    if (!file.existsSync()) {
      return [];
    }
    final lines = file.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
    final slice = lines.length > limit ? lines.sublist(lines.length - limit) : lines;
    return slice.map((l) => jsonDecode(l) as Map<String, dynamic>).toList();
  }
}
