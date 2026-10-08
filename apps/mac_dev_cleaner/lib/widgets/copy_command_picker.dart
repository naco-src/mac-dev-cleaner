import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

import '../theme/mdc_theme.dart';

String joinCopyCommands(Iterable<CopyCommandPart> parts) {
  return parts.map((p) => p.command).join('\n');
}

Future<void> showCopyCommandPicker(
  BuildContext context, {
  required String itemName,
  required List<CopyCommandPart> parts,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _CopyCommandPickerDialog(itemName: itemName, parts: parts),
  );
}

class _CopyCommandPickerDialog extends StatefulWidget {
  const _CopyCommandPickerDialog({required this.itemName, required this.parts});

  final String itemName;
  final List<CopyCommandPart> parts;

  @override
  State<_CopyCommandPickerDialog> createState() =>
      _CopyCommandPickerDialogState();
}

class _CopyCommandPickerDialogState extends State<_CopyCommandPickerDialog> {
  late final Set<int> _selected = {
    for (var i = 0; i < widget.parts.length; i++) i,
  };

  Iterable<CopyCommandPart> get _selectedParts sync* {
    for (var i = 0; i < widget.parts.length; i++) {
      if (_selected.contains(i)) yield widget.parts[i];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = joinCopyCommands(_selectedParts);

    return AlertDialog(
      title: const Text('Copy command'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.itemName, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _selected
                      ..clear()
                      ..addAll(List.generate(widget.parts.length, (i) => i));
                  }),
                  child: const Text('Select all'),
                ),
                TextButton(
                  onPressed: () => setState(_selected.clear),
                  child: const Text('Clear'),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.parts.length,
                itemBuilder: (context, index) {
                  final part = widget.parts[index];
                  return CheckboxListTile(
                    value: _selected.contains(index),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(index);
                        } else {
                          _selected.remove(index);
                        }
                      });
                    },
                    title: Text(part.label),
                    subtitle: Text(
                      part.command,
                      style: context.monoBodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text('Preview', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                preview.isEmpty ? '(nothing selected)' : preview,
                style: context.monoBodySmall,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _selected.isEmpty
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: preview));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Copied ${_selected.length} '
                        '${_selected.length == 1 ? 'line' : 'lines'} to clipboard',
                      ),
                    ),
                  );
                },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy'),
        ),
      ],
    );
  }
}
