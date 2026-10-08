import 'package:file/file.dart';

import 'doctor/doctor_service.dart';
import 'executor/executor.dart' show ConfirmCallback, Executor;
import 'history/history_log.dart';
import 'io/process_runner.dart';
import 'models/plan.dart';
import 'models/scan_item.dart';
import 'platform/dev_cleaner_host.dart';
import 'platform/doctor_engine.dart';
import 'platform/host_factory.dart';
import 'platform/host_paths.dart';
import 'platform/host_platform.dart';
import 'platform/scan_engine.dart';
import 'planner/planner.dart';
import 'report/disk_space.dart';
import 'scanner/scan_log.dart';

class MacDevCleaner {
  MacDevCleaner({
    FileSystem? fileSystem,
    ProcessRunner? commandRunner,
    HostPaths? paths,
    HostPlatform? platform,
    DevCleanerHost? host,
    int? scanConcurrency,
  }) : _host =
           host ??
           createDevCleanerHost(
             platform: platform,
             fileSystem: fileSystem,
             commandRunner: commandRunner,
             paths: paths,
             scanConcurrency: scanConcurrency,
           ) {
    historyLog = HistoryLog(_host.fileSystem, _host.paths);
    planner = Planner();
  }

  final DevCleanerHost _host;

  HostPlatform get platform => _host.platform;

  FileSystem get fileSystem => _host.fileSystem;

  ProcessRunner get commandRunner => _host.commandRunner;

  HostPaths get paths => _host.paths;

  ScanEngine get scanService => _host.scanEngine;

  DoctorEngine get doctor => _host.doctorEngine;

  late final HistoryLog historyLog;
  late final Planner planner;

  Future<List<ScanItem>> scan({ScanProgressCallback? onProgress}) =>
      _host.scanEngine.scanAll(onProgress: onProgress);

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
      _host.diskSpaceProvider.read(commandRunner);

  Future<List<DoctorIssue>> doctorCheck({ScanProgressCallback? onProgress}) =>
      _host.doctorEngine.runAll(onProgress: onProgress);

  Future<List<Map<String, dynamic>>> history({int limit = 50}) =>
      historyLog.readAll(limit: limit);
}
