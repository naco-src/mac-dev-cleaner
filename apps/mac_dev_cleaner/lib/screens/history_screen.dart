import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';
import 'package:provider/provider.dart';

import '../controller/cleaner_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CleanerController>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CleanerController>(
      builder: (context, controller, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text(
                    'History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => controller.loadHistory(),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.historyFilePath,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: controller.historyFilePath),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Path copied')),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (controller.historyLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (controller.historyEntries.isEmpty)
              const Expanded(
                child: Center(child: Text('No cleanups logged yet.')),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.historyEntries.length,
                  itemBuilder: (context, index) {
                    final entry = controller.historyEntries[index];
                    final bytes =
                        (entry['bytesReclaimedEstimate'] as num?)?.toInt() ?? 0;
                    return ListTile(
                      title: Text(entry['time']?.toString() ?? ''),
                      subtitle: Text('Reclaimed ~${formatBytes(bytes)}'),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
