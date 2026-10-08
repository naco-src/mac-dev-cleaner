import 'dart:ui';

class TreemapInput<T> {
  const TreemapInput({
    required this.id,
    required this.label,
    required this.value,
    this.payload,
  });

  final String id;
  final String label;
  final double value;
  final T? payload;
}

class TreemapRect<T> {
  const TreemapRect({required this.input, required this.rect});

  final TreemapInput<T> input;
  final Rect rect;

  double get area => rect.width * rect.height;
}
