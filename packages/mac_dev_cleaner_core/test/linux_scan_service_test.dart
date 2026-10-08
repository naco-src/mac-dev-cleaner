import 'package:file/memory.dart';
import 'package:mac_dev_cleaner_core/src/io/process_runner.dart';
import 'package:mac_dev_cleaner_core/src/platform/linux/linux_paths.dart';
import 'package:mac_dev_cleaner_core/src/platform/linux/linux_scan_service.dart';
import 'package:test/test.dart';

class _FakeRunner implements ProcessRunner {
  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    if (executable == 'which') {
      return ProcessResult(exitCode: 1, stdout: '', stderr: '');
    }
    if (executable == 'pgrep') {
      return ProcessResult(exitCode: 1, stdout: '', stderr: '');
    }
    return ProcessResult(exitCode: 1, stdout: '', stderr: '');
  }
}

void main() {
  test('LinuxScanService scanAll completes on empty home', () async {
    final fs = MemoryFileSystem();
    const home = '/home/dev';
    fs.directory(home).createSync(recursive: true);
    final paths = LinuxHostPaths(
      home: home,
      environment: {'HOME': home, 'MDC_PROJECT_ROOTS': home},
    );
    final service = LinuxScanService(
      fileSystem: fs,
      commandRunner: _FakeRunner(),
      paths: paths,
      scanConcurrency: 2,
    );
    final items = await service.scanAll();
    expect(items, isA<List>());
  });

  test('LinuxScanService reports Gradle cache when present', () async {
    final fs = MemoryFileSystem();
    const home = '/home/dev';
    final gradleCache = '$home/.gradle/caches';
    fs.directory(gradleCache).createSync(recursive: true);
    fs.file('$gradleCache/foo.jar').createSync();
    fs.file('$gradleCache/foo.jar').writeAsStringSync('x' * 100);

    final paths = LinuxHostPaths(
      home: home,
      environment: {'HOME': home, 'MDC_PROJECT_ROOTS': home},
    );
    final service = LinuxScanService(
      fileSystem: fs,
      commandRunner: _FakeRunner(),
      paths: paths,
      scanConcurrency: 2,
    );
    final items = await service.scanAll();
    expect(items.any((i) => i.id == 'gradle-caches'), isTrue);
  });
}
