import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

const version = '0.1.0';

Future<void> main(List<String> arguments) async {
  if (!Platform.isMacOS) {
    stderr.writeln('mdc is intended for macOS only.');
    exitCode = 1;
    return;
  }

  if (arguments.contains('--version')) {
    stdout.writeln('mdc $version');
    return;
  }

  final runner = CommandRunner<void>(
    'mdc',
    'Mac Dev Cleaner — scan and clean developer caches safely.',
  );

  runner.addCommand(ScanCommand());
  runner.addCommand(PlanCommand());
  runner.addCommand(CleanCommand());
  runner.addCommand(DoctorCommand());
  runner.addCommand(HistoryCommand());

  try {
    await runner.run(arguments);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exitCode = 64;
  }
}

CleanPlan buildPlan(
  MacDevCleaner mdc,
  List<ScanItem> items,
  ArgResults argResults,
) {
  final select = argResults.option('select');
  if (select != null && select.trim().isNotEmpty) {
    final ids = select
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    return mdc.plan(items, selectedIds: ids);
  }
  final safeOnly = argResults.flag('safe');
  return mdc.plan(items, safeOnly: safeOnly);
}

void printTable(List<ScanItem> items, {required bool verbose}) {
  const idWidth = 28;
  const sizeWidth = 10;
  const riskWidth = 12;
  stdout.writeln(
    '${'ID'.padRight(idWidth)} ${'SIZE'.padRight(sizeWidth)} ${'RISK'.padRight(riskWidth)} NAME',
  );
  stdout.writeln('-' * 80);
  for (final item in items) {
    if (item.sizeBytes == 0 &&
        item.cleanAction?.method == CleanMethod.runCommand) {
      // Still show command-only items
    } else if (item.sizeBytes == 0 && item.risk == RiskLevel.protected) {
      continue;
    }
    final id = item.id.length > idWidth
        ? item.id.substring(0, idWidth - 1)
        : item.id;
    stdout.writeln(
      '${id.padRight(idWidth)} ${formatBytes(item.sizeBytes).padRight(sizeWidth)} '
      '${item.risk.label.padRight(riskWidth)} ${item.name}',
    );
    stdout.writeln('  ${item.explain} (${item.regenerates.label})');
    if (item.preconditionHint != null) {
      stdout.writeln('  ⚠ ${item.preconditionHint}');
    }
    if (item.detail != null) {
      stdout.writeln('  ${item.detail}');
    }
    if (verbose && item.paths.isNotEmpty) {
      for (final path in item.paths.take(5)) {
        stdout.writeln('  → $path');
      }
      if (item.paths.length > 5) {
        stdout.writeln('  → … +${item.paths.length - 5} more');
      }
    }
    if (verbose && item.cleanAction?.commandDescription != null) {
      stdout.writeln('  cmd: ${item.cleanAction!.commandDescription}');
    }
    stdout.writeln('');
  }
}

class ScanCommand extends Command<void> {
  @override
  final name = 'scan';

  @override
  final description = 'List cleanable items (read-only).';

  ScanCommand() {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show paths.',
    );
  }

  @override
  Future<void> run() async {
    final mdc = MacDevCleaner();
    final before = await mdc.dataVolumeSpace();
    if (before != null) {
      stdout.writeln(
        'Data volume free: ${formatBytes(before.freeBytes)} / ${formatBytes(before.totalBytes)}',
      );
      stdout.writeln('');
    }

    stdout.writeln('Scanning (this can take a few minutes)…');
    final items = await mdc.scan();
    printTable(items, verbose: argResults!.flag('verbose'));
  }
}

class PlanCommand extends Command<void> {
  @override
  final name = 'plan';

  @override
  final description = 'Dry-run what would be cleaned.';

  PlanCommand() {
    argParser
      ..addFlag(
        'safe',
        negatable: false,
        help: 'Only safe items selected by default.',
      )
      ..addOption('select', help: 'Comma-separated item ids.');
  }

  @override
  Future<void> run() async {
    final mdc = MacDevCleaner();
    final items = await mdc.scan();
    final plan = buildPlan(mdc, items, argResults!);
    stdout.writeln(
      'Plan: ${plan.items.length} item(s), ${formatBytes(plan.totalBytes)} reclaimable',
    );
    stdout.writeln('');
    printTable(plan.items, verbose: true);
  }
}

class CleanCommand extends Command<void> {
  @override
  final name = 'clean';

  @override
  final description = 'Execute cleanup (Trash by default).';

  CleanCommand() {
    argParser
      ..addFlag(
        'safe',
        negatable: false,
        help: 'Only safe items selected by default.',
      )
      ..addOption('select', help: 'Comma-separated item ids.')
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Skip per-item confirmation.',
      )
      ..addFlag(
        'delete',
        negatable: false,
        help: 'Permanent delete instead of Trash.',
      );
  }

  @override
  Future<void> run() async {
    final mdc = MacDevCleaner();
    final before = await mdc.dataVolumeSpace();
    final items = await mdc.scan();
    final plan = buildPlan(mdc, items, argResults!);

    if (plan.items.isEmpty) {
      stdout.writeln(
        'Nothing selected. Use --safe, defaults, or --select id1,id2.',
      );
      stdout.writeln('Run `mdc scan` to list ids.');
      return;
    }

    stdout.writeln(
      'Will clean ${plan.items.length} item(s), ~${formatBytes(plan.totalBytes)}',
    );
    final yes = argResults!.flag('yes');
    final permanent = argResults!.flag('delete');

    final result = await mdc.clean(
      plan,
      yes: yes,
      permanentDelete: permanent,
      confirm: yes
          ? null
          : (item) async {
              stdout.write(
                'Clean "${item.name}" (${formatBytes(item.sizeBytes)})? [y/N] ',
              );
              final line = stdin.readLineSync()?.trim().toLowerCase();
              return line == 'y' || line == 'yes';
            },
    );

    stdout.writeln('');
    stdout.writeln(
      'Succeeded: ${result.succeeded.length}, failed: ${result.failed.length}',
    );
    for (final f in result.failed) {
      stderr.writeln('  ${f.itemId}: ${f.message}');
    }

    final after = await mdc.dataVolumeSpace();
    if (before != null && after != null) {
      stdout.writeln(
        'Data volume free: ${formatBytes(before.freeBytes)} → ${formatBytes(after.freeBytes)}',
      );
    }
  }
}

class DoctorCommand extends Command<void> {
  @override
  final name = 'doctor';

  @override
  final description = 'npm ownership, Homebrew, environment hints.';

  @override
  Future<void> run() async {
    final mdc = MacDevCleaner();
    final issues = await mdc.doctorCheck();
    if (issues.isEmpty) {
      stdout.writeln('No issues reported.');
      return;
    }
    for (final issue in issues) {
      stdout.writeln('• ${issue.title}');
      stdout.writeln('  ${issue.detail}');
      if (issue.fixCommand != null) {
        stdout.writeln('  Fix: ${issue.fixCommand}');
      }
      stdout.writeln('');
    }
  }
}

class HistoryCommand extends Command<void> {
  @override
  final name = 'history';

  @override
  final description = 'Past cleanups from ~/.mdc/history.jsonl.';

  HistoryCommand() {
    argParser.addOption('limit', defaultsTo: '20', help: 'Max entries.');
  }

  @override
  Future<void> run() async {
    final mdc = MacDevCleaner();
    final limit = int.tryParse(argResults!.option('limit')!) ?? 20;
    final entries = await mdc.history(limit: limit);
    if (entries.isEmpty) {
      stdout.writeln('No history yet.');
      return;
    }
    for (final entry in entries) {
      stdout.writeln(entry['time']);
      stdout.writeln(
        '  reclaimed ~${formatBytes((entry['bytesReclaimedEstimate'] as num?)?.toInt() ?? 0)}',
      );
    }
  }
}
