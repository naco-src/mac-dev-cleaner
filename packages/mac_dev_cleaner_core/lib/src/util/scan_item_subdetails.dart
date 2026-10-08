import 'package:path/path.dart' as p;

import '../models/scan_item.dart';
import '../models/scan_item_subdetail.dart';
import 'copy_command_parts.dart';

List<ScanItemSubdetail> scanItemSubdetailsFor(ScanItem item) {
  final parts = copyCommandPartsFor(item);
  if (parts.isNotEmpty) {
    return [
      for (final part in parts)
        ScanItemSubdetail(label: part.label, value: part.command),
    ];
  }

  if (item.paths.isNotEmpty) {
    return [
      for (final path in item.paths)
        ScanItemSubdetail(label: _pathLabel(path), value: path),
    ];
  }

  final cmd = item.cleanAction?.commandDescription;
  if (cmd != null && cmd.isNotEmpty) {
    return [ScanItemSubdetail(label: 'Command', value: cmd)];
  }

  return const [];
}

String _pathLabel(String path) {
  final base = p.basename(path);
  if (base.isNotEmpty) return base;
  return path;
}

extension ScanItemSubdetails on ScanItem {
  List<ScanItemSubdetail> get subdetails => scanItemSubdetailsFor(this);
}
