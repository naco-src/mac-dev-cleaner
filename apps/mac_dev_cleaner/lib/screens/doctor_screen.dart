import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';
import 'package:provider/provider.dart';

import '../controller/cleaner_controller.dart';
import '../widgets/scan_activity_log.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CleanerController>().loadDoctor();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CleanerController>(
      builder: (context, controller, _) {
        final theme = Theme.of(context);
        final issues = controller.doctorIssues;
        final hasRun = controller.doctorLogs.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
              child: Row(
                children: [
                  const Text(
                    'Doctor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  if (controller.doctorLoading) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                  const Spacer(),
                  if (hasRun)
                    TextButton.icon(
                      icon: const Icon(Icons.copy_all, size: 18),
                      label: const Text('Copy log'),
                      onPressed: () {
                        final text = _formatDoctorLog(controller.doctorLogs);
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                    ),
                  OutlinedButton(
                    onPressed: controller.doctorLoading
                        ? null
                        : () => controller.loadDoctor(),
                    child: const Text('Run again'),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: issues.isEmpty ? 1 : 2,
              child: hasRun
                  ? ScanActivityLog(
                      entries: controller.doctorLogs,
                      compact: true,
                      title: 'Doctor activity',
                    )
                  : Center(
                      child: Text(
                        controller.doctorLoading
                            ? 'Running checks…'
                            : 'Tap Run again to start.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
            ),
            if (issues.isNotEmpty) ...[
              Divider(height: 1, color: theme.dividerColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text(
                  'Findings (${issues.length})',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Expanded(
                flex: 3,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: issues.length,
                  itemBuilder: (context, index) {
                    final issue = issues[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(issue.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(issue.detail),
                            if (issue.fixCommand != null) ...[
                              const SizedBox(height: 8),
                              SelectableText(
                                issue.fixCommand!,
                                style: const TextStyle(
                                  fontFamily: 'Menlo',
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: issue.fixCommand == null
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: 'Copy fix command',
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: issue.fixCommand!),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Copied to clipboard'),
                                    ),
                                  );
                                },
                              ),
                      ),
                    );
                  },
                ),
              ),
            ] else if (hasRun && !controller.doctorLoading)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No problems detected in automated checks (FDA note may still apply).',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }
}

String _formatDoctorLog(List<ScanLogEntry> entries) {
  final buf = StringBuffer()..writeln('=== Doctor activity ===');
  for (final entry in entries) {
    final h = entry.time.hour.toString().padLeft(2, '0');
    final m = entry.time.minute.toString().padLeft(2, '0');
    final s = entry.time.second.toString().padLeft(2, '0');
    buf.writeln('[$h:$m:$s] ${entry.message}');
  }
  return buf.toString().trimRight();
}
