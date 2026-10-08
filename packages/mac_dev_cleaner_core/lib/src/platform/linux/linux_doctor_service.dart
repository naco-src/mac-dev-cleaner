import '../../doctor/doctor_service.dart';
import '../../doctor/npm_checks.dart';
import '../../io/process_runner.dart';
import '../../platform/doctor_engine.dart';
import '../../platform/host_paths.dart';
import '../../scanner/scan_log.dart';
import 'linux_paths.dart';

/// Linux doctor checks; macOS uses [DoctorService].
class LinuxDoctorService implements DoctorEngine {
  LinuxDoctorService({required this.commandRunner, HostPaths? paths})
    : paths = paths ?? LinuxHostPaths();

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
      phase(
        'npm cache ownership',
        () => checkNpmOwnership(commandRunner, paths),
      ),
      phase('npm install path', _checkSudoNpm),
      phase('Homebrew', _checkHomebrewIfAvailable),
    ]);

    final issues = [...results[0], ...results[1], ...results[2]];
    log(
      ScanLogLevel.info,
      'Doctor finished — ${issues.length} item${issues.length == 1 ? '' : 's'} listed',
    );
    return issues;
  }

  Future<List<DoctorIssue>> _checkSudoNpm() async {
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
          fixCommand: 'Prefer nvm, fnm, or a user-level node install; avoid sudo npm install -g.',
        ),
      ];
    }
    return [];
  }

  Future<List<DoctorIssue>> _checkHomebrewIfAvailable() async {
    final which = await commandRunner.run('which', ['brew']);
    if (!which.success || which.stdout.trim().isEmpty) {
      return [];
    }
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
}
