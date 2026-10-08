import 'package:flutter/material.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';
import 'package:provider/provider.dart';

import '../controller/cleaner_controller.dart';
import '../widgets/plan_summary_dialog.dart';
import '../widgets/scan_item_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _permanentDelete = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CleanerController>(
      builder: (context, controller, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DiskHeader(controller: controller),
            _Toolbar(
              controller: controller,
              searchController: _searchController,
            ),
            Expanded(child: _ItemList(controller: controller)),
            _Footer(
              controller: controller,
              permanentDelete: _permanentDelete,
              onPermanentDeleteChanged: (v) =>
                  setState(() => _permanentDelete = v),
            ),
          ],
        );
      },
    );
  }
}

class _DiskHeader extends StatelessWidget {
  const _DiskHeader({required this.controller});

  final CleanerController controller;

  @override
  Widget build(BuildContext context) {
    final disk = controller.diskSpace;
    return Material(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.storage),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                disk == null
                    ? 'Data volume — scan to refresh'
                    : 'Free ${formatBytes(disk.freeBytes)} of ${formatBytes(disk.totalBytes)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (controller.scanPhase == ScanPhase.scanning)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.controller, required this.searchController});

  final CleanerController controller;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.icon(
            onPressed: controller.scanPhase == ScanPhase.scanning
                ? null
                : () => controller.runScan(),
            icon: const Icon(Icons.search),
            label: const Text('Scan'),
          ),
          FilterChip(
            label: const Text('Safe only'),
            selected: controller.safeOnlyFilter,
            onSelected: controller.setSafeOnlyFilter,
          ),
          ...RuleGroup.values.map(
            (g) => FilterChip(
              label: Text(g.label),
              selected: controller.groupFilter == g,
              onSelected: (on) => controller.setGroupFilter(on ? g : null),
            ),
          ),
          SizedBox(
            width: 220,
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.filter_list, size: 20),
                hintText: 'Search…',
                border: OutlineInputBorder(),
              ),
              onChanged: controller.setSearchQuery,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({required this.controller});

  final CleanerController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.scanPhase == ScanPhase.idle) {
      return const Center(
        child: Text('Tap Scan to find reclaimable developer caches.'),
      );
    }
    if (controller.scanPhase == ScanPhase.error) {
      return Center(child: Text('Scan failed: ${controller.scanError}'));
    }
    if (controller.scanPhase == ScanPhase.scanning &&
        controller.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning — this can take several minutes…'),
          ],
        ),
      );
    }

    final visible = controller.visibleItems;
    if (visible.isEmpty) {
      return const Center(child: Text('No items match filters.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              TextButton(
                onPressed: () => controller.selectAllVisible(true),
                child: const Text('Select visible'),
              ),
              TextButton(
                onPressed: () => controller.selectAllVisible(false),
                child: const Text('Clear visible'),
              ),
              const Spacer(),
              Text('${controller.selectedIds.length} selected'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final item = visible[index];
              return ScanItemTile(
                item: item,
                selected: controller.selectedIds.contains(item.id),
                onSelected: (v) => controller.toggleSelection(item.id, v),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.controller,
    required this.permanentDelete,
    required this.onPermanentDeleteChanged,
  });

  final CleanerController controller;
  final bool permanentDelete;
  final ValueChanged<bool> onPermanentDeleteChanged;

  @override
  Widget build(BuildContext context) {
    final plan = controller.currentPlan;
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: plan.items.isEmpty
                  ? null
                  : () => showPlanPreviewDialog(context, plan),
              child: const Text('Preview plan'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: plan.items.isEmpty || controller.cleanInProgress
                  ? null
                  : () => _confirmAndClean(context),
              child: controller.cleanInProgress
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Clean selected (${formatBytes(plan.totalBytes)})'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndClean(BuildContext context) async {
    var delete = permanentDelete;
    final ok = await showPlanSummaryDialog(
      context,
      plan: controller.currentPlan,
      permanentDelete: delete,
      onPermanentDeleteChanged: (v) {
        delete = v;
        onPermanentDeleteChanged(v);
      },
    );
    if (ok != true || !context.mounted) {
      return;
    }
    final result = await controller.runClean(permanentDelete: delete);
    if (context.mounted) {
      await showCleanResultDialog(context, result);
    }
  }
}
