import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

import 'copy_command_picker.dart';

/// Copies command line(s) for a scan item; opens a picker when there are several.
class CopyCommandButton extends StatelessWidget {
  const CopyCommandButton({
    super.key,
    required this.itemName,
    required this.parts,
    this.iconSize = 20,
    this.dense = false,
  });

  final String itemName;
  final List<CopyCommandPart> parts;
  final double iconSize;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) return const SizedBox.shrink();

    if (dense) {
      return IconButton(
        icon: Icon(Icons.copy, size: iconSize),
        tooltip: parts.length > 1 ? 'Copy command…' : 'Copy command',
        onPressed: () => _onPressed(context),
      );
    }
    return TextButton.icon(
      icon: Icon(Icons.copy, size: iconSize),
      label: Text(parts.length > 1 ? 'Copy command…' : 'Copy command'),
      onPressed: () => _onPressed(context),
    );
  }

  void _onPressed(BuildContext context) {
    if (parts.length == 1) {
      _copy(context, parts.first.command);
      return;
    }
    showCopyCommandPicker(context, itemName: itemName, parts: parts);
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied command to clipboard')),
    );
  }
}
