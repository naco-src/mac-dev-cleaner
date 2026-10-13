import 'package:path/path.dart' as p;

import '../models/scan_item.dart';
import '../models/scan_item_subdetail.dart';
import 'copy_command_parts.dart';

List<ScanItemSubdetail> scanItemSubdetailsFor(ScanItem item) {
  final parts = copyCommandPartsFor(item);
  if (parts.isNotEmpty) {
    return _largestFirst([
      for (var i = 0; i < parts.length; i++)
        ScanItemSubdetail(
          label: parts[i].label,
          value: parts[i].command,
          sizeBytes: _subdetailSizeBytes(
            item,
            parts[i].command,
            i,
            parts.length,
          ),
        ),
    ]);
  }

  if (item.paths.isNotEmpty) {
    return _largestFirst([
      for (var i = 0; i < item.paths.length; i++)
        ScanItemSubdetail(
          label: _pathLabel(item.paths[i]),
          value: item.paths[i],
          sizeBytes: _subdetailSizeBytes(
            item,
            item.paths[i],
            i,
            item.paths.length,
          ),
        ),
    ]);
  }

  final cmd = item.cleanAction?.commandDescription;
  if (cmd != null && cmd.isNotEmpty) {
    return [
      ScanItemSubdetail(
        label: 'Command',
        value: cmd,
        sizeBytes: item.sizeBytes > 0 ? item.sizeBytes : null,
      ),
    ];
  }

  return const [];
}

/// Largest known size first. Unknown sizes stay at the end; ties keep input order.
List<ScanItemSubdetail> _largestFirst(List<ScanItemSubdetail> details) {
  final indexed = [
    for (var i = 0; i < details.length; i++) (detail: details[i], index: i),
  ];
  indexed.sort((a, b) {
    final sizeCompare = (b.detail.sizeBytes ?? -1).compareTo(
      a.detail.sizeBytes ?? -1,
    );
    if (sizeCompare != 0) return sizeCompare;
    return a.index.compareTo(b.index);
  });
  return [for (final entry in indexed) entry.detail];
}

int? _subdetailSizeBytes(
  ScanItem item,
  String value,
  int index,
  int partCount,
) {
  final map = item.pathSizes;
  if (map.isNotEmpty) {
    final direct = map[value];
    if (direct != null) return direct;
    if (index < item.paths.length) {
      final byPath = map[item.paths[index]];
      if (byPath != null) return byPath;
    }
  }
  if (partCount == 1 && item.sizeBytes > 0) {
    return item.sizeBytes;
  }
  return null;
}

String _pathLabel(String path) {
  final base = p.basename(path);
  if (base.isNotEmpty) return base;
  return path;
}

extension ScanItemSubdetails on ScanItem {
  List<ScanItemSubdetail> get subdetails => scanItemSubdetailsFor(this);
}
