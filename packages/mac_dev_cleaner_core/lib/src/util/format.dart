String formatBytes(int bytes) {
  if (bytes < 0) {
    return '0 B';
  }
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  if (unit == 0) {
    return '${bytes} B';
  }
  return '${value.toStringAsFixed(value >= 10 ? 1 : 2)} ${units[unit]}';
}
