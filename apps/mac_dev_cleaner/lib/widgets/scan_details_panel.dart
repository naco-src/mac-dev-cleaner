import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

import '../controller/cleaner_controller.dart';
import 'copy_command_button.dart';
import 'scan_activity_log.dart';

String buildScanDetailsCopyText(CleanerController controller) {
  final buf = StringBuffer();
  if (controller.scanError != null) {
    buf.writeln('Error: ${controller.scanError}');
    buf.writeln();
  }
  if (controller.scanLogs.isNotEmpty) {
    buf.writeln('=== Scan activity ===');
    for (final entry in controller.scanLogs) {
      buf.writeln('[${formatScanLogTime(entry.time)}] ${entry.message}');
    }
    buf.writeln();
  }
  if (controller.items.isNotEmpty) {
    buf.writeln('=== Discovered items (${controller.items.length}) ===');
    for (final item in controller.items) {
      buf.writeln(formatScanItemDetail(item));
      buf.writeln();
    }
  }
  return buf.toString().trimRight();
}

String formatScanLogTime(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  final s = time.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

/// Activity log plus per-item breakdown (paths, commands, errors).
class ScanDetailsPanel extends StatelessWidget {
  const ScanDetailsPanel({super.key, required this.controller});

  final CleanerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = controller.scanPhase;

    if (phase == ScanPhase.idle && controller.scanLogs.isEmpty) {
      return Center(
        child: Text(
          'Run Scan to see activity and item details here.',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    final canCopy =
        controller.scanLogs.isNotEmpty ||
        controller.items.isNotEmpty ||
        controller.scanError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canCopy)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.copy_all, size: 18),
                label: const Text('Copy all'),
                onPressed: () {
                  final text = buildScanDetailsCopyText(controller);
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
            ),
          ),
        if (phase == ScanPhase.scanning)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Scan in progress…',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ),
        if (phase == ScanPhase.error)
          Material(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                controller.scanError ?? 'Unknown error',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ),
        Expanded(
          flex: controller.items.isEmpty ? 1 : 2,
          child: ScanActivityLog(entries: controller.scanLogs),
        ),
        if (controller.items.isNotEmpty) ...[
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              'Discovered items (${controller.items.length})',
              style: theme.textTheme.titleSmall,
            ),
          ),
          Expanded(flex: 3, child: _ItemDetailsList(items: controller.items)),
        ],
      ],
    );
  }
}

class _ItemDetailsList extends StatelessWidget {
  const _ItemDetailsList({required this.items});

  final List<ScanItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final copyParts = item.copyCommandParts;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (copyParts.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: CopyCommandButton(
                    itemName: item.name,
                    parts: copyParts,
                    iconSize: 16,
                  ),
                ),
              SelectableText(
                formatScanItemDetail(item, maxPaths: 8),
                style: TextStyle(
                  fontFamily: 'Menlo',
                  fontSize: 11,
                  height: 1.4,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String formatScanItemDetail(ScanItem item, {int? maxPaths}) {
  final buf = StringBuffer()
    ..writeln('${item.id}  ${formatBytes(item.sizeBytes)}  ${item.risk.label}')
    ..writeln('  ${item.name}')
    ..writeln('  ${item.explain}')
    ..writeln(
      '  group: ${item.group.label}  regenerates: ${item.regenerates.label}',
    );
  if (item.preconditionHint != null) {
    buf.writeln('  ⚠ ${item.preconditionHint}');
  }
  if (item.detail != null) {
    buf.writeln('  detail: ${item.detail}');
  }
  if (item.cleanAction?.commandDescription != null) {
    buf.writeln('  cmd: ${item.cleanAction!.commandDescription}');
  }
  final paths = maxPaths == null ? item.paths : item.paths.take(maxPaths);
  for (final path in paths) {
    buf.writeln('  → $path');
  }
  if (maxPaths != null && item.paths.length > maxPaths) {
    buf.writeln('  → … +${item.paths.length - maxPaths} paths');
  }
  return buf.toString().trimRight();
}
