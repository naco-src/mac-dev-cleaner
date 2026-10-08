import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controller/cleaner_controller.dart';

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
        if (controller.doctorLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.doctorIssues.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No issues reported.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => controller.loadDoctor(),
                  child: const Text('Run again'),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text(
                    'Doctor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => controller.loadDoctor(),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: controller.doctorIssues.length,
                itemBuilder: (context, index) {
                  final issue = controller.doctorIssues[index];
                  return Card(
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
                                fontFamily: 'monospace',
                                fontSize: 12,
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
          ],
        );
      },
    );
  }
}
