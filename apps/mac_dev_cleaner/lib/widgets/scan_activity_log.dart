import 'package:flutter/material.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

class ScanActivityLog extends StatefulWidget {
  const ScanActivityLog({
    super.key,
    required this.entries,
    this.compact = false,
    this.title = 'Scan activity',
  });

  final List<ScanLogEntry> entries;
  final bool compact;
  final String title;

  @override
  State<ScanActivityLog> createState() => _ScanActivityLogState();
}

class _ScanActivityLogState extends State<ScanActivityLog> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant ScanActivityLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries.length > oldWidget.entries.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) {
      return;
    }
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final list = ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      itemCount: widget.entries.length,
      itemBuilder: (context, index) {
        final entry = widget.entries[index];
        final color = switch (entry.level) {
          ScanLogLevel.info => theme.colorScheme.onSurface,
          ScanLogLevel.warning => Colors.orange.shade800,
          ScanLogLevel.error => theme.colorScheme.error,
        };
        final time = _formatTime(entry.time);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SelectableText(
            '[$time] ${entry.message}',
            style: TextStyle(
              fontFamily: 'Menlo',
              fontSize: 11,
              height: 1.35,
              color: color,
            ),
          ),
        );
      },
    );

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, widget.compact ? 4 : 8, 12, 4),
            child: Text(widget.title, style: theme.textTheme.titleSmall),
          ),
          Expanded(child: list),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
