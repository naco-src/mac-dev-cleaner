import 'dart:io' as io;

import '../io/process_runner.dart';
import '../platform/host_paths.dart';
import '../util/file_owner.dart';
import 'doctor_service.dart';

Future<List<DoctorIssue>> checkNpmOwnership(
  ProcessRunner commandRunner,
  HostPaths paths,
) async {
  final npmDir = io.Directory(paths.npmCache);
  if (!npmDir.existsSync()) {
    return [];
  }
  final issues = <DoctorIssue>[];
  try {
    await for (final entity in npmDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! io.File) {
        continue;
      }
      final owner = await fileOwnerUid(commandRunner, entity.path);
      if (owner == 0) {
        issues.add(
          DoctorIssue(
            title: 'npm cache has root-owned files',
            detail: entity.path,
            fixCommand: 'sudo chown -R "\$(id -un)" "${paths.npmCache}"',
          ),
        );
        break;
      }
    }
  } on io.FileSystemException {
    issues.add(
      DoctorIssue(
        title: 'Cannot read npm cache',
        detail: paths.npmCache,
        fixCommand: io.Platform.isMacOS
            ? 'Grant Full Disk Access to Terminal (or mdc) in System Settings.'
            : 'Check permissions on ${paths.npmCache}.',
      ),
    );
  }
  return issues;
}

Future<bool> isNpmCacheUsable(
  ProcessRunner commandRunner,
  HostPaths paths,
) async {
  final issues = await checkNpmOwnership(commandRunner, paths);
  return issues.isEmpty;
}
