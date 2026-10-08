import 'dart:io';

import '../io/process_runner.dart';
import '../platform/disk_space_provider.dart';
import '../platform/host_factory.dart';

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

/// Uses the current platform [DiskSpaceProvider] (macOS implementation today).
Future<DataVolumeSpace?> readDataVolumeSpace([ProcessRunner? runner]) async {
  final r = runner ?? IoProcessRunner();
  try {
    final host = createDevCleanerHost();
    return await host.diskSpaceProvider.read(r);
  } on UnsupportedError {
    return null;
  }
}

bool get isMacOs => Platform.isMacOS;
