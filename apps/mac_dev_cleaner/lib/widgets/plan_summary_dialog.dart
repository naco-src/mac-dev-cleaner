import 'package:flutter/material.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

Future<bool?> showPlanSummaryDialog(
  BuildContext context, {
  required CleanPlan plan,
  required bool permanentDelete,
  required ValueChanged<bool> onPermanentDeleteChanged,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Clean selected items?'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${plan.items.length} item(s), ${formatBytes(plan.totalBytes)} reclaimable.',
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Permanent delete (skip Trash)'),
                    subtitle: const Text('Default is move to Trash'),
                    value: permanentDelete,
                    onChanged: (v) {
                      setState(() => onPermanentDeleteChanged(v ?? false));
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: plan.items.isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                child: const Text('Clean'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showPlanPreviewDialog(BuildContext context, CleanPlan plan) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Plan preview'),
      content: SizedBox(
        width: 400,
        child: Text(
          '${plan.items.length} item(s)\n${formatBytes(plan.totalBytes)} reclaimable',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> showCleanResultDialog(BuildContext context, CleanResult result) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cleanup finished'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Succeeded: ${result.succeeded.length}'),
            Text('Failed: ${result.failed.length}'),
            Text(
              'Estimated reclaimed: ${formatBytes(result.bytesReclaimedEstimate)}',
            ),
            if (result.failed.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Errors:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final f in result.failed) Text('${f.itemId}: ${f.message}'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
