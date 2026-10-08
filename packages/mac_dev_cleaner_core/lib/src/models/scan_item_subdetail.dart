/// One row under an expanded [ScanItem] (path, command, or target).
class ScanItemSubdetail {
  const ScanItemSubdetail({
    required this.label,
    required this.value,
    this.sizeBytes,
  });

  final String label;
  final String value;
  final int? sizeBytes;
}
