import 'package:file/file.dart';
import 'package:file/local.dart';

import '../../doctor/doctor_service.dart';
import '../../io/process_runner.dart';
import '../../scanner/scan_service.dart';
import '../dev_cleaner_host.dart';
import '../disk_space_provider.dart';
import '../doctor_engine.dart';
import '../host_paths.dart';
import '../host_platform.dart';
import '../scan_engine.dart';
import 'macos_disk_space.dart';
import 'macos_paths.dart';

class MacOSDevCleanerHost implements DevCleanerHost {
  factory MacOSDevCleanerHost({
    FileSystem? fileSystem,
    ProcessRunner? commandRunner,
    MacOSPaths? paths,
    ScanEngine? scanEngine,
    DoctorEngine? doctorEngine,
    DiskSpaceProvider? diskSpaceProvider,
    int? scanConcurrency,
  }) {
    final fs = fileSystem ?? LocalFileSystem();
    final runner = commandRunner ?? IoProcessRunner();
    final macPaths = paths ?? MacOSHostPaths();
    return MacOSDevCleanerHost._(
      fileSystem: fs,
      commandRunner: runner,
      paths: macPaths,
      scanEngine:
          scanEngine ??
          ScanService(
            fileSystem: fs,
            commandRunner: runner,
            paths: macPaths,
            scanConcurrency: scanConcurrency,
          ),
      doctorEngine:
          doctorEngine ?? DoctorService(commandRunner: runner, paths: macPaths),
      diskSpaceProvider: diskSpaceProvider ?? const MacOSDiskSpaceProvider(),
    );
  }

  MacOSDevCleanerHost._({
    required this.fileSystem,
    required this.commandRunner,
    required this.paths,
    required this.scanEngine,
    required this.doctorEngine,
    required this.diskSpaceProvider,
  });

  @override
  final HostPlatform platform = HostPlatform.macos;

  @override
  final HostPaths paths;

  @override
  final FileSystem fileSystem;

  @override
  final ProcessRunner commandRunner;

  @override
  final ScanEngine scanEngine;

  @override
  final DoctorEngine doctorEngine;

  @override
  final DiskSpaceProvider diskSpaceProvider;
}
