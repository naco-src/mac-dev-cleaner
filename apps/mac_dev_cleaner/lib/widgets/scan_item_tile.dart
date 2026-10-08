import 'package:flutter/material.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

import '../theme/mdc_theme.dart';
import 'copy_command_button.dart';
import 'deletion_guide_dialog.dart';
import 'risk_badge.dart';
import 'scan_item_subdetail_list.dart';

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
    final copyParts = item.copyCommandParts;
    final subCount = item.subdetails.length;
    final canExpand = subCount > 0 || item.detail != null;

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
                if (subCount > 0 && item.risk == RiskLevel.protected)
                  Text(
                    subCount == 1
                        ? 'Expand for folder breakdown'
                        : '$subCount folders — expand for sizes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else if (subCount > 1)
                  Text(
                    '$subCount targets — expand for details',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DeletionGuideIconButton(item: item),
                if (copyParts.isNotEmpty)
                  CopyCommandButton(
                    itemName: item.name,
                    parts: copyParts,
                    dense: true,
                  ),
                if (canExpand)
                  IconButton(
                    icon: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    tooltip: expanded ? 'Hide subitems' : 'Show subitems',
                    onPressed: () => setState(() => expanded = !expanded),
                  ),
              ],
            ),
          ),
          if (expanded && canExpand) ScanItemExpandedDetails(item: item),
        ],
      ),
    );
  }
}
