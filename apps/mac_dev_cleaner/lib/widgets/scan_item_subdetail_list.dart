import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

import '../theme/mdc_theme.dart';
import 'copy_command_button.dart';
import 'deletion_guide_dialog.dart';

/// Expanded body: metadata plus one row per sub-target.
class ScanItemExpandedDetails extends StatelessWidget {
  const ScanItemExpandedDetails({super.key, required this.item});

  final ScanItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subdetails = item.subdetails;
    final copyParts = item.copyCommandParts;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DeletionGuideIconButton(item: item),
                if (copyParts.isNotEmpty)
                  CopyCommandButton(
                    itemName: item.name,
                    parts: copyParts,
                    iconSize: 16,
                  ),
              ],
            ),
          ),
          Text('ID: ${item.id}', style: context.monoLabelSmall),
          if (item.detail != null) ...[
            const SizedBox(height: 4),
            Text(item.detail!, style: theme.textTheme.bodySmall),
          ],
          if (subdetails.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subdetails.length == 1
                  ? 'Target'
                  : 'Targets (${subdetails.length})',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: subdetails.length > 6 ? 220 : double.infinity,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: subdetails.length > 6
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: subdetails.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final sub = subdetails[index];
                  return _SubdetailRow(subdetail: sub);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubdetailRow extends StatelessWidget {
  const _SubdetailRow({required this.subdetail});

  final ScanItemSubdetail subdetail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subdetail.label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (subdetail.sizeBytes != null)
                      Text(
                        formatBytes(subdetail.sizeBytes!),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                SelectableText(subdetail.value, style: context.monoBodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: subdetail.value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
          ),
        ],
      ),
    );
  }
}
