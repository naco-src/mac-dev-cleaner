import '../models/deletion_guide.dart';
import '../models/enums.dart';
import '../models/scan_item.dart';
import '../util/format.dart';
import 'copy_command_parts.dart';

DeletionGuide deletionGuideFor(ScanItem item) {
  if (item.risk == RiskLevel.protected) {
    return DeletionGuide(
      summary:
          '${item.name} is report-only. Mac Dev Cleaner never deletes this.',
      steps: const [
        DeletionGuideStep(
          title: 'Why it appears',
          body:
              'Shown for disk context only. Remove data manually only if you '
              'understand what it is used for.',
        ),
      ],
      notes: [
        if (item.paths.isNotEmpty) 'Location: ${item.paths.join(', ')}',
        'Regenerates: ${item.regenerates.label}.',
      ],
    );
  }

  final action = item.cleanAction;
  if (action == null) {
    return DeletionGuide(
      summary: 'No automated clean action is defined for ${item.name}.',
      notes: [item.explain],
    );
  }

  final before = <String>[];
  if (item.preconditionHint != null) {
    before.add(item.preconditionHint!);
  }
  if (item.risk == RiskLevel.conditional) {
    before.add('Conditional rule — review targets before deleting.');
  }

  final notes = <String>[
    item.explain,
    'Comes back: ${item.regenerates.label}.',
    'Mac Dev Cleaner never runs sudo; run elevated commands yourself if needed.',
  ];

  return switch (action.method) {
    CleanMethod.runCommand => _runCommandGuide(item, before, notes),
    CleanMethod.moveToTrash => _trashGuide(
      item,
      before,
      notes,
      emptyOnly: false,
    ),
    CleanMethod.deleteContents => _trashGuide(
      item,
      before,
      notes,
      emptyOnly: true,
    ),
  };
}

DeletionGuide _runCommandGuide(
  ScanItem item,
  List<String> before,
  List<String> notes,
) {
  final parts = copyCommandPartsFor(item);
  final steps = <DeletionGuideStep>[
    const DeletionGuideStep(
      title: 'In Mac Dev Cleaner',
      body:
          'Select this item and choose Clean. The app runs the same official '
          'command(s) for you.',
    ),
    const DeletionGuideStep(
      title: 'Manually in Terminal',
      body:
          'Paste and run each command below in Terminal (one at a time). '
          'Prefer these over deleting files with rm.',
    ),
  ];

  if (parts.isEmpty) {
    final cmd = item.cleanAction?.copyableCommand;
    if (cmd != null) {
      steps.add(
        DeletionGuideStep(title: 'Command', body: 'Run:', copyText: cmd),
      );
    }
  } else if (parts.length == 1) {
    steps.add(
      DeletionGuideStep(
        title: 'Command',
        body: 'Run:',
        copyText: parts.first.command,
      ),
    );
  } else {
    final buf = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) buf.writeln();
      buf.writeln('# ${parts[i].label}');
      buf.writeln(parts[i].command);
    }
    steps.add(
      DeletionGuideStep(
        title: 'Commands',
        body: 'Run each block (or pick the ones you need):',
        copyText: buf.toString().trimRight(),
      ),
    );
  }

  notes.add(
    'Never use rm -rf on simulator runtimes or NDK bundles — use these commands.',
  );

  return DeletionGuide(
    summary:
        'Remove ${item.name} using the official CLI (${formatBytes(item.sizeBytes)}).',
    beforeYouStart: before,
    steps: steps,
    notes: notes,
  );
}

DeletionGuide _trashGuide(
  ScanItem item,
  List<String> before,
  List<String> notes, {
  required bool emptyOnly,
}) {
  final paths = item.paths.isNotEmpty
      ? item.paths
      : item.cleanAction?.paths ?? const [];
  final pathBlock = paths.isEmpty ? null : paths.join('\n');

  final inApp = emptyOnly
      ? 'Select this item and choose Clean. The app empties these folders '
            '(or moves contents to Trash when Trash is enabled).'
      : 'Select this item and choose Clean. Paths move to Trash by default '
            '(recoverable from Finder).';

  final manual = emptyOnly
      ? 'Delete contents inside each folder in Finder, or remove the folders '
            'if you are sure nothing else is stored there.'
      : 'In Finder, move each path to Trash. Do not run rm -rf on broad paths.';

  final steps = <DeletionGuideStep>[
    DeletionGuideStep(title: 'In Mac Dev Cleaner', body: inApp),
    DeletionGuideStep(title: 'Manually', body: manual, copyText: pathBlock),
  ];

  return DeletionGuide(
    summary:
        'Remove ${item.name} (${formatBytes(item.sizeBytes)}) via Trash or Finder.',
    beforeYouStart: before,
    steps: steps,
    notes: notes,
  );
}

extension ScanItemDeletionGuide on ScanItem {
  DeletionGuide get deletionGuide => deletionGuideFor(this);
}
