import 'package:file/file.dart';
import 'package:file/local.dart';

import 'doctor/doctor_service.dart';
import 'executor/executor.dart' show ConfirmCallback, Executor;
import 'history/history_log.dart';
import 'io/process_runner.dart';
import 'models/plan.dart';
import 'models/scan_item.dart';
import 'planner/planner.dart';
import 'report/disk_space.dart';
import 'scanner/scan_log.dart';
import 'scanner/scan_service.dart';
import 'util/paths.dart';

class MacDevCleaner {
  MacDevCleaner({
    FileSystem? fileSystem,
    ProcessRunner? commandRunner,
    MdcPaths? paths,
  }) : fileSystem = fileSystem ?? LocalFileSystem(),
       commandRunner = commandRunner ?? IoProcessRunner(),
       paths = paths ?? MdcPaths() {
    scanService = ScanService(
      fileSystem: this.fileSystem,
      commandRunner: this.commandRunner,
      paths: this.paths,
    );
    historyLog = HistoryLog(this.fileSystem, this.paths);
    planner = Planner();
    doctor = DoctorService(
      commandRunner: this.commandRunner,
      paths: this.paths,
    );
  }

  final FileSystem fileSystem;
  final ProcessRunner commandRunner;
  final MdcPaths paths;
  late final ScanService scanService;
  late final HistoryLog historyLog;
  late final Planner planner;
  late final DoctorService doctor;

  Future<List<ScanItem>> scan({ScanProgressCallback? onProgress}) =>
      scanService.scanAll(onProgress: onProgress);

  CleanPlan plan(
    List<ScanItem> items, {
    bool safeOnly = false,
    Set<String>? selectedIds,
  }) {
    return planner.buildPlan(
      items,
      safeOnly: safeOnly,
      selectedIds: selectedIds,
    );
  }

  Future<CleanResult> clean(
    CleanPlan plan, {
    bool yes = false,
    bool permanentDelete = false,
    ConfirmCallback? confirm,
  }) async {
    final executor = Executor(
      fileSystem: fileSystem,
      commandRunner: commandRunner,
      paths: paths,
      historyLog: historyLog,
      permanentDelete: permanentDelete,
    );
    return executor.execute(plan, skipConfirm: yes, confirm: confirm);
  }

  Future<DataVolumeSpace?> dataVolumeSpace() =>
      readDataVolumeSpace(commandRunner);

  Future<List<DoctorIssue>> doctorCheck({ScanProgressCallback? onProgress}) =>
      doctor.runAll(onProgress: onProgress);

  Future<List<Map<String, dynamic>>> history({int limit = 50}) =>
      historyLog.readAll(limit: limit);
}
