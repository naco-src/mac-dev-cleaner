import 'package:file/file.dart';

import '../io/process_runner.dart';
import 'dev_cleaner_host.dart';
import 'host_paths.dart';
import 'host_platform.dart';
import 'macos/macos_dev_cleaner_host.dart';
import 'macos/macos_paths.dart';

/// Creates the [DevCleanerHost] for the current OS (macOS today).
DevCleanerHost createDevCleanerHost({
  HostPlatform? platform,
  FileSystem? fileSystem,
  ProcessRunner? commandRunner,
  HostPaths? paths,
  int? scanConcurrency,
}) {
  final resolved = platform ?? currentHostPlatform();
  switch (resolved) {
    case HostPlatform.macos:
      final macPaths = _macPaths(paths);
      return MacOSDevCleanerHost(
        fileSystem: fileSystem,
        commandRunner: commandRunner,
        paths: macPaths,
        scanConcurrency: scanConcurrency,
      );
    case HostPlatform.linux:
    case HostPlatform.windows:
    case HostPlatform.unknown:
      throw UnsupportedError(
        'Dev cleaner is not implemented for $resolved yet. '
        'Supported: ${HostPlatform.macos.name}.',
      );
  }
}

MacOSPaths _macPaths(HostPaths? paths) {
  return switch (paths) {
    null => MacOSHostPaths(),
    final MacOSPaths mac => mac,
    final HostPaths p => MacOSHostPaths(home: p.home),
  };
}
