import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mac_dev_cleaner/treemap/squarify.dart';
import 'package:mac_dev_cleaner/treemap/treemap_node.dart';

void main() {
  test('empty inputs yield no rects', () {
    expect(squarify(const Rect.fromLTWH(0, 0, 100, 100), []), isEmpty);
  });

  test('single input fills area', () {
    const area = Rect.fromLTWH(0, 0, 200, 100);
    final rects = squarify(area, [
      const TreemapInput(id: 'a', label: 'A', value: 50),
    ]);
    expect(rects, hasLength(1));
    expect(rects.first.area, closeTo(area.width * area.height, 1));
  });

  test('multiple inputs cover area without large gaps', () {
    const area = Rect.fromLTWH(0, 0, 400, 300);
    final inputs = [
      const TreemapInput(id: 'a', label: 'A', value: 500),
      const TreemapInput(id: 'b', label: 'B', value: 300),
      const TreemapInput(id: 'c', label: 'C', value: 200),
      const TreemapInput(id: 'd', label: 'D', value: 100),
    ];
    final rects = squarify(area, inputs);
    expect(rects.length, greaterThanOrEqualTo(3));
    final totalArea = rects.fold<double>(0, (s, r) => s + r.area);
    expect(totalArea, closeTo(area.width * area.height, area.width * 2));

    for (final r in rects) {
      expect(r.rect.left, greaterThanOrEqualTo(area.left - 0.01));
      expect(r.rect.top, greaterThanOrEqualTo(area.top - 0.01));
      expect(r.rect.right, lessThanOrEqualTo(area.right + 0.01));
      expect(r.rect.bottom, lessThanOrEqualTo(area.bottom + 0.01));
    }
  });

  test('mergeSmallSlices buckets tiny values', () {
    final merged = mergeSmallSlices([
      const TreemapInput(id: 'big', label: 'Big', value: 1000),
      const TreemapInput(id: 'tiny', label: 'Tiny', value: 1),
    ]);
    expect(merged.any((e) => e.id == '__other__'), isTrue);
  });
}
