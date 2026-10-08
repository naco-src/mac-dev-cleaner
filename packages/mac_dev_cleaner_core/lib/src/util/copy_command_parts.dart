import 'package:path/path.dart' as p;

import '../models/clean_action.dart';
import '../models/copy_command_part.dart';
import '../models/enums.dart';
import '../models/scan_item.dart';

/// Copyable shell lines or paths for one scan item.
List<CopyCommandPart> copyCommandPartsFor(ScanItem item) {
  final action = item.cleanAction;
  if (action == null) return const [];

  return switch (action.method) {
    CleanMethod.runCommand => _runCommandParts(action, item),
    CleanMethod.moveToTrash || CleanMethod.deleteContents => _pathParts(action),
  };
}

List<CopyCommandPart> _runCommandParts(CleanAction action, ScanItem item) {
  final cmd = action.command;
  if (cmd == null || cmd.isEmpty) return const [];

  if (cmd.length >= 3 && cmd[1] == '--uninstall') {
    final sdkmanager = cmd[0];
    final packages = cmd.sublist(2);
    if (packages.length > 1) {
      return [
        for (final pkg in packages)
          CopyCommandPart(
            label: _packageLabel(pkg, item.paths),
            command: '$sdkmanager --uninstall "$pkg"',
          ),
      ];
    }
  }

  final text = action.copyableCommand;
  if (text == null || text.isEmpty) return const [];

  final split = _splitDescription(text);
  if (split.length > 1) {
    return [
      for (final line in split)
        CopyCommandPart(label: _commandLineLabel(line), command: line),
    ];
  }

  return [CopyCommandPart(label: item.name, command: text)];
}

List<CopyCommandPart> _pathParts(CleanAction action) {
  final paths = action.paths;
  if (paths.isEmpty) return const [];
  if (paths.length == 1) {
    return [
      CopyCommandPart(label: _pathLabel(paths.first), command: paths.first),
    ];
  }
  return [
    for (final path in paths)
      CopyCommandPart(label: _pathLabel(path), command: path),
  ];
}

List<String> _splitDescription(String text) {
  if (!text.contains('; ')) return [text];
  return text
      .split('; ')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

String _packageLabel(String package, List<String> paths) {
  if (package.startsWith('ndk;')) {
    final ver = package.substring(4);
    return 'NDK $ver';
  }
  return package;
}

String _commandLineLabel(String line) {
  final trimmed = line.trim();
  if (trimmed.length <= 48) return trimmed;
  return '${trimmed.substring(0, 45)}…';
}

String _pathLabel(String path) {
  final base = p.basename(path);
  if (base.isNotEmpty) return base;
  return path;
}

extension ScanItemCopyCommands on ScanItem {
  List<CopyCommandPart> get copyCommandParts => copyCommandPartsFor(this);

  String? get copyableCommand {
    final parts = copyCommandParts;
    if (parts.isEmpty) return null;
    return parts.map((part) => part.command).join('\n');
  }
}
