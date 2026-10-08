import 'process_runner.dart';

Future<bool> isProcessRunning(ProcessRunner runner, String processName) async {
  final result = await runner.run('pgrep', ['-x', processName]);
  return result.success && result.stdout.trim().isNotEmpty;
}

Future<bool> isAnyProcessRunning(
  ProcessRunner runner,
  List<String> processNames,
) async {
  for (final name in processNames) {
    if (await isProcessRunning(runner, name)) {
      return true;
    }
  }
  return false;
}
