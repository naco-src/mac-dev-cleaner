import 'dart:io' as io;

import '../io/process_runner.dart';
import '../util/paths.dart';

class DoctorIssue {
  DoctorIssue({required this.title, required this.detail, this.fixCommand});

  final String title;
  final String detail;
  final String? fixCommand;
}

class DoctorService {
  DoctorService({required this.commandRunner, MdcPaths? paths})
    : paths = paths ?? MdcPaths();

  final ProcessRunner commandRunner;
  final MdcPaths paths;

  Future<List<DoctorIssue>> runAll() async {
    final issues = <DoctorIssue>[];
    issues.addAll(await checkNpmOwnership());
    issues.addAll(await checkSudoNpm());
    issues.addAll(await checkHomebrew());
    issues.addAll(checkFullDiskAccessHint());
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
