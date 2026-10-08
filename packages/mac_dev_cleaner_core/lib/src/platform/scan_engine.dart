import '../models/scan_item.dart';
import '../scanner/scan_log.dart';

/// Host-specific scan rules (Xcode on macOS, etc.).
abstract class ScanEngine {
  Future<List<ScanItem>> scanAll({ScanProgressCallback? onProgress});
}
