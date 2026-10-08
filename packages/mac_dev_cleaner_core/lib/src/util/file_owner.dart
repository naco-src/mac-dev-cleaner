import 'dart:io' show Platform;

import '../io/process_runner.dart';

Future<int?> fileOwnerUid(ProcessRunner commandRunner, String path) async {
  if (Platform.isMacOS) {
    final result = await commandRunner.run('stat', ['-f', '%u', path]);
    if (!result.success) {
      return null;
    }
    return int.tryParse(result.stdout.trim());
  }
  if (Platform.isLinux) {
    final result = await commandRunner.run('stat', ['-c', '%u', path]);
    if (!result.success) {
      return null;
    }
    return int.tryParse(result.stdout.trim());
  }
  return null;
}
