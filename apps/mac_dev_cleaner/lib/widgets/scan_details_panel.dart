import 'package:flutter/material.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

import '../controller/cleaner_controller.dart';
import 'scan_activity_log.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SelectableText(
            _formatItem(item),
            style: TextStyle(
              fontFamily: 'Menlo',
              fontSize: 11,
              height: 1.4,
              color: theme.colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }

  String _formatItem(ScanItem item) {
    final buf = StringBuffer()
      ..writeln(
        '${item.id}  ${formatBytes(item.sizeBytes)}  ${item.risk.label}',
      )
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
    for (final path in item.paths.take(8)) {
      buf.writeln('  → $path');
    }
    if (item.paths.length > 8) {
      buf.writeln('  → … +${item.paths.length - 8} paths');
    }
    return buf.toString().trimRight();
  }
}
