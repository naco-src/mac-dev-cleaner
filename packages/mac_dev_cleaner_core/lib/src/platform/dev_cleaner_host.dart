import 'package:file/file.dart';

import '../io/process_runner.dart';
import 'disk_space_provider.dart';
import 'doctor_engine.dart';
import 'host_paths.dart';
import 'host_platform.dart';
import 'scan_engine.dart';

/// Platform bundle: paths, scan rules, doctor checks, and disk metrics.
abstract class DevCleanerHost {
  HostPlatform get platform;

  HostPaths get paths;

  FileSystem get fileSystem;

  ProcessRunner get commandRunner;

  ScanEngine get scanEngine;

  DoctorEngine get doctorEngine;

  DiskSpaceProvider get diskSpaceProvider;
}
