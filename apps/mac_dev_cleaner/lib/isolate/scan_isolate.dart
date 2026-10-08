import 'package:flutter/foundation.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

Future<List<ScanItem>> _scanEntry(void _) async {
  final cleaner = MacDevCleaner();
  return cleaner.scan();
}

Future<List<ScanItem>> runScanOffMainThread() {
  return compute(_scanEntry, null);
}
