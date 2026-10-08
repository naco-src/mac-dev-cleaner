import 'package:flutter/material.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

import '../theme/mdc_theme.dart';
import 'risk_badge.dart';

class ScanItemTile extends StatefulWidget {
  const ScanItemTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onSelected,
  });

  final ScanItem item;
  final bool selected;
  final ValueChanged<bool?> onSelected;

  @override
  State<ScanItemTile> createState() => _ScanItemTileState();
}

class _ScanItemTileState extends State<ScanItemTile> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final canSelect = item.cleanable && item.preconditionMet;

    final semantic = MdcSemanticColors.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: Checkbox(
              value: canSelect && widget.selected,
              onChanged: canSelect ? widget.onSelected : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  formatBytes(item.sizeBytes),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 8),
                RiskBadge(risk: item.risk),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(item.explain),
                Text(
                  'Comes back: ${item.regenerates.label}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (item.preconditionHint != null)
                  Text(
                    item.preconditionHint!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: semantic.riskConditionalFg,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              tooltip: expanded ? 'Hide details' : 'Show paths and details',
              onPressed: () => setState(() => expanded = !expanded),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${item.id}', style: context.monoLabelSmall),
                  if (item.detail != null) Text(item.detail!),
                  if (item.cleanAction?.commandDescription != null)
                    Text(
                      'Command: ${item.cleanAction!.commandDescription}',
                      style: context.monoBodySmall,
                    ),
                  if (item.paths.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    for (final path in item.paths.take(8))
                      Text(path, style: context.monoBodySmall),
                    if (item.paths.length > 8)
                      Text('… +${item.paths.length - 8} more'),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
