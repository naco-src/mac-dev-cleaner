import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copies [command] to the clipboard and shows a snackbar.
class CopyCommandButton extends StatelessWidget {
  const CopyCommandButton({
    super.key,
    required this.command,
    this.iconSize = 20,
    this.dense = false,
  });

  final String command;
  final double iconSize;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (dense) {
      return IconButton(
        icon: Icon(Icons.copy, size: iconSize),
        tooltip: 'Copy command',
        onPressed: () => _copy(context),
      );
    }
    return TextButton.icon(
      icon: Icon(Icons.copy, size: iconSize),
      label: const Text('Copy command'),
      onPressed: () => _copy(context),
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: command));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied command to clipboard')),
    );
  }
}
