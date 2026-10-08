import 'package:file/file.dart';
import 'package:file/local.dart';

import '../../io/process_runner.dart';
import '../dev_cleaner_host.dart';
import '../disk_space_provider.dart';
import '../doctor_engine.dart';
import '../host_paths.dart';
import '../host_platform.dart';
import '../scan_engine.dart';
import 'linux_disk_space.dart';
import 'linux_doctor_service.dart';
import 'linux_paths.dart';
import 'linux_scan_service.dart';

class LinuxDevCleanerHost implements DevCleanerHost {
  factory LinuxDevCleanerHost({
    FileSystem? fileSystem,
    ProcessRunner? commandRunner,
    LinuxPaths? paths,
    ScanEngine? scanEngine,
    DoctorEngine? doctorEngine,
    DiskSpaceProvider? diskSpaceProvider,
    int? scanConcurrency,
  }) {
    final fs = fileSystem ?? LocalFileSystem();
    final runner = commandRunner ?? IoProcessRunner();
    final linuxPaths = paths ?? LinuxHostPaths();
    return LinuxDevCleanerHost._(
      fileSystem: fs,
      commandRunner: runner,
      paths: linuxPaths,
      scanEngine:
          scanEngine ??
          LinuxScanService(
            fileSystem: fs,
            commandRunner: runner,
            paths: linuxPaths,
            scanConcurrency: scanConcurrency,
          ),
      doctorEngine:
          doctorEngine ??
          LinuxDoctorService(commandRunner: runner, paths: linuxPaths),
      diskSpaceProvider: diskSpaceProvider ?? const LinuxDiskSpaceProvider(),
    );
  }

  LinuxDevCleanerHost._({
    required this.fileSystem,
    required this.commandRunner,
    required this.paths,
    required this.scanEngine,
    required this.doctorEngine,
    required this.diskSpaceProvider,
  });

  @override
  final HostPlatform platform = HostPlatform.linux;

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
