import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

import '../theme/mdc_theme.dart';

Future<void> showDeletionGuideDialog(
  BuildContext context, {
  required ScanItem item,
}) {
  final guide = item.deletionGuide;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('How to delete'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: _DeletionGuideBody(itemName: item.name, guide: guide),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: guide.clipboardText));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied guide to clipboard')),
            );
          },
          child: const Text('Copy guide'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

class DeletionGuideIconButton extends StatelessWidget {
  const DeletionGuideIconButton({super.key, required this.item});

  final ScanItem item;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_book_outlined, size: 20),
      tooltip: 'How to delete',
      onPressed: () => showDeletionGuideDialog(context, item: item),
    );
  }
}

class _DeletionGuideBody extends StatelessWidget {
  const _DeletionGuideBody({required this.itemName, required this.guide});

  final String itemName;
  final DeletionGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(itemName, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(guide.summary),
        if (guide.beforeYouStart.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Before you start', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          for (final line in guide.beforeYouStart)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(line)),
                ],
              ),
            ),
        ],
        for (var i = 0; i < guide.steps.length; i++) ...[
          const SizedBox(height: 16),
          Text(
            '${i + 1}. ${guide.steps[i].title}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(guide.steps[i].body),
          if (guide.steps[i].copyText != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                guide.steps[i].copyText!,
                style: context.monoBodySmall,
              ),
            ),
          ],
        ],
        if (guide.notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Notes', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          for (final note in guide.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(note, style: theme.textTheme.bodySmall),
            ),
        ],
      ],
    );
  }
}
