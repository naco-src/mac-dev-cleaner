enum ScanLogLevel { info, warning, error }

class ScanLogEntry {
  ScanLogEntry({required this.level, required this.message, DateTime? time})
    : time = time ?? DateTime.now();

  final ScanLogLevel level;
  final String message;
  final DateTime time;

  factory ScanLogEntry.info(String message) =>
      ScanLogEntry(level: ScanLogLevel.info, message: message);

  factory ScanLogEntry.warning(String message) =>
      ScanLogEntry(level: ScanLogLevel.warning, message: message);

  factory ScanLogEntry.error(String message) =>
      ScanLogEntry(level: ScanLogLevel.error, message: message);
}

typedef ScanProgressCallback = void Function(ScanLogEntry entry);
