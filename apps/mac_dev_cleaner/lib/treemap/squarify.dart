import 'dart:math' as math;
import 'dart:ui';

import 'treemap_node.dart';

List<TreemapInput<T>> mergeSmallSlices<T>(
  List<TreemapInput<T>> inputs, {
  double minFraction = 0.005,
}) {
  final positive = inputs.where((i) => i.value > 0).toList();
  if (positive.length <= 1) {
    return positive;
  }
  final total = positive.fold<double>(0, (s, i) => s + i.value);
  final threshold = total * minFraction;
  final main = <TreemapInput<T>>[];
  var otherValue = 0.0;
  for (final item in positive) {
    if (item.value < threshold) {
      otherValue += item.value;
    } else {
      main.add(item);
    }
  }
  if (otherValue > 0) {
    main.add(
      TreemapInput<T>(id: '__other__', label: 'Other', value: otherValue),
    );
  }
  return main.isEmpty ? positive : main;
}

List<TreemapRect<T>> squarify<T>(
  Rect area,
  List<TreemapInput<T>> inputs, {
  double minFraction = 0.005,
}) {
  if (area.width <= 0 || area.height <= 0) {
    return [];
  }
  final merged = mergeSmallSlices(inputs, minFraction: minFraction);
  if (merged.isEmpty) {
    return [];
  }
  final total = merged.fold<double>(0, (s, i) => s + i.value);
  if (total <= 0) {
    return [];
  }

  final sorted = List<TreemapInput<T>>.from(merged)
    ..sort((a, b) => b.value.compareTo(a.value));

  final rects = <TreemapRect<T>>[];
  _squarify(sorted, area, total, rects);
  return rects;
}

void _squarify<T>(
  List<TreemapInput<T>> children,
  Rect row,
  double totalValue,
  List<TreemapRect<T>> out,
) {
  if (children.isEmpty) {
    return;
  }
  if (children.length == 1) {
    out.add(TreemapRect(input: children.first, rect: row));
    return;
  }

  final rowLength = math.min(row.width, row.height);
  final rowArea = row.width * row.height;

  var slice = <TreemapInput<T>>[children.first];
  var i = 1;
  while (i < children.length) {
    final candidate = children[i];
    final withCandidate = [...slice, candidate];
    if (_worst(withCandidate, rowLength) <= _worst(slice, rowLength)) {
      slice = withCandidate;
      i++;
    } else {
      break;
    }
  }

  final sliceValue = slice.fold<double>(0, (s, c) => s + c.value);
  final remaining = children.sublist(slice.length);
  final remainingValue = totalValue - sliceValue;

  final horizontal = row.width >= row.height;
  final thickness = horizontal
      ? rowArea * (sliceValue / totalValue) / row.width
      : rowArea * (sliceValue / totalValue) / row.height;

  var offset = 0.0;
  for (final item in slice) {
    final fraction = item.value / sliceValue;
    final Rect tile;
    if (horizontal) {
      final w = row.width * fraction;
      tile = Rect.fromLTWH(row.left + offset, row.top, w, thickness);
      offset += w;
    } else {
      final h = row.height * fraction;
      tile = Rect.fromLTWH(row.left, row.top + offset, thickness, h);
      offset += h;
    }
    out.add(TreemapRect(input: item, rect: tile));
  }

  final rest = horizontal
      ? Rect.fromLTWH(
          row.left,
          row.top + thickness,
          row.width,
          row.height - thickness,
        )
      : Rect.fromLTWH(
          row.left + thickness,
          row.top,
          row.width - thickness,
          row.height,
        );

  if (remaining.isNotEmpty && remainingValue > 0) {
    _squarify(remaining, rest, remainingValue, out);
  }
}

double _worst<T>(List<TreemapInput<T>> row, double side) {
  if (row.isEmpty) {
    return double.infinity;
  }
  final rowValue = row.fold<double>(0, (s, c) => s + c.value);
  if (rowValue <= 0 || side <= 0) {
    return double.infinity;
  }
  var minV = double.infinity;
  var maxV = 0.0;
  for (final c in row) {
    minV = math.min(minV, c.value);
    maxV = math.max(maxV, c.value);
  }
  final s2 = side * side;
  final r2 = rowValue * rowValue;
  return math.max(s2 * maxV / r2, r2 / (s2 * minV));
}
