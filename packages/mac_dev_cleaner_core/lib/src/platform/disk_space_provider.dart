import '../io/process_runner.dart';
import '../report/disk_space.dart';

/// Reads free/total disk space for the primary data volume.
abstract class DiskSpaceProvider {
  Future<DataVolumeSpace?> read(ProcessRunner commandRunner);
}
