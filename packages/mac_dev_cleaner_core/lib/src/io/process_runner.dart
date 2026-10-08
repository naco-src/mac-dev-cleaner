import 'dart:io';

abstract class ProcessRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  });
}

class ProcessResult {
  ProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get success => exitCode == 0;
}

class IoProcessRunner implements ProcessRunner {
  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: false,
    );
    return ProcessResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    );
  }
}

class FakeProcessRunner implements ProcessRunner {
  FakeProcessRunner({this.handlers = const {}});

  final Map<String, ProcessResult Function(List<String> args)> handlers;
  final List<(String exe, List<String> args)> invocations = [];

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    invocations.add((executable, List.unmodifiable(arguments)));
    final handler = handlers[executable];
    if (handler != null) {
      return handler(arguments);
    }
    return ProcessResult(exitCode: 127, stdout: '', stderr: 'not found');
  }
}
