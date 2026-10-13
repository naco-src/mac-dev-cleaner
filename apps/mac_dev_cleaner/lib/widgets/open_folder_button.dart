import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

/// Absolute paths this item can reveal in Finder.
List<String> openableFoldersFor(ScanItem item) {
  final fromItem = item.paths.where(isOpenableFolderPath).toList();
  if (fromItem.isNotEmpty) return fromItem;
  final action = item.cleanAction;
  if (action == null || action.method == CleanMethod.runCommand) {
    return const [];
  }
  return action.paths.where(isOpenableFolderPath).toList();
}

/// True when [value] is a filesystem path, not a shell command.
bool isOpenableFolderPath(String value) {
  if (!value.startsWith('/')) return false;
  if (value.contains('\n') || value.contains(' --')) return false;
  return true;
}

String folderLabel(String path) {
  final trimmed = path.endsWith('/') && path.length > 1
      ? path.substring(0, path.length - 1)
      : path;
  final slash = trimmed.lastIndexOf('/');
  if (slash < 0 || slash == trimmed.length - 1) return trimmed;
  return trimmed.substring(slash + 1);
}

/// Opens [path] in Finder. Files open their parent folder.
Future<void> openFolder(String path) async {
  final folder = _folderToOpen(path);
  final result = await Process.run('open', [folder]);
  if (result.exitCode != 0) {
    final message = '${result.stderr}'.trim();
    throw Exception(message.isEmpty ? 'Could not open $folder' : message);
  }
}

String _folderToOpen(String path) {
  final type = FileSystemEntity.typeSync(path, followLinks: true);
  if (type == FileSystemEntityType.directory) return path;
  if (type == FileSystemEntityType.notFound) return path;
  final parent = File(path).parent.path;
  return parent.isEmpty ? path : parent;
}

class OpenFolderButton extends StatelessWidget {
  const OpenFolderButton({
    super.key,
    required this.paths,
    this.iconSize = 20,
    this.dense = false,
  });

  final List<String> paths;
  final double iconSize;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) return const SizedBox.shrink();

    final tooltip = paths.length > 1 ? 'Open folder…' : 'Open folder';
    final icon = Icon(Icons.folder_open, size: iconSize);

    if (paths.length == 1) {
      return IconButton(
        icon: icon,
        tooltip: tooltip,
        visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
        onPressed: () => _open(context, paths.first),
      );
    }

    return PopupMenuButton<String>(
      tooltip: tooltip,
      icon: icon,
      itemBuilder: (context) => [
        for (final path in paths)
          PopupMenuItem(value: path, child: Text(folderLabel(path))),
      ],
      onSelected: (path) => _open(context, path),
    );
  }

  Future<void> _open(BuildContext context, String path) async {
    try {
      await openFolder(path);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open folder: $error')));
    }
  }
}
