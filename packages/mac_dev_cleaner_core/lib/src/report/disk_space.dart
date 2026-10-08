import 'dart:io';

import '../io/process_runner.dart';

class DataVolumeSpace {
  DataVolumeSpace({
    required this.mountPoint,
    required this.totalBytes,
    required this.freeBytes,
    required this.usedBytes,
  });

  final String mountPoint;
  final int totalBytes;
  final int freeBytes;
  final int usedBytes;
}

Future<DataVolumeSpace?> readDataVolumeSpace([ProcessRunner? runner]) async {
  final r = runner ?? IoProcessRunner();
  final result = await r.run('df', ['-k', '/System/Volumes/Data']);
  if (!result.success) {
    return null;
  }
  final lines = result.stdout
      .split('\n')
      .where((l) => l.trim().isNotEmpty)
      .toList();
  if (lines.length < 2) {
    return null;
  }
  final parts = lines[1].split(RegExp(r'\s+'));
  if (parts.length < 4) {
    return null;
  }
  final totalK = int.tryParse(parts[1]) ?? 0;
  final usedK = int.tryParse(parts[2]) ?? 0;
  final availK = int.tryParse(parts[3]) ?? 0;
  const k = 1024;
  return DataVolumeSpace(
    mountPoint: '/System/Volumes/Data',
    totalBytes: totalK * k,
    freeBytes: availK * k,
    usedBytes: usedK * k,
  );
}

bool get isMacOs => Platform.isMacOS;
