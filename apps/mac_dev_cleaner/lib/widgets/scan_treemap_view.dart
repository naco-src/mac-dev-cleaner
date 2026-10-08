import 'package:flutter/material.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';
import 'package:provider/provider.dart';

import '../controller/cleaner_controller.dart';
import '../treemap/group_colors.dart';
import '../treemap/treemap_layout.dart';
import 'treemap_tile.dart';

class ScanTreemapView extends StatelessWidget {
  const ScanTreemapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CleanerController>(
      builder: (context, controller, _) {
        final drill = controller.treemapDrillGroup;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TreemapBreadcrumb(controller: controller, drill: drill),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  if (drill == null) {
                    return _GroupTreemap(size: size, controller: controller);
                  }
                  return _ItemTreemap(
                    size: size,
                    controller: controller,
                    group: drill,
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

class _TreemapBreadcrumb extends StatelessWidget {
  const _TreemapBreadcrumb({required this.controller, required this.drill});

  final CleanerController controller;
  final RuleGroup? drill;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (drill != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'All groups',
              onPressed: controller.treemapBack,
            ),
          TextButton(
            onPressed: drill == null ? null : controller.treemapBack,
            child: const Text('All groups'),
          ),
          if (drill != null) ...[
            const Icon(Icons.chevron_right, size: 18),
            Text(drill!.label, style: Theme.of(context).textTheme.titleSmall),
          ],
        ],
      ),
    );
  }
}

class _GroupTreemap extends StatelessWidget {
  const _GroupTreemap({required this.size, required this.controller});

  final Size size;
  final CleanerController controller;

  @override
  Widget build(BuildContext context) {
    final totals = controller.groupTotals(controller.visibleItems);
    if (totals.isEmpty) {
      return const Center(child: Text('No sized items to show.'));
    }
    final rects = layoutGroupTreemap(size, totals);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final r in rects)
          if (r.input.payload != null)
            TreemapTile(
              rect: r.rect,
              label: r.input.label,
              sizeBytes: r.input.value.round(),
              fillColor: groupColor(r.input.payload!),
              onTap: () => controller.drillIntoGroup(r.input.payload!),
              selected: false,
              tooltipLines: [
                r.input.label,
                formatBytes(r.input.value.round()),
                'Click to drill down',
              ],
            ),
      ],
    );
  }
}

class _ItemTreemap extends StatelessWidget {
  const _ItemTreemap({
    required this.size,
    required this.controller,
    required this.group,
  });

  final Size size;
  final CleanerController controller;
  final RuleGroup group;

  @override
  Widget build(BuildContext context) {
    final items = controller.visibleItems
        .where((i) => i.group == group && i.sizeBytes > 0)
        .toList();
    if (items.isEmpty) {
      return const Center(child: Text('No items in this group.'));
    }
    final rects = layoutItemTreemap(size, items);
    final base = groupColor(group);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final r in rects)
          if (r.input.payload != null)
            Builder(
              builder: (context) {
                final item = r.input.payload!;
                final canSelect = item.cleanable && item.preconditionMet;
                return TreemapTile(
                  rect: r.rect,
                  label: item.name,
                  sizeBytes: item.sizeBytes,
                  fillColor: Color.lerp(
                    base,
                    Colors.black,
                    _riskShade(item.risk),
                  )!,
                  risk: item.risk,
                  selected: controller.selectedIds.contains(item.id),
                  onTap: () {
                    if (canSelect) {
                      controller.toggleSelection(
                        item.id,
                        !controller.selectedIds.contains(item.id),
                      );
                    }
                  },
                  tooltipLines: [
                    item.name,
                    formatBytes(item.sizeBytes),
                    item.risk.label,
                    item.explain,
                    if (item.preconditionHint != null) item.preconditionHint!,
                    if (canSelect) 'Click to toggle selection',
                  ],
                );
              },
            ),
      ],
    );
  }

  double _riskShade(RiskLevel risk) {
    return switch (risk) {
      RiskLevel.safe => 0.0,
      RiskLevel.conditional => 0.15,
      RiskLevel.protected => 0.3,
    };
  }
}
