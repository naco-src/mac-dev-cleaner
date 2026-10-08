import 'dart:ui';

import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

import 'squarify.dart';
import 'treemap_node.dart';

const _layoutPadding = 2.0;

List<TreemapRect<RuleGroup>> layoutGroupTreemap(
  Size size,
  Map<RuleGroup, int> totals,
) {
  final inputs = totals.entries
      .where((e) => e.value > 0)
      .map(
        (e) => TreemapInput<RuleGroup>(
          id: e.key.name,
          label: e.key.label,
          value: e.value.toDouble(),
          payload: e.key,
        ),
      )
      .toList();
  final area = Rect.fromLTWH(
    _layoutPadding,
    _layoutPadding,
    size.width - _layoutPadding * 2,
    size.height - _layoutPadding * 2,
  );
  return squarify(area, inputs);
}

List<TreemapRect<ScanItem>> layoutItemTreemap(Size size, List<ScanItem> items) {
  final inputs = items
      .where((i) => i.sizeBytes > 0)
      .map(
        (i) => TreemapInput<ScanItem>(
          id: i.id,
          label: i.name,
          value: i.sizeBytes.toDouble(),
          payload: i,
        ),
      )
      .toList();
  final area = Rect.fromLTWH(
    _layoutPadding,
    _layoutPadding,
    size.width - _layoutPadding * 2,
    size.height - _layoutPadding * 2,
  );
  return squarify(area, inputs);
}
