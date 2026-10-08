import 'dart:io' as io;

import '../io/process_runner.dart';
import '../platform/doctor_engine.dart';
import '../platform/host_paths.dart';
import '../platform/macos/macos_paths.dart';
import '../scanner/scan_log.dart';

class DoctorIssue {
  DoctorIssue({required this.title, required this.detail, this.fixCommand});

  final String title;
  final String detail;
  final String? fixCommand;
}

/// macOS doctor checks; other platforms should provide their own [DoctorEngine].
class DoctorService implements DoctorEngine {
  DoctorService({required this.commandRunner, HostPaths? paths})
    : paths = paths ?? MacOSHostPaths();

  final ProcessRunner commandRunner;
  final HostPaths paths;

  @override
  Future<List<DoctorIssue>> runAll({ScanProgressCallback? onProgress}) async {
    void log(ScanLogLevel level, String message) {
      onProgress?.call(ScanLogEntry(level: level, message: message));
    }

    Future<List<DoctorIssue>> phase(
      String name,
      Future<List<DoctorIssue>> Function() run,
    ) async {
      log(ScanLogLevel.info, '→ $name');
      try {
        final result = await run();
        log(
          ScanLogLevel.info,
          '✓ $name (${result.length} issue${result.length == 1 ? '' : 's'})',
        );
        return result;
      } catch (e, st) {
        log(ScanLogLevel.error, '✗ $name: $e');
        if (e is! Exception) {
          log(ScanLogLevel.error, st.toString().split('\n').first);
        }
        return [];
      }
    }

    log(ScanLogLevel.info, 'Doctor started');
    final results = await Future.wait<List<DoctorIssue>>([
      phase('npm cache ownership', checkNpmOwnership),
      phase('npm install path', checkSudoNpm),
      phase('Homebrew', checkHomebrew),
    ]);
    log(ScanLogLevel.info, '→ Full Disk Access hint');
    final fda = checkFullDiskAccessHint();
    log(
      ScanLogLevel.info,
      '✓ Full Disk Access hint (${fda.length} note${fda.length == 1 ? '' : 's'})',
    );

    final issues = [...results[0], ...results[1], ...results[2], ...fda];
    log(
      ScanLogLevel.info,
      'Doctor finished — ${issues.length} item${issues.length == 1 ? '' : 's'} listed',
    );
    return issues;
  }

  Future<List<DoctorIssue>> checkNpmOwnership() async {
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
        final owner = await _fileOwnerUid(entity.path);
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
          fixCommand:
              'Grant Full Disk Access to Terminal (or mdc) in System Settings.',
        ),
      );
    }
    return issues;
  }

  Future<List<DoctorIssue>> checkSudoNpm() async {
    final result = await commandRunner.run('which', ['npm']);
    if (!result.success) {
      return [];
    }
    final npmPath = result.stdout.trim();
    if (npmPath.contains('/usr/local/lib/node_modules') ||
        npmPath.startsWith('/usr/')) {
      return [
        DoctorIssue(
          title: 'npm may have been installed with sudo',
          detail: npmPath,
          fixCommand:
              'Prefer nvm, fnm, or Homebrew node; avoid sudo npm install -g.',
        ),
      ];
    }
    return [];
  }

  Future<List<DoctorIssue>> checkHomebrew() async {
    final doctor = await commandRunner.run('brew', ['doctor']);
    if (doctor.success) {
      return [];
    }
    return [
      DoctorIssue(
        title: 'Homebrew doctor reported problems',
        detail: doctor.stderr.trim().isNotEmpty
            ? doctor.stderr.trim()
            : doctor.stdout.trim(),
        fixCommand: 'brew doctor',
      ),
    ];
  }

  Future<int?> _fileOwnerUid(String path) async {
    if (!io.Platform.isMacOS) {
      return null;
    }
    final result = await commandRunner.run('stat', ['-f', '%u', path]);
    if (!result.success) {
      return null;
    }
    return int.tryParse(result.stdout.trim());
  }

  List<DoctorIssue> checkFullDiskAccessHint() {
    if (!io.Platform.isMacOS) {
      return [];
    }
    return [
      DoctorIssue(
        title: 'Full Disk Access',
        detail: 'If scan sizes look too small, add Terminal (or your IDE) under Privacy & Security → Full Disk Access.',
      ),
    ];
  }
}
