import 'package:file/file.dart';

import '../io/process_runner.dart';
import 'dev_cleaner_host.dart';
import 'host_paths.dart';
import 'host_platform.dart';
import 'linux/linux_dev_cleaner_host.dart';
import 'linux/linux_paths.dart';
import 'macos/macos_dev_cleaner_host.dart';
import 'macos/macos_paths.dart';

/// Creates the [DevCleanerHost] for the current OS.
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
      final linuxPaths = _linuxPaths(paths);
      return LinuxDevCleanerHost(
        fileSystem: fileSystem,
        commandRunner: commandRunner,
        paths: linuxPaths,
        scanConcurrency: scanConcurrency,
      );
    case HostPlatform.windows:
    case HostPlatform.unknown:
      throw UnsupportedError(
        'Dev cleaner is not implemented for $resolved yet. '
        'Supported: ${HostPlatform.macos.name}, ${HostPlatform.linux.name}.',
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

LinuxPaths _linuxPaths(HostPaths? paths) {
  return switch (paths) {
    null => LinuxHostPaths(),
    final LinuxPaths linux => linux,
    final HostPaths p => LinuxHostPaths(home: p.home),
  };
}
