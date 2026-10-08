import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

import '../controller/cleaner_controller.dart';
import 'scan_activity_log.dart';
import 'scan_item_subdetail_list.dart';

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
        final subCount = item.subdetails.length;
        final canExpand = subCount > 0 || item.detail != null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            margin: EdgeInsets.zero,
            child: ExpansionTile(
              initiallyExpanded: false,
              title: Text(item.name, style: theme.textTheme.titleSmall),
              subtitle: Text(
                '${formatBytes(item.sizeBytes)} · ${item.risk.label}'
                '${subCount > 1 ? ' · $subCount targets' : ''}'
                '${subCount == 1 && item.risk == RiskLevel.protected ? ' · 1 folder' : ''}',
                style: theme.textTheme.bodySmall,
              ),
              children: [if (canExpand) ScanItemExpandedDetails(item: item)],
            ),
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
  final subs = item.subdetails;
  if (subs.isNotEmpty) {
    final limited = maxPaths == null ? subs : subs.take(maxPaths);
    for (final sub in limited) {
      final size = sub.sizeBytes != null
          ? ' ${formatBytes(sub.sizeBytes!)}'
          : '';
      buf.writeln('  → ${sub.label}: ${sub.value}$size');
    }
    if (maxPaths != null && subs.length > maxPaths) {
      buf.writeln('  → … +${subs.length - maxPaths} more');
    }
  } else if (item.cleanAction?.commandDescription != null) {
    buf.writeln('  cmd: ${item.cleanAction!.commandDescription}');
  }
  return buf.toString().trimRight();
}
